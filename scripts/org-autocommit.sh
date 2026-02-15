#!/usr/bin/env bash
# Auto-commit Org notes using Ollama-generated commit messages.

set -euo pipefail

export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

ORG_DIR="${ORG_AUTOCOMMIT_ORG_DIR:-$HOME/Org}"
MODEL="${ORG_AUTOCOMMIT_MODEL:-qwen2.5:14b}"
LOG_DIR="${ORG_AUTOCOMMIT_LOG_DIR:-$HOME/Library/Logs/org-autocommit}"
LOCK_DIR="${ORG_AUTOCOMMIT_LOCK_DIR:-/tmp/org-autocommit.lock}"
MAX_DIFF_FILES="${ORG_AUTOCOMMIT_MAX_DIFF_FILES:-12}"
MAX_DIFF_LINES_PER_FILE="${ORG_AUTOCOMMIT_MAX_DIFF_LINES_PER_FILE:-80}"
TITLE_MAX_LEN="${ORG_AUTOCOMMIT_TITLE_MAX_LEN:-50}"
HOSTNAME_LABEL="${ORG_AUTOCOMMIT_HOSTNAME_LABEL:-$(hostname -s 2>/dev/null || hostname)}"
TITLE_CONTENT_MAX_LEN=$((TITLE_MAX_LEN - ${#HOSTNAME_LABEL} - 2))
if (( TITLE_CONTENT_MAX_LEN < 1 )); then
  TITLE_CONTENT_MAX_LEN=1
fi

if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
  LOG_DIR="/tmp/org-autocommit-logs"
  mkdir -p "$LOG_DIR"
fi
RUN_LOG="$LOG_DIR/org-autocommit.log"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$RUN_LOG"
}

cleanup() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  log "Another run is active; skipping."
  exit 0
fi
trap cleanup EXIT

log "=== Run start (org_dir=$ORG_DIR model=$MODEL) ==="

if [[ ! -d "$ORG_DIR" ]]; then
  log "Org directory does not exist: $ORG_DIR"
  exit 1
fi

cd "$ORG_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  log "Not a git repository: $ORG_DIR"
  exit 1
fi

if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  log "No changes detected."
  exit 0
fi

git add -A

if git diff --cached --quiet; then
  log "No staged changes after git add."
  exit 0
fi

changed_files=""
diff_excerpts=""
changed_file_count=0

while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  changed_file_count=$((changed_file_count + 1))
  if [[ $changed_file_count -le 40 ]]; then
    changed_files+="$file"$'\n'
  fi

  if [[ $changed_file_count -le $MAX_DIFF_FILES ]]; then
    diff_excerpts+="### $file"$'\n'
    file_excerpt="$(git diff --cached --unified=0 -- "$file" | sed -n "1,${MAX_DIFF_LINES_PER_FILE}p")"
    if [[ -n "$file_excerpt" ]]; then
      diff_excerpts+="$file_excerpt"$'\n'
    else
      diff_excerpts+="(No text diff excerpt available.)"$'\n'
    fi
    diff_excerpts+=$'\n'
  fi
done < <(git diff --cached --name-only)

changed_files="${changed_files%$'\n'}"
if [[ -z "$changed_files" ]]; then
  changed_files="(No changed files listed.)"
fi

if [[ $changed_file_count -gt $MAX_DIFF_FILES ]]; then
  diff_excerpts+="(Only the first ${MAX_DIFF_FILES} files are expanded; total changed files: ${changed_file_count}.)"
fi

diff_stat="$(git diff --cached --stat)"
diff_numstat="$(git diff --cached --numstat | sed -n '1,200p')"

prompt="$(cat <<EOF
I am writing a git commit message for Org Mode notes.
These are personal/work notes, not software source code.

Rules:
- Output plain text only.
- Do not use any markdown or other formatting except for dashes, bullets, or numbered lists if needed.
- First line is the commit title text.
- Write it in imperative mood and do not end it with a period.
- Keep it at most ${TITLE_CONTENT_MAX_LEN} characters.
- Then one blank line.
- Then 2-5 lines of body text wrapped to about 72 chars.
- Body should summarize note topics and intent (plans, meetings, todos, reflections).
- Cover the overall changes across all modified files, not only one file.
- Do not mention code, tests, refactors, or implementation language.
- Do not say I'm "Fixing things" unless the notes describe something being fixed.
- Do not quote or transcribe note sentences verbatim from the diff.
- Do not invent details that are not in the diff.
- Do not include timestamps
- Do not say something like "Update notes" in the title; that's redundant.


Changed file count:
$changed_file_count

Changed files (make sure that in the summary you cover the overall changes across all these files, not just one):
$changed_files

Diff stat:
$diff_stat

Diff numstat:
$diff_numstat

Per-file diff excerpts (unified=0, capped per file, this is the content that I want to summarize for the commit message):
$diff_excerpts
EOF
)"

run_ollama() {
  local input="$1"
  if ! command -v ollama >/dev/null 2>&1; then
    return 1
  fi

  if command -v gtimeout >/dev/null 2>&1; then
    printf '%s' "$input" | gtimeout 45s ollama run "$MODEL"
    return $?
  fi

  if command -v timeout >/dev/null 2>&1; then
    printf '%s' "$input" | timeout 45s ollama run "$MODEL"
    return $?
  fi

  printf '%s' "$input" | ollama run "$MODEL"
}

fallback_message() {
  cat <<EOF
Update Org notes

Capture the latest work and personal note updates.
Record planning, task, and reflection edits from this interval.
EOF
}

normalize_message() {
  local raw="$1"
  local cleaned title body prefix fallback_title

  cleaned="$(printf '%s\n' "$raw" \
    | sed 's/\r$//' \
    | sed '/^```/d' \
    | sed '/./,$!d')"

  title="$(printf '%s\n' "$cleaned" \
    | head -n 1 \
    | tr -s ' ' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  title="$(printf '%s' "$title" | sed 's/\.$//' | sed 's/[[:space:]]*$//')"
  prefix="${HOSTNAME_LABEL}: "
  title="$(printf '%s' "$title" | cut -c1-"$TITLE_CONTENT_MAX_LEN" | sed 's/[[:space:]]*$//')"
  if [[ -z "$title" ]]; then
    fallback_title="Update Org notes"
    title="$(printf '%s' "$fallback_title" | cut -c1-"$TITLE_CONTENT_MAX_LEN" | sed 's/[[:space:]]*$//')"
  fi

  body="$(printf '%s\n' "$cleaned" | tail -n +2)"
  body="$(printf '%s\n' "$body" | sed '1{/^[[:space:]]*$/d;}')"

  if [[ -z "$(printf '%s' "$body" | tr -d '[:space:]')" ]]; then
    body="$(fallback_message | tail -n +3)"
  fi

  body="$(printf '%s\n' "$body" | sed 's/[[:space:]]*$//' | fold -s -w 72)"

  printf '%s%s\n\n%s\n' "$prefix" "$title" "$body"
}

ai_message="$(run_ollama "$prompt" 2>>"$RUN_LOG" || true)"

if [[ -z "$(printf '%s' "$ai_message" | tr -d '[:space:]')" ]]; then
  log "Ollama unavailable or failed; using fallback message."
  ai_message="$(fallback_message)"
fi

commit_message="$(normalize_message "$ai_message")"
msg_file="$(mktemp "${TMPDIR:-/tmp}/org-commit-msg.XXXXXX")"
trap 'rm -f "$msg_file"; cleanup' EXIT
printf '%s\n' "$commit_message" > "$msg_file"

if [[ "${ORG_AUTOCOMMIT_DRY_RUN:-0}" == "1" ]]; then
  log "Dry run enabled. Generated commit message:"
  while IFS= read -r line; do
    log "  $line"
  done < "$msg_file"
  exit 0
fi

if git commit -F "$msg_file" >> "$RUN_LOG" 2>&1; then
  committed_title="$(head -n 1 "$msg_file")"
  log "Committed successfully: $committed_title"
else
  log "git commit failed."
  exit 1
fi

if [[ "${ORG_AUTOCOMMIT_PUSH:-0}" == "1" ]]; then
  if git push >> "$RUN_LOG" 2>&1; then
    log "Pushed successfully."
  else
    log "git push failed."
    exit 1
  fi
fi
