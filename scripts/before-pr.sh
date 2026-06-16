#!/usr/bin/env bash
#
# before-pr.sh — Run every gate that CI will run, locally, before opening a PR.
# Catches the embarrassing class of failures (lint, typecheck, missing tests)
# before they hit GitHub Actions and waste a CI minute + a code review cycle.
#
# Usage:
#   ./scripts/before-pr.sh                    Run everything
#   ./scripts/before-pr.sh --fast             Skip slow gates (tests, gitleaks)
#   ./scripts/before-pr.sh --only typecheck   Run only typecheck
#
# Suggested shell alias (add to ~/.zshrc or ~/.bashrc):
#   alias bpr="./scripts/before-pr.sh"
#

set -e  # exit on first failure

# ---------- Config ----------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Colours (TTY only)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'  # No Colour
else
    GREEN=''; RED=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

# ---------- Args ----------

MODE="all"
ONLY_GATE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --fast) MODE="fast"; shift ;;
        --only) ONLY_GATE="$2"; shift 2 ;;
        --help|-h)
            sed -n '2,/^$/p' "$0" | sed 's/^# //; s/^#//'
            exit 0
            ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done

# ---------- Helpers ----------

START_TIME=$(date +%s)
FAILED_GATES=()

print_header() {
    echo
    echo -e "${BOLD}${BLUE}━━━ $1 ━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_failure() {
    echo -e "${RED}✗${NC} $1"
}

print_skip() {
    echo -e "${YELLOW}↷${NC} $1 (skipped)"
}

should_run() {
    local gate="$1"
    if [ -n "$ONLY_GATE" ] && [ "$ONLY_GATE" != "$gate" ]; then
        return 1
    fi
    return 0
}

run_gate() {
    local name="$1"
    local cmd="$2"
    if ! should_run "$name"; then
        return 0
    fi
    print_header "$name"
    if eval "$cmd"; then
        print_success "$name passed"
    else
        print_failure "$name failed"
        FAILED_GATES+=("$name")
    fi
}

# ---------- Pre-flight ----------

print_header "Pre-flight"

# Git state
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠${NC}  Uncommitted changes detected. Continuing anyway."
fi

# Branch sanity
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "main" ]; then
    echo -e "${RED}✗${NC} On main branch. Open a branch first."
    exit 1
fi
echo "Branch: $CURRENT_BRANCH"

# Conventional Commits sanity (just a hint, not a gate)
COMMIT_PATTERN='^(feat|fix|chore|docs|refactor|test|style|perf|build|ci|revert)(\([^)]+\))?: .+'
LATEST_COMMIT_MSG=$(git log -1 --pretty=%s)
if ! echo "$LATEST_COMMIT_MSG" | grep -qE "$COMMIT_PATTERN"; then
    echo -e "${YELLOW}⚠${NC}  Latest commit message doesn't match Conventional Commits format."
    echo "    Got: $LATEST_COMMIT_MSG"
fi

# ---------- Gates ----------

# 1. Format check (fast)
run_gate "format" "pnpm format:check"

# 2. Lint (fast)
run_gate "lint" "pnpm lint"

# 3. Typecheck (medium)
run_gate "typecheck" "pnpm typecheck"

# 4. Tests (slow — skip with --fast)
if [ "$MODE" = "fast" ] && [ -z "$ONLY_GATE" ]; then
    print_skip "tests"
else
    run_gate "test" "pnpm test"
fi

# 5. Secrets / gitleaks (slow — skip with --fast)
if [ "$MODE" = "fast" ] && [ -z "$ONLY_GATE" ]; then
    print_skip "gitleaks"
elif command -v gitleaks >/dev/null 2>&1; then
    run_gate "gitleaks" "gitleaks detect --source . --verbose --redact --no-git --config=.gitleaks.toml 2>/dev/null || gitleaks detect --source . --verbose --redact --no-git"
else
    print_skip "gitleaks (not installed — brew install gitleaks)"
fi

# 6. Semgrep (slow — skip with --fast)
if [ "$MODE" = "fast" ] && [ -z "$ONLY_GATE" ]; then
    print_skip "semgrep"
elif command -v semgrep >/dev/null 2>&1; then
    run_gate "semgrep" "semgrep --config ops/security/semgrep-rules.yml --error --quiet"
else
    print_skip "semgrep (not installed — brew install semgrep)"
fi

# 7. Pnpm audit (fast, online)
run_gate "audit" "pnpm audit --audit-level=high"

# 8. Inventory coverage check (fast)
if should_run "coverage"; then
    print_header "coverage"
    if [ -f "scripts/coverage.sh" ]; then
        bash scripts/coverage.sh --check-only && print_success "coverage check passed" || {
            print_failure "coverage check failed"
            FAILED_GATES+=("coverage")
        }
    else
        print_skip "coverage (scripts/coverage.sh missing)"
    fi
fi

# ---------- Summary ----------

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo
print_header "Summary"
echo "Elapsed: ${ELAPSED}s"

if [ ${#FAILED_GATES[@]} -eq 0 ]; then
    echo -e "${GREEN}${BOLD}All gates passed.${NC} Safe to push + open PR."
    echo
    echo "Suggested PR title format: <conventional-commit-type>(<scope>): <one-line summary>"
    echo "Example:                  feat(api/auth): magic-link login with rate-limit"
    exit 0
else
    echo -e "${RED}${BOLD}Failed gates:${NC}"
    for gate in "${FAILED_GATES[@]}"; do
        echo "  - $gate"
    done
    echo
    echo "Re-run a single gate:  ./scripts/before-pr.sh --only <gate>"
    echo "Skip slow gates:       ./scripts/before-pr.sh --fast"
    exit 1
fi
