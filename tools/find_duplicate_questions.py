#!/usr/bin/env python3
"""
Duplicate Question Finder & Cleaner for Quizbattles.

Analyzes question database JSON files (e.g. data/questions_en.json or data/fallback_questions.json)
to find:
1. Exact duplicates (ignoring case, whitespace, and punctuation).
2. Fuzzy / near-duplicates (e.g. slight rewordings, typos, different question marks).
3. Cross-category duplicates (same question placed in multiple categories).

Usage:
  python tools/find_duplicate_questions.py
  python tools/find_duplicate_questions.py --input data/questions_en.json --similarity 0.85
  python tools/find_duplicate_questions.py --input data/questions_en.json --clean --output data/questions_en_cleaned.json
"""

import argparse
import difflib
import json
import os
import re
import string
from typing import Any, Dict, List, Set, Tuple


def normalize_text(text: str) -> str:
    """Normalizes question text for comparison by lowercasing and removing punctuation/extra whitespace."""
    if not text:
        return ""
    # Lowercase
    text = text.lower()
    # Remove HTML entities if any left
    text = re.sub(r"&\w+;", " ", text)
    # Remove all punctuation and symbols
    text = text.translate(str.maketrans("", "", string.punctuation + "“”‘’¿¡"))
    # Normalize whitespace
    text = re.sub(r"\s+", " ", text).strip()
    return text


def load_questions_file(filepath: str) -> Tuple[Dict[str, List[Dict[str, Any]]], int]:
    """Loads a question JSON file and returns the dictionary and total question count."""
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Questions file not found: {filepath}")

    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, dict):
        raise ValueError("Root JSON structure must be a dictionary of categories to question arrays.")

    total_count = sum(len(q_list) for q_list in data.values() if isinstance(q_list, list))
    return data, total_count


def find_duplicates(
    data: Dict[str, List[Dict[str, Any]]],
    fuzzy_threshold: float = 0.85
) -> Dict[str, Any]:
    """
    Scans questions across all categories for exact and fuzzy duplicates.
    """
    # Flatten questions with metadata
    flat_questions: List[Dict[str, Any]] = []
    for cat_name, q_list in data.items():
        if not isinstance(q_list, list):
            continue
        for idx, item in enumerate(q_list):
            raw_q = item.get("question", "")
            norm_q = normalize_text(raw_q)
            flat_questions.append({
                "category": cat_name,
                "index": idx,
                "raw_question": raw_q,
                "normalized_question": norm_q,
                "correct_answer": item.get("correct_answer", ""),
                "incorrect_answers": item.get("incorrect_answers", []),
                "item_ref": item
            })

    exact_groups: Dict[str, List[Dict[str, Any]]] = {}
    for q in flat_questions:
        norm = q["normalized_question"]
        if not norm:
            continue
        exact_groups.setdefault(norm, []).append(q)

    # Filter only groups with duplicates
    exact_duplicates = {k: v for k, v in exact_groups.items() if len(v) > 1}

    # Find fuzzy / near duplicates among unique normalized questions
    unique_normalized_keys = list(exact_groups.keys())
    fuzzy_pairs: List[Dict[str, Any]] = []

    # Compare pairwise for fuzzy match if threshold < 1.0
    if 0.0 < fuzzy_threshold < 1.0:
        n = len(unique_normalized_keys)
        for i in range(n):
            key_a = unique_normalized_keys[i]
            q_a = exact_groups[key_a][0]
            for j in range(i + 1, n):
                key_b = unique_normalized_keys[j]
                
                # Quick length pre-filter
                len_a, len_b = len(key_a), len(key_b)
                if len_a == 0 or len_b == 0:
                    continue
                if min(len_a, len_b) / max(len_a, len_b) < (fuzzy_threshold - 0.1):
                    continue

                # Similarity ratio
                ratio = difflib.SequenceMatcher(None, key_a, key_b).ratio()
                if ratio >= fuzzy_threshold:
                    q_b = exact_groups[key_b][0]
                    fuzzy_pairs.append({
                        "similarity": round(ratio * 100, 1),
                        "question_a": q_a,
                        "question_b": q_b
                    })

    # Sort fuzzy pairs by similarity descending
    fuzzy_pairs.sort(key=lambda x: x["similarity"], reverse=True)

    return {
        "total_scanned": len(flat_questions),
        "exact_duplicates": exact_duplicates,
        "fuzzy_duplicates": fuzzy_pairs,
        "all_flattened": flat_questions
    }


def clean_dataset(
    data: Dict[str, List[Dict[str, Any]]],
    remove_fuzzy: bool = False,
    fuzzy_threshold: float = 0.88
) -> Tuple[Dict[str, List[Dict[str, Any]]], int]:
    """
    Produces a clean version of the dataset by removing exact duplicates (and optionally near-duplicates).
    """
    seen_normalized: Set[str] = set()
    cleaned_data: Dict[str, List[Dict[str, Any]]] = {}
    removed_count = 0

    for cat_name, q_list in data.items():
        if not isinstance(q_list, list):
            cleaned_data[cat_name] = q_list
            continue

        cleaned_category: List[Dict[str, Any]] = []
        for item in q_list:
            raw_q = item.get("question", "")
            norm = normalize_text(raw_q)

            if not norm:
                continue

            # Check exact duplicate
            if norm in seen_normalized:
                removed_count += 1
                continue

            # Check fuzzy duplicate against already accepted questions if requested
            if remove_fuzzy:
                is_fuzzy_dup = False
                for accepted_norm in seen_normalized:
                    if difflib.SequenceMatcher(None, norm, accepted_norm).ratio() >= fuzzy_threshold:
                        is_fuzzy_dup = True
                        break
                if is_fuzzy_dup:
                    removed_count += 1
                    continue

            seen_normalized.add(norm)
            cleaned_category.append(item)

        cleaned_data[cat_name] = cleaned_category

    return cleaned_data, removed_count


def print_report(results: Dict[str, Any], fuzzy_threshold: float) -> None:
    """Prints a human-readable duplicate analysis report to the console."""
    exact_dups = results["exact_duplicates"]
    fuzzy_dups = results["fuzzy_duplicates"]
    total = results["total_scanned"]

    print("==================================================")
    print("        DUPLICATE QUESTIONS ANALYSIS REPORT       ")
    print("==================================================")
    print(f"Total Questions Analyzed: {total}")
    print(f"Exact Duplicate Groups:   {len(exact_dups)}")
    print(f"Fuzzy/Near Duplicate Pairs ({int(fuzzy_threshold * 100)}%+): {len(fuzzy_dups)}")
    print("==================================================\n")

    if exact_dups:
        print("--- [1] EXACT DUPLICATES (Normalized Text) ---")
        for idx, (norm_key, instances) in enumerate(exact_dups.items(), 1):
            print(f"\nGroup #{idx} ({len(instances)} occurrences):")
            for inst in instances:
                print(f"  [{inst['category']}] \"{inst['raw_question']}\"")
                print(f"      -> Correct: \"{inst['correct_answer']}\"")
        print("\n" + "-" * 50)
    else:
        print("No exact duplicates found.\n")

    if fuzzy_dups:
        print(f"\n--- [2] FUZZY / NEAR DUPLICATES (Similarity >= {int(fuzzy_threshold * 100)}%) ---")
        for idx, pair in enumerate(fuzzy_dups[:25], 1):  # Limit display to top 25
            qa = pair["question_a"]
            qb = pair["question_b"]
            print(f"\nPair #{idx} [{pair['similarity']}% Similarity]:")
            print(f"  1. [{qa['category']}] \"{qa['raw_question']}\"")
            print(f"     -> Answer: \"{qa['correct_answer']}\"")
            print(f"  2. [{qb['category']}] \"{qb['raw_question']}\"")
            print(f"     -> Answer: \"{qb['correct_answer']}\"")
        if len(fuzzy_dups) > 25:
            print(f"\n... and {len(fuzzy_dups) - 25} more near-duplicate pairs.")
        print("\n" + "-" * 50)
    else:
        print("No fuzzy / near duplicates found above the threshold.\n")


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    default_input = os.path.abspath(os.path.join(script_dir, "..", "data", "questions_en.json"))
    fallback_input = os.path.abspath(os.path.join(script_dir, "..", "data", "fallback_questions.json"))

    parser = argparse.ArgumentParser(description="Find and resolve duplicate trivia questions.")
    parser.add_argument(
        "--input", "-i",
        default=default_input if os.path.exists(default_input) else fallback_input,
        help="Path to questions JSON file to check (default: data/questions_en.json or data/fallback_questions.json)"
    )
    parser.add_argument(
        "--similarity", "-s",
        type=float,
        default=0.85,
        help="Fuzzy matching similarity threshold between 0.0 and 1.0 (default: 0.85)"
    )
    parser.add_argument(
        "--clean", "-c",
        action="store_true",
        help="Generate a cleaned JSON file with duplicates removed"
    )
    parser.add_argument(
        "--clean-fuzzy",
        action="store_true",
        help="Also remove fuzzy near-duplicates when --clean is used"
    )
    parser.add_argument(
        "--output", "-o",
        default=None,
        help="Output path for cleaned JSON file (default: overwrites input or creates <name>_cleaned.json)"
    )

    args = parser.parse_args()

    print(f"Loading questions from: {args.input}")
    try:
        data, count = load_questions_file(args.input)
    except Exception as e:
        print(f"Error loading file: {e}")
        sys.exit(1)

    # Analyze duplicates
    results = find_duplicates(data, fuzzy_threshold=args.similarity)
    print_report(results, fuzzy_threshold=args.similarity)

    # Clean if requested
    if args.clean:
        output_file = args.output
        if not output_file:
            base, ext = os.path.splitext(args.input)
            output_file = f"{base}_cleaned{ext}"

        cleaned_data, removed_count = clean_dataset(
            data,
            remove_fuzzy=args.clean_fuzzy,
            fuzzy_threshold=args.similarity
        )
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(cleaned_data, f, indent=2, ensure_ascii=False)

        print("==================================================")
        print("                  CLEANUP RESULT                  ")
        print("==================================================")
        print(f"Total Questions Before: {count}")
        print(f"Duplicates Removed:     {removed_count}")
        print(f"Total Questions After:  {count - removed_count}")
        print(f"Saved Cleaned File To:  {output_file}")
        print("==================================================")


if __name__ == "__main__":
    main()
