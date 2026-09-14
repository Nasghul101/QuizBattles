#!/usr/bin/env python3
"""Translate a local Quizbattles question database with LibreTranslate."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


# Change these values for another translation run.
INPUT_FILE = Path(__file__).resolve().parent.parent / "data" / "questions_en.json"
INPUT_LANGUAGE = "en"
OUTPUT_LANGUAGE = "de"
OUTPUT_FILE = Path(__file__).resolve().parent.parent / "data" / "questions_de.json"

# LibreTranslate installation and server settings.
LIBRETRANSLATE_EXECUTABLE = Path(
    r"C:\Ich hasse Windows\LibreTranslate\.venv\Scripts\libretranslate.exe"
)
LIBRETRANSLATE_HOST = "127.0.0.1"
LIBRETRANSLATE_PORT = 5000
START_LIBRETRANSLATE = True

# Request settings. Smaller batches are slower but use less memory.
BATCH_SIZE = 20
REQUEST_TIMEOUT_SECONDS = 120
SERVER_START_TIMEOUT_SECONDS = 300
MAX_RETRIES = 3
RETRY_DELAY_SECONDS = 2


class TranslationError(RuntimeError):
    """Raised when LibreTranslate cannot translate the requested text."""


def api_url(path: str) -> str:
    return f"http://{LIBRETRANSLATE_HOST}:{LIBRETRANSLATE_PORT}{path}"


def request_json(path: str, payload: dict[str, Any] | None = None) -> Any:
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        headers["Content-Type"] = "application/json"

    request = Request(api_url(path), data=data, headers=headers, method="POST" if data else "GET")
    with urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
        return json.loads(response.read().decode("utf-8"))


def wait_for_server(server: subprocess.Popen[bytes] | None = None) -> None:
    deadline = time.monotonic() + SERVER_START_TIMEOUT_SECONDS
    last_error: Exception | None = None

    while time.monotonic() < deadline:
        if server is not None and server.poll() is not None:
            raise TranslationError(
                f"LibreTranslate exited before becoming ready (exit code {server.returncode})."
            )
        try:
            request_json("/languages")
            return
        except (HTTPError, URLError, TimeoutError, OSError, json.JSONDecodeError) as error:
            last_error = error
            time.sleep(1)

    raise TranslationError(
        f"LibreTranslate did not become ready within {SERVER_START_TIMEOUT_SECONDS} seconds. "
        f"Last error: {last_error}"
    )


def start_server() -> subprocess.Popen[bytes]:
    if not LIBRETRANSLATE_EXECUTABLE.is_file():
        raise FileNotFoundError(
            f"LibreTranslate executable not found: {LIBRETRANSLATE_EXECUTABLE}"
        )

    command = [
        str(LIBRETRANSLATE_EXECUTABLE),
        "--host",
        LIBRETRANSLATE_HOST,
        "--port",
        str(LIBRETRANSLATE_PORT),
        "--load-only",
        f"{INPUT_LANGUAGE},{OUTPUT_LANGUAGE}",
    ]
    print(f"Starting LibreTranslate: {' '.join(command)}")
    return subprocess.Popen(command)


def load_questions() -> dict[str, list[dict[str, Any]]]:
    if not INPUT_FILE.is_file():
        raise FileNotFoundError(f"Input file not found: {INPUT_FILE}")

    with INPUT_FILE.open("r", encoding="utf-8") as file:
        data = json.load(file)

    if not isinstance(data, dict):
        raise ValueError("The input JSON root must be an object of category arrays.")

    for category, questions in data.items():
        if not isinstance(questions, list):
            raise ValueError(f"Category {category!r} must contain an array.")
        for index, question in enumerate(questions):
            if not isinstance(question, dict):
                raise ValueError(f"Question {category}[{index}] must be an object.")

    return data


def collect_texts(data: dict[str, list[dict[str, Any]]]) -> list[str]:
    texts: list[str] = []
    seen: set[str] = set()

    for questions in data.values():
        for question in questions:
            values = [question.get("question", ""), question.get("correct_answer", "")]
            values.extend(question.get("incorrect_answers", []))
            for value in values:
                if not isinstance(value, str) or not value.strip() or value in seen:
                    continue
                seen.add(value)
                texts.append(value)

    return texts


def translate_batch(texts: list[str]) -> list[str]:
    payload = {
        "q": texts,
        "source": INPUT_LANGUAGE,
        "target": OUTPUT_LANGUAGE,
        "format": "text",
    }

    response = request_json("/translate", payload)
    if isinstance(response, dict):
        result = response.get("translatedText")
        if isinstance(result, list) and len(result) == len(texts):
            if all(isinstance(item, str) for item in result):
                return result
        if len(texts) == 1 and isinstance(result, str):
            return [result]

    raise TranslationError("LibreTranslate returned an unexpected batch response.")


def translate_texts(texts: list[str]) -> dict[str, str]:
    translations: dict[str, str] = {}
    total_batches = (len(texts) + BATCH_SIZE - 1) // BATCH_SIZE

    for batch_index, start in enumerate(range(0, len(texts), BATCH_SIZE), start=1):
        batch = texts[start : start + BATCH_SIZE]
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                translated = translate_batch(batch)
                translations.update(zip(batch, translated))
                print(f"Translated batch {batch_index}/{total_batches} ({len(batch)} texts)")
                break
            except (HTTPError, URLError, TimeoutError, OSError, json.JSONDecodeError, TranslationError) as error:
                if attempt == MAX_RETRIES:
                    raise TranslationError(
                        f"Failed to translate batch {batch_index} after {MAX_RETRIES} attempts: {error}"
                    ) from error
                print(f"Batch {batch_index} failed ({error}); retrying ({attempt}/{MAX_RETRIES})...")
                time.sleep(RETRY_DELAY_SECONDS)

    return translations


def apply_translations(
    data: dict[str, list[dict[str, Any]]],
    translations: dict[str, str],
) -> dict[str, list[dict[str, Any]]]:
    output: dict[str, list[dict[str, Any]]] = {}

    for category, questions in data.items():
        output_questions: list[dict[str, Any]] = []
        for question in questions:
            translated_question = question.copy()
            for field in ("question", "correct_answer"):
                value = question.get(field)
                if isinstance(value, str) and value in translations:
                    translated_question[field] = translations[value]

            incorrect_answers = question.get("incorrect_answers", [])
            if isinstance(incorrect_answers, list):
                translated_question["incorrect_answers"] = [
                    translations.get(answer, answer) if isinstance(answer, str) else answer
                    for answer in incorrect_answers
                ]
            output_questions.append(translated_question)
        output[category] = output_questions

    return output


def write_output(data: dict[str, list[dict[str, Any]]]) -> None:
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    temporary_file = OUTPUT_FILE.with_suffix(OUTPUT_FILE.suffix + ".tmp")
    with temporary_file.open("w", encoding="utf-8", newline="\n") as file:
        json.dump(data, file, ensure_ascii=False, indent=2)
        file.write("\n")
    os.replace(temporary_file, OUTPUT_FILE)


def main() -> int:
    server: subprocess.Popen[bytes] | None = None
    try:
        data = load_questions()
        texts = collect_texts(data)
        print(f"Loaded {sum(len(items) for items in data.values())} questions.")
        print(f"Found {len(texts)} unique question and answer texts to translate.")

        if START_LIBRETRANSLATE:
            server = start_server()
        wait_for_server(server)

        translations = translate_texts(texts)
        write_output(apply_translations(data, translations))
        print(f"Wrote translated questions to: {OUTPUT_FILE}")
        return 0
    except (FileNotFoundError, ValueError, TranslationError, OSError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    finally:
        if server is not None and server.poll() is None:
            print("Stopping LibreTranslate...")
            server.terminate()
            try:
                server.wait(timeout=10)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait()


if __name__ == "__main__":
    raise SystemExit(main())
