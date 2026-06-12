#!/usr/bin/env bash
# coverage.sh — JOBBees MVP feature coverage report
#
# Reads inventory/JOBBees_Feature_Inventory.csv and reports how much of the
# IN + IN★ scope has been marked "done" in the "Your Decision" column.
#
# Usage:
#   ./scripts/coverage.sh                          # human-readable summary
#   ./scripts/coverage.sh --by-section             # break down by Section
#   ./scripts/coverage.sh --by-sprint <N>          # only rows assigned to sprint N
#   ./scripts/coverage.sh --csv                    # machine-readable CSV
#   ./scripts/coverage.sh --remaining              # list every IN/IN★ NOT yet done
#
# How to mark a row done:
#   In inventory/JOBBees_Feature_Inventory.csv, set the "Your Decision"
#   column (col 9) to "done" or "done [sprint-N]" or "done [sprint-N, PR#42]".
#
# This file uses python for CSV parsing (handles quoted fields with commas
# correctly — naive awk splits would break on "Email signup (first name,
# last name, ...)" style rows).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CSV_PATH="${REPO_ROOT}/inventory/JOBBees_Feature_Inventory.csv"

if [ ! -f "$CSV_PATH" ]; then
  echo "ERROR: inventory CSV not found at $CSV_PATH" >&2
  echo "Note: inventory/ is gitignored; this script only works when the CSV is present locally." >&2
  exit 1
fi

MODE="${1:---summary}"
ARG="${2:-}"

python3 - "$CSV_PATH" "$MODE" "$ARG" <<'PY'
import csv, sys, collections

csv_path, mode, arg = sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else ""

# Column indices (0-based) — matches inventory CSV header:
# ID, Surface, Section, Item, Architect Note, Call, Hours, Notes/Reason,
# Your Decision, Your Comment
COL_ID, COL_SURFACE, COL_SECTION, COL_ITEM = 0, 1, 2, 3
COL_CALL, COL_HOURS, COL_DECISION = 5, 6, 8

def is_in_scope(row):
    return row[COL_CALL].strip() in ("IN", "IN★")

def is_done(row):
    return "done" in row[COL_DECISION].strip().lower()

def hours(row):
    try:
        return float(row[COL_HOURS]) if row[COL_HOURS].strip() else 0.0
    except ValueError:
        return 0.0

def sprint_of(row):
    # Heuristic: "done [sprint-3]" or "sprint-3" anywhere in decision/comment
    text = row[COL_DECISION].lower()
    import re
    m = re.search(r"sprint[- ]?(\d+)", text)
    return int(m.group(1)) if m else None

with open(csv_path, newline='', encoding='utf-8') as f:
    reader = csv.reader(f)
    header = next(reader)
    rows = [r for r in reader if r and r[COL_ID].strip()]

in_scope = [r for r in rows if is_in_scope(r)]
done_rows = [r for r in in_scope if is_done(r)]

total_count = len(in_scope)
done_count = len(done_rows)
total_hours = sum(hours(r) for r in in_scope)
done_hours = sum(hours(r) for r in done_rows)

if mode in ("--summary", ""):
    pct_count = (done_count * 100 // total_count) if total_count else 0
    pct_hours = (done_hours * 100 / total_hours) if total_hours else 0
    print(f"JOBBees MVP coverage")
    print(f"  By count:  {done_count} / {total_count} IN+IN★ features done ({pct_count}%)")
    print(f"  By hours:  {done_hours:.0f} / {total_hours:.0f} hours done ({pct_hours:.0f}%)")
    print(f"  Remaining: {total_count - done_count} features, {total_hours - done_hours:.0f} hours")

elif mode == "--by-section":
    sections = collections.defaultdict(lambda: [0, 0, 0.0, 0.0])  # done, total, donehrs, totalhrs
    for r in in_scope:
        key = f"{r[COL_SURFACE]} / {r[COL_SECTION]}"
        sections[key][1] += 1
        sections[key][3] += hours(r)
        if is_done(r):
            sections[key][0] += 1
            sections[key][2] += hours(r)
    print(f"{'Section':<60} {'Done':>10} {'Hours':>15}")
    print("-" * 90)
    for sec in sorted(sections.keys()):
        d, t, dh, th = sections[sec]
        pct = (d*100//t) if t else 0
        print(f"{sec[:58]:<60} {d:>3}/{t:<3} ({pct:>3}%) {dh:>5.0f}/{th:<5.0f}h")

elif mode == "--by-sprint":
    if not arg:
        print("ERROR: --by-sprint requires sprint number, e.g. --by-sprint 3", file=sys.stderr)
        sys.exit(2)
    target_sprint = int(arg)
    sprint_rows = [r for r in in_scope if sprint_of(r) == target_sprint]
    s_done = [r for r in sprint_rows if is_done(r)]
    s_total = len(sprint_rows)
    s_done_n = len(s_done)
    s_hours = sum(hours(r) for r in sprint_rows)
    s_done_hrs = sum(hours(r) for r in s_done)
    print(f"Sprint {target_sprint} coverage")
    print(f"  Features: {s_done_n} / {s_total} done ({(s_done_n*100//s_total) if s_total else 0}%)")
    print(f"  Hours:    {s_done_hrs:.0f} / {s_hours:.0f} done")
    print()
    print("Remaining in this sprint:")
    for r in sprint_rows:
        if not is_done(r):
            print(f"  #{r[COL_ID]:>3} [{r[COL_SURFACE]:<7}] {r[COL_ITEM][:80]}")

elif mode == "--csv":
    print("metric,done,total,pct")
    print(f"features,{done_count},{total_count},{(done_count*100//total_count) if total_count else 0}")
    print(f"hours,{done_hours:.0f},{total_hours:.0f},{(done_hours*100/total_hours) if total_hours else 0:.0f}")

elif mode == "--remaining":
    print(f"{'ID':>5}  {'Surface':<8}  {'Hours':>5}  Item")
    print("-" * 100)
    for r in in_scope:
        if not is_done(r):
            print(f"{r[COL_ID]:>5}  {r[COL_SURFACE][:8]:<8}  {hours(r):>5.0f}  {r[COL_ITEM][:80]}")

else:
    print(f"Unknown mode: {mode}", file=sys.stderr)
    print("Usage: coverage.sh [--summary|--by-section|--by-sprint N|--csv|--remaining]", file=sys.stderr)
    sys.exit(2)
PY
