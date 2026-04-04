#!/usr/bin/env bash
# Sync Org notes with a strict, no-merge Git workflow.

set -euo pipefail

export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

ORG_DIR="${ORG_AUTOCOMMIT_ORG_DIR:-$HOME/Org}"
MODEL="${ORG_AUTOCOMMIT_MODEL:-qwen2.5:14b}"
LOG_DIR="${ORG_AUTOCOMMIT_LOG_DIR:-$HOME/Library/Logs/org-autocommit}"
LOCK_DIR="${ORG_AUTOCOMMIT_LOCK_DIR:-/tmp/org-autocommit.lock}"
MODE="${ORG_AUTOCOMMIT_MODE:-full-sync}"
MAX_DIFF_FILES="${ORG_AUTOCOMMIT_MAX_DIFF_FILES:-12}"
MAX_DIFF_LINES_PER_FILE="${ORG_AUTOCOMMIT_MAX_DIFF_LINES_PER_FILE:-80}"
TITLE_MAX_LEN="${ORG_AUTOCOMMIT_TITLE_MAX_LEN:-50}"
HOSTNAME_LABEL="${ORG_AUTOCOMMIT_HOSTNAME_LABEL:-$(hostname -s 2>/dev/null || hostname)}"
DRY_RUN="${ORG_AUTOCOMMIT_DRY_RUN:-0}"
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
  rm -f "${MSG_FILE:-}" 2>/dev/null || true
  rmdir "$LOCK_DIR" 2>/dev/null || true
}

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  log "Another run is active; skipping."
  exit 0
fi
trap cleanup EXIT

case "$MODE" in
  commit-only|full-sync)
    ;;
  *)
    log "Invalid ORG_AUTOCOMMIT_MODE: $MODE"
    exit 1
    ;;
esac

log "=== Run start (mode=$MODE org_dir=$ORG_DIR model=$MODEL dry_run=$DRY_RUN) ==="

if [[ ! -d "$ORG_DIR" ]]; then
  log "Org directory does not exist: $ORG_DIR"
  exit 1
fi

git_org() {
  git -C "$ORG_DIR" "$@"
}

if ! git_org rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  log "Not a git repository: $ORG_DIR"
  exit 1
fi

repo_root="$(git_org rev-parse --show-toplevel 2>/dev/null || echo "$ORG_DIR")"

notify_user() {
  local title="$1"
  local body="$2"

  if command -v osascript >/dev/null 2>&1; then
    osascript \
      -e 'on run argv' \
      -e 'display notification (item 2 of argv) with title (item 1 of argv)' \
      -e 'end run' \
      "$title" "$body" >/dev/null 2>&1 || true
    return
  fi

  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$body" >/dev/null 2>&1 || true
  fi
}

abort_with_notification() {
  local reason="$1"
  log "$reason"
  notify_user "Org sync needs attention" "$reason"
  exit 1
}

has_worktree_changes() {
  [[ -n "$(git_org status --short --untracked-files=normal 2>/dev/null)" ]]
}

has_unmerged_files() {
  [[ -n "$(git_org diff --name-only --diff-filter=U 2>/dev/null)" ]]
}

has_in_progress_operation() {
  local git_dir
  git_dir="$(git_org rev-parse --git-dir)"

  [[ -f "$git_dir/MERGE_HEAD" ]] \
    || [[ -f "$git_dir/CHERRY_PICK_HEAD" ]] \
    || [[ -d "$git_dir/rebase-apply" ]] \
    || [[ -d "$git_dir/rebase-merge" ]] \
    || [[ -d "$git_dir/sequencer" ]]
}

get_upstream_ref() {
  if ! git_org rev-parse --verify '@{upstream}' >/dev/null 2>&1; then
    return 0
  fi

  git_org rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true
}

update_ahead_behind() {
  local counts
  if ! counts="$(git_org rev-list --left-right --count "HEAD...$UPSTREAM_REF" 2>/dev/null)"; then
    abort_with_notification "Org sync aborted: upstream branch ${UPSTREAM_REF} is unavailable in $repo_root."
  fi
  read -r AHEAD_COUNT BEHIND_COUNT <<<"$counts"
}

build_commit_prompt() {
  local changed_files diff_excerpts changed_file_count diff_stat diff_numstat file file_excerpt

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
      file_excerpt="$(git_org diff --cached --unified=0 -- "$file" | sed -n "1,${MAX_DIFF_LINES_PER_FILE}p")"
      if [[ -n "$file_excerpt" ]]; then
        diff_excerpts+="$file_excerpt"$'\n'
      else
        diff_excerpts+="(No text diff excerpt available.)"$'\n'
      fi
      diff_excerpts+=$'\n'
    fi
  done < <(git_org diff --cached --name-only)

  changed_files="${changed_files%$'\n'}"
  if [[ -z "$changed_files" ]]; then
    changed_files="(No changed files listed.)"
  fi

  if [[ $changed_file_count -gt $MAX_DIFF_FILES ]]; then
    diff_excerpts+="(Only the first ${MAX_DIFF_FILES} files are expanded; total changed files: ${changed_file_count}.)"
  fi

  diff_stat="$(git_org diff --cached --stat)"
  diff_numstat="$(git_org diff --cached --numstat | sed -n '1,200p')"

  cat <<EOF
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
}

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
  if [[ -z "$title" ]]; then
    fallback_title="Update Org notes"
    title="$fallback_title"
  fi

  body="$(printf '%s\n' "$cleaned" | tail -n +2)"
  body="$(printf '%s\n' "$body" | sed '1{/^[[:space:]]*$/d;}')"

  if [[ -z "$(printf '%s' "$body" | tr -d '[:space:]')" ]]; then
    body="$(fallback_message | tail -n +3)"
  fi

  body="$(printf '%s\n' "$body" | sed 's/[[:space:]]*$//' | fold -s -w 72)"

  printf '%s%s\n\n%s\n' "$prefix" "$title" "$body"
}

create_commit() {
  local git_add_output commit_message committed_title ai_message prompt

  if ! git_add_output="$(git_org add -A 2>&1)"; then
    log "git add failed at $ORG_DIR: $git_add_output"
    exit 1
  fi

  if git_org diff --cached --quiet; then
    log "No staged changes after git add."
    return 0
  fi

  prompt="$(build_commit_prompt)"
  ai_message="$(run_ollama "$prompt" 2>>"$RUN_LOG" || true)"

  if [[ -z "$(printf '%s' "$ai_message" | tr -d '[:space:]')" ]]; then
    log "Ollama unavailable or failed; using fallback message."
    ai_message="$(fallback_message)"
  fi

  commit_message="$(normalize_message "$ai_message")"
  MSG_FILE="$(mktemp "${TMPDIR:-/tmp}/org-commit-msg.XXXXXX")"
  printf '%s\n' "$commit_message" > "$MSG_FILE"

  if [[ "$DRY_RUN" == "1" ]]; then
    log "Dry run enabled. Generated commit message:"
    while IFS= read -r line; do
      log "  $line"
    done < "$MSG_FILE"
    log "Dry run enabled; skipping git commit."
    return 0
  fi

  if git_org commit -F "$MSG_FILE" >> "$RUN_LOG" 2>&1; then
    committed_title="$(head -n 1 "$MSG_FILE")"
    log "Committed successfully: $committed_title"
  else
    log "git commit failed."
    exit 1
  fi
}

run_commit_only_mode() {
  if has_unmerged_files; then
    abort_with_notification "Org auto-commit aborted: unmerged files are present in $repo_root."
  fi

  if has_in_progress_operation; then
    abort_with_notification "Org auto-commit aborted: merge, rebase, or cherry-pick is already in progress in $repo_root."
  fi

  if has_worktree_changes; then
    create_commit
  else
    log "No local changes detected for commit-only run."
  fi
}

run_full_sync_mode() {
  UPSTREAM_REF="$(get_upstream_ref)"
  if [[ -z "$UPSTREAM_REF" ]]; then
    abort_with_notification "No upstream branch is configured for $repo_root."
  fi

  if ! git_org fetch origin >> "$RUN_LOG" 2>&1; then
    abort_with_notification "git fetch origin failed for $repo_root."
  fi

  if has_unmerged_files; then
    abort_with_notification "Org sync aborted: unmerged files are present in $repo_root."
  fi

  if has_in_progress_operation; then
    abort_with_notification "Org sync aborted: merge, rebase, or cherry-pick is already in progress in $repo_root."
  fi

  update_ahead_behind

  if (( BEHIND_COUNT > 0 )) && has_worktree_changes; then
    abort_with_notification "Org sync aborted: local changes exist while branch is behind ${UPSTREAM_REF}."
  fi

  if (( AHEAD_COUNT > 0 && BEHIND_COUNT > 0 )); then
    abort_with_notification "Org sync aborted: local branch diverged from ${UPSTREAM_REF}."
  fi

  if (( BEHIND_COUNT > 0 )); then
    if [[ "$DRY_RUN" == "1" ]]; then
      log "Dry run enabled; would run git pull --ff-only."
    elif git_org pull --ff-only >> "$RUN_LOG" 2>&1; then
      log "Fast-forward pull completed successfully."
    else
      abort_with_notification "Org sync aborted: fast-forward pull failed for $repo_root."
    fi
  fi

  if (( BEHIND_COUNT == 0 )) && has_worktree_changes; then
    create_commit
  fi

  update_ahead_behind

  if (( AHEAD_COUNT > 0 && BEHIND_COUNT > 0 )); then
    abort_with_notification "Org sync aborted: local branch diverged from ${UPSTREAM_REF}."
  fi

  if (( AHEAD_COUNT > 0 )); then
    if [[ "$DRY_RUN" == "1" ]]; then
      log "Dry run enabled; would run git push origin."
    elif git_org push origin >> "$RUN_LOG" 2>&1; then
      log "Pushed successfully."
    else
      abort_with_notification "Org sync aborted: git push origin failed for $repo_root."
    fi
  fi

  if ! has_worktree_changes && (( AHEAD_COUNT == 0 )) && (( BEHIND_COUNT == 0 )); then
    log "Org repo is clean and in sync."
  fi
}

case "$MODE" in
  commit-only)
    run_commit_only_mode
    ;;
  full-sync)
    run_full_sync_mode
    ;;
esac
