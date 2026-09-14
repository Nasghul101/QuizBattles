#!/usr/bin/env python3
"""
Trivia Question Database Builder for Quizbattles.

Fetches questions across the 12 game categories defined in
autoload/trivia_question_service.gd and saves them in data/questions_en.json,
matching the format in data/fallback_questions.json.

Data Sources:
1. Primary Source: Open Trivia Database (OpenTDB API)
2. Secondary Source: QuizQuestions.org (Scrapes & parses 4-choice questions if OpenTDB lacks questions)

Key Features:
- Respects OpenTDB rate limits (5-second delay between requests).
- Uses OpenTDB Session Tokens to prevent duplicates across batches.
- Handles composite categories (Entertainment & Science) across all subcategories.
- Automatically falls back to QuizQuestions.org when an OpenTDB category is exhausted.
- Properly decodes HTML entities into clean UTF-8 text.
- Deduplicates questions by question text.
- Incremental save to data/questions_en.json.
"""

import html
import json
import os
import re
import string
import sys
import time
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from typing import Any, Dict, List, Optional, Set

# --- OpenTDB Configuration ---
OPENTDB_API_URL = "https://opentdb.com/api.php"
OPENTDB_TOKEN_URL = "https://opentdb.com/api_token.php?command=request"
OPENTDB_DELAY_SECONDS = 5.2
OPENTDB_MAX_PER_REQUEST = 50

# 12 Game categories mapped to OpenTDB Category IDs (matching trivia_question_service.gd)
OPENTDB_CATEGORY_MAPPING: Dict[str, Any] = {
    "General Knowledge": 9,
    "Entertainment": [11, 12, 13, 14, 29, 31],  # Film, Music, TV, Video Games, Comics, Anime
    "Science": [17, 18, 19, 30],  # Nature, Computers, Mathematics, Gadgets
    "History": 23,
    "Geography": 22,
    "Sports": 21,
    "Art": 25,
    "Animals": 27,
    "Mythology": 20,
    "Politics": 24,
    "Celebrities": 26,
    "Vehicles": 28,
}

# --- QuizQuestions.org Configuration ---
QQO_BASE_URL = "https://www.quizquestions.org/category/"

# Mapping from game categories to QuizQuestions.org category slugs
QQO_CATEGORY_MAPPING: Dict[str, List[str]] = {
    "General Knowledge": [
        "general-knowledge", "easy", "pub-quiz", "random", "kids"
    ],
    "Entertainment": [
        "entertainment", "movie", "music", "tv-show", "video-game",
        "anime", "disney", "friends-tv-show", "game-of-thrones",
        "harry-potter", "lord-of-the-rings", "marvel", "star-wars",
        "the-simpsons", "pop-culture", "super-mario", "pokemon", "minecraft"
    ],
    "Science": [
        "science", "biology", "chemistry", "physics", "anatomy",
        "space", "technology", "computer-science-and-coding", "math"
    ],
    "History": [
        "history", "world-war-2", "black-history"
    ],
    "Geography": [
        "geography", "australia", "brazil", "canada", "india-quiz-questions",
        "ireland", "italy", "japan", "philippines", "scotland-quiz-questions",
        "singapore", "south-africa-quiz-questions", "spain", "uk", "usa",
        "azerbaijan", "bosnia", "bulgaria", "gibraltar", "jamaica",
        "liberia", "montserrat", "new-zealand", "turks-caicos-islands", "virgin-islands"
    ],
    "Sports": [
        "sports"
    ],
    "Art": [
        "art", "literature"
    ],
    "Animals": [
        "animals-wildlife"
    ],
    "Mythology": [
        "mythology"
    ],
    "Politics": [
        "independence-day", "history", "usa", "uk"
    ],
    "Celebrities": [
        "celebrity", "pop-culture", "music", "movie", "entertainment"
    ],
    "Vehicles": [
        "cars"
    ],
}


class QuizQuestionsOrgParser(HTMLParser):
    """Parses 4-choice multiple choice questions and answers from QuizQuestions.org HTML pages."""
    def __init__(self):
        super().__init__()
        self.in_p_title = False
        self.in_ol = False
        self.in_li = False
        self.in_correct_answer = False

        self.current_q = ""
        self.current_options: List[str] = []
        self.current_correct: Optional[str] = None
        self.current_text = ""
        self.questions: List[Dict[str, Any]] = []

    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        cls = attrs_dict.get("class", "")

        if tag == "p" and "font-display" in cls:
            self.in_p_title = True
            self.current_text = ""
            self.current_q = ""
            self.current_options = []
            self.current_correct = None
        elif tag == "ol" and "list-[upper-alpha]" in cls:
            self.in_ol = True
        elif tag == "li" and self.in_ol:
            self.in_li = True
            self.current_text = ""

    def handle_endtag(self, tag):
        if tag == "p" and self.in_p_title:
            self.in_p_title = False
            q_clean = re.sub(r"^\d+\.\s*", "", self.current_text.strip())
            self.current_q = q_clean
        elif tag == "li" and self.in_li:
            self.in_li = False
            self.current_options.append(self.current_text.strip())
        elif tag == "ol" and self.in_ol:
            self.in_ol = False

    def handle_data(self, data):
        if self.in_p_title or self.in_li:
            self.current_text += data
        else:
            if "Correct answer:" in data:
                self.in_correct_answer = True
            elif self.in_correct_answer:
                ans = data.strip()
                if ans and not self.current_correct:
                    self.current_correct = ans
                    self.in_correct_answer = False
                    # Check if we have a valid 4-option question
                    if self.current_q and len(self.current_options) == 4:
                        if self.current_correct in self.current_options:
                            wrong = [o for o in self.current_options if o != self.current_correct]
                            if len(wrong) == 3:
                                self.questions.append({
                                    "type": "multiple",
                                    "difficulty": "medium",
                                    "question": html.unescape(self.current_q),
                                    "correct_answer": html.unescape(self.current_correct),
                                    "incorrect_answers": [html.unescape(w) for w in wrong],
                                })


def get_opentdb_token() -> Optional[str]:
    """Requests a session token from OpenTDB to prevent duplicate questions."""
    try:
        req = urllib.request.Request(
            OPENTDB_TOKEN_URL,
            headers={"User-Agent": "Quizbattles-Fetcher/1.0"}
        )
        with urllib.request.urlopen(req, timeout=15) as response:
            data = json.loads(response.read().decode("utf-8"))
            if data.get("response_code") == 0:
                return data.get("token")
    except Exception as e:
        print(f"[Warning] Could not get OpenTDB token: {e}")
    return None


def fetch_opentdb_batch(
    category_id: int,
    amount: int,
    token: Optional[str] = None
) -> tuple[int, List[Dict[str, Any]]]:
    """Fetches a batch of multiple-choice questions from OpenTDB."""
    params = {
        "amount": amount,
        "category": category_id,
        "type": "multiple"
    }
    if token:
        params["token"] = token

    url = f"{OPENTDB_API_URL}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"User-Agent": "Quizbattles-Fetcher/1.0"})

    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            code = data.get("response_code", -1)
            results = data.get("results", [])
            return code, results
    except Exception as e:
        print(f"    [Error OpenTDB fetch]: {e}")
        return -1, []


def fetch_qqo_category(slug: str) -> List[Dict[str, Any]]:
    """Fetches and parses questions from QuizQuestions.org for a given category slug."""
    url = f"{QQO_BASE_URL}{slug}"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Quizbattles-Fetcher/1.0"}
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            html_content = resp.read().decode("utf-8", errors="replace")
            parser = QuizQuestionsOrgParser()
            parser.feed(html_content)
            return parser.questions
    except Exception as e:
        print(f"    [Error QuizQuestions.org fetch '{slug}']: {e}")
        return []


def normalize_text(text: str) -> str:
    """Normalizes question text for robust duplicate comparison."""
    if not text:
        return ""
    text = text.lower()
    text = text.translate(str.maketrans("", "", string.punctuation + "“”‘’¿¡"))
    return re.sub(r"\s+", " ", text).strip()


def unescape_opentdb_data(raw_q: Dict[str, Any], top_category: str) -> Dict[str, Any]:
    """Normalizes OpenTDB question item into Quizbattles schema."""
    return {
        "category": top_category,
        "type": raw_q.get("type", "multiple"),
        "difficulty": raw_q.get("difficulty", "medium"),
        "question": html.unescape(raw_q.get("question", "")).strip(),
        "correct_answer": html.unescape(raw_q.get("correct_answer", "")).strip(),
        "incorrect_answers": [
            html.unescape(ans).strip() for ans in raw_q.get("incorrect_answers", [])
        ],
    }


def fetch_questions_for_category(
    category_name: str,
    target_count: int,
    opentdb_token: Optional[str],
    seen_questions: Set[str]
) -> List[Dict[str, Any]]:
    """Fetches questions for a category from OpenTDB, filling gaps via QuizQuestions.org."""
    category_questions: List[Dict[str, Any]] = []

    print(f"\n==================================================")
    print(f"Fetching '{category_name}' (Target: {target_count} questions)...")

    # --- Phase 1: Fetch from OpenTDB ---
    mapping = OPENTDB_CATEGORY_MAPPING.get(category_name)
    if mapping is not None:
        sub_ids: List[int] = mapping if isinstance(mapping, list) else [mapping]
        per_sub_target = max(1, target_count // len(sub_ids))

        for sub_id in sub_ids:
            sub_collected = 0
            sub_target = per_sub_target if len(sub_ids) > 1 else target_count
            consecutive_failures = 0
            current_batch_size = OPENTDB_MAX_PER_REQUEST

            while sub_collected < sub_target and len(category_questions) < target_count and current_batch_size >= 1:
                fetch_amount = min(current_batch_size, sub_target - sub_collected)
                print(f"  [OpenTDB] Requesting {fetch_amount} questions (Category ID {sub_id})...")

                code, results = fetch_opentdb_batch(sub_id, fetch_amount, opentdb_token)

                if code == 5:  # Rate limited
                    print("    [OpenTDB Rate Limit] Waiting 10s...")
                    time.sleep(10.0)
                    continue
                elif code == 4:  # Token exhausted for this category
                    print(f"    [OpenTDB] Category ID {sub_id} questions exhausted for session.")
                    break
                elif code == 1:  # Not enough questions to satisfy requested amount
                    # Step down batch size to capture remaining questions (e.g. 50 -> 25 -> 10 -> 5 -> 1)
                    if current_batch_size > 25:
                        current_batch_size = 25
                    elif current_batch_size > 10:
                        current_batch_size = 10
                    elif current_batch_size > 5:
                        current_batch_size = 5
                    elif current_batch_size > 1:
                        current_batch_size = 1
                    else:
                        print(f"    [OpenTDB] Category ID {sub_id} fully exhausted.")
                        break
                    print(f"    [OpenTDB] Requested amount exceeded available pool. Stepping down batch size to {current_batch_size}...")
                    time.sleep(OPENTDB_DELAY_SECONDS)
                    continue
                elif code != 0 or not results:
                    consecutive_failures += 1
                    if consecutive_failures >= 3:
                        break
                    time.sleep(OPENTDB_DELAY_SECONDS)
                    continue

                consecutive_failures = 0
                new_added = 0
                for item in results:
                    cleaned = unescape_opentdb_data(item, category_name)
                    q_text = cleaned["question"]
                    norm_q = normalize_text(q_text)
                    if norm_q and norm_q not in seen_questions:
                        seen_questions.add(norm_q)
                        category_questions.append(cleaned)
                        sub_collected += 1
                        new_added += 1

                print(f"    [OpenTDB] +{new_added} unique questions. Total for category: {len(category_questions)}/{target_count}")
                time.sleep(OPENTDB_DELAY_SECONDS)

    # --- Phase 2: Secondary Fallback to QuizQuestions.org if short of target ---
    shortfall = target_count - len(category_questions)
    if shortfall > 0 and category_name in QQO_CATEGORY_MAPPING:
        print(f"  [QuizQuestions.org] Shortfall of {shortfall} questions. Querying secondary database...")
        slugs = QQO_CATEGORY_MAPPING[category_name]

        for slug in slugs:
            if len(category_questions) >= target_count:
                break

            print(f"  [QuizQuestions.org] Fetching slug: '{slug}'...")
            qqo_results = fetch_qqo_category(slug)
            new_added = 0

            for q in qqo_results:
                if len(category_questions) >= target_count:
                    break
                q_text = q["question"]
                norm_q = normalize_text(q_text)
                if norm_q and norm_q not in seen_questions:
                    seen_questions.add(norm_q)
                    q["category"] = category_name
                    category_questions.append(q)
                    new_added += 1

            print(f"    [QuizQuestions.org] +{new_added} unique questions from '{slug}'. Total: {len(category_questions)}/{target_count}")
            time.sleep(1.0)  # Gentle delay between page fetches

    print(f"Finished '{category_name}': collected {len(category_questions)} questions.")
    return category_questions


def main():
    target_total = 3000
    categories = list(OPENTDB_CATEGORY_MAPPING.keys())
    per_category_target = target_total // len(categories)  # 250 per category

    # Determine paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    workspace_root = os.path.abspath(os.path.join(script_dir, ".."))
    output_dir = os.path.join(workspace_root, "data")
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, "questions_en.json")

    print("==================================================")
    print("      Quizbattles Multi-Source Question Fetcher   ")
    print("==================================================")
    print(f"Target Total:      ~{target_total} questions")
    print(f"Categories (12):   {', '.join(categories)}")
    print(f"Target/Category:   {per_category_target} questions")
    print("Data Sources:      1. Open Trivia DB (Primary)")
    print("                   2. QuizQuestions.org (Secondary Fallback)")
    print(f"Output File:       {output_path}")
    print("==================================================\n")

    token = get_opentdb_token()
    if token:
        print(f"[OpenTDB Session Token Acquired]: {token}\n")

    all_data: Dict[str, List[Dict[str, Any]]] = {}
    seen_questions: Set[str] = set()
    total_fetched = 0
    start_time = time.time()

    for category_name in categories:
        questions = fetch_questions_for_category(
            category_name=category_name,
            target_count=per_category_target,
            opentdb_token=token,
            seen_questions=seen_questions
        )
        all_data[category_name] = questions
        total_fetched += len(questions)

        # Incremental save
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(all_data, f, indent=2, ensure_ascii=False)

    elapsed = time.time() - start_time
    print("\n==================================================")
    print("                 FETCH COMPLETE                   ")
    print("==================================================")
    print(f"Total Questions Saved: {total_fetched}")
    print(f"Output: {output_path}")
    print(f"Total Time: {elapsed / 60:.1f} minutes")
    print("==================================================")


if __name__ == "__main__":
    main()
