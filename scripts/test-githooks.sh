#!/usr/bin/env bash
# Test what the git hooks in .githooks/ DO, not what their regexes look like.
#
#   ./scripts/test-githooks.sh
#
# Separate from test-hooks.sh because the input contract differs: the Claude
# PreToolUse hooks read a JSON payload on stdin, commit-msg takes a path to a
# message file and pre-push reads ref updates.
#
# The cases that matter most are the ACCEPTS. A commit-msg hook that is too
# tight is worse than none, because the cost lands on every good commit -- the
# measured rule here rejects 16 of the last 40 real commits, all on subject
# length, and every other rule rejects nothing in that window.
set -uo pipefail

REPO=$(git rev-parse --show-toplevel) || exit 2
COMMIT_MSG="$REPO/.githooks/commit-msg"
PRE_PUSH="$REPO/.githooks/pre-push"

for h in "$COMMIT_MSG" "$PRE_PUSH"; do
  [[ -x $h ]] || { echo "error: $h is not executable"; exit 2; }
done

pass=0
fail=0

sandbox=$(mktemp -d -t test-githooks-XXXXXX)
trap 'rm -rf "$sandbox"' EXIT
msgfile="$sandbox/COMMIT_EDITMSG"

zero=0000000000000000000000000000000000000000

# msg <accept|reject> <label> <message>
msg() {
  local expect=$1 label=$2 got=accept
  printf '%s' "$3" > "$msgfile"
  "$COMMIT_MSG" "$msgfile" >/dev/null 2>&1 || got=reject

  if [[ $got == "$expect" ]]; then
    printf '  ok    %-42s -> %s\n' "$label" "$got"
    pass=$((pass + 1))
  else
    printf '  FAIL  %-42s -> %s (wanted %s)\n' "$label" "$got" "$expect"
    fail=$((fail + 1))
  fi
}

# push <accept|reject> <label> <local_sha> <remote_ref> <remote_sha>
push() {
  local expect=$1 label=$2 got=accept
  "$PRE_PUSH" origin git@example.invalid:x.git >/dev/null 2>&1 \
    <<<"refs/heads/main $3 $4 $5" || got=reject

  if [[ $got == "$expect" ]]; then
    printf '  ok    %-42s -> %s\n' "$label" "$got"
    pass=$((pass + 1))
  else
    printf '  FAIL  %-42s -> %s (wanted %s)\n' "$label" "$got" "$expect"
    fail=$((fail + 1))
  fi
}

echo "commit-msg -- must reject:"
msg reject "subject over 72 total" \
  "fix(languages/csharp): report roslyn lifecycle via its User events, not a wrapper"
msg reject "description over 50 after the prefix" \
  "fix(picker): name the layout a preset so select-style sources resolve theirs"
msg reject "trailing period" \
  "fix(oil): drop the redundant keymap."
msg reject "non-imperative opener: fixed" \
  "fixed the AVD lookup on XDG layouts"
msg reject "non-imperative opener: added" \
  "fix(picker): added a preset for select sources"
msg reject "non-imperative opener: updated" \
  "updated the kanagawa palette"
msg reject "non-imperative opener: changed" \
  "changed how the formatter resolves"
msg reject "non-imperative opener: removed" \
  "removed the runtime theme checks"
msg reject "non-imperative opener: refactored" \
  "refactored the variant generator"
msg reject "contentless: wip" "wip"
msg reject "contentless: update file" "update file"
msg reject "contentless: fixes" "fixes"
msg reject "contentless with a prefix" "chore: cleanup"
msg reject "bare tool invocation" "run ktlintFormat"
msg reject "bare tool invocation, two words" "cargo fmt"
msg reject "bare tool invocation, three words" "npm run lint"
msg reject "body line over 80" \
  "fix(picker): name the layout a preset

preset's replacement does not survive there because blink will drop a mapping whose
commands are all snippet commands plus fallback and the cmdline tab would break."

echo "commit-msg -- must accept:"
msg accept "a known-good subject" \
  "fix(picker): name the layout a preset"
msg accept "description at exactly 50 after the prefix" \
  "fix(languages/csharp): fall back to dotnet-sdk_10 and not _8"
msg accept "no prefix, short subject" \
  "Borderless block floats (#9)"
msg accept "fixup! passes through" \
  "fixup! fix(picker): name the layout a preset so select-style sources resolve"
msg accept "squash! passes through" \
  "squash! chore: cleanup"
msg accept "amend! passes through" \
  "amend! wip"
msg accept "Merge subject" \
  "Merge pull request #8 from Marcus441/kotlin-lsp"
msg accept "Revert subject" \
  'Revert "fix(languages/csharp): report roslyn lifecycle via its User events"'
msg accept "empty message (aborted commit)" ""
msg accept "only git comments (aborted commit)" \
  "# Please enter the commit message for your changes.
# On branch main"
msg accept "long trailer URL" \
  "fix(oil): drop the redundant keymap

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01JrGwatu9kWx61AYacbi2rVxxxxxxxxxx"
msg accept "bare URL in the body" \
  "fix(oil): drop the redundant keymap

See https://github.com/notashelf/nvf/blob/main/modules/plugins/utility/oil/oil.nix"
msg accept "Rationale: pointer over 72" \
  "fix(languages/kotlin): persist the index cache

Rationale: docs/decisions/kotlin-lsp.md#the-index-cache-is-persistent-on-purpose"
msg accept "unbreakable token: nix store hash" \
  "fix(x): pin the fallback

min and default are byte-identical (s985iw9p5s9fc4vzm8m9rfkyhsy4sqjf), gui moves."
msg accept "em dash counted as one character" \
  "fix(x): pin the fallback

aaaaaaaaa — aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
msg accept "body line at exactly 80" \
  "fix(x): pin the fallback

12345678901234567890123456789012345678901234567890123456789012345678901234567890"
msg accept "repeated trailer blocks (GitHub squash)" \
  "Borderless block floats (#9)

* feat(theme): make the floats that are panes read as opaque blocks

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>

* fix(session): drop dressing so snacks owns vim.ui.input in gui

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"

echo "pre-push -- must reject:"
push reject "non-fast-forward to main" \
  "$(git -C "$REPO" rev-parse HEAD~3)" refs/heads/main "$(git -C "$REPO" rev-parse HEAD)"
push reject "deleting main" \
  "$zero" refs/heads/main "$(git -C "$REPO" rev-parse HEAD)"

echo "pre-push -- must accept:"
push accept "fast-forward to main" \
  "$(git -C "$REPO" rev-parse HEAD)" refs/heads/main "$(git -C "$REPO" rev-parse HEAD)"
push accept "new branch on the remote" \
  "$(git -C "$REPO" rev-parse HEAD)" refs/heads/main "$zero"
push accept "non-fast-forward to a feature branch" \
  "$(git -C "$REPO" rev-parse HEAD~3)" refs/heads/kotlin-lsp "$(git -C "$REPO" rev-parse HEAD)"

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]] || echo "A commit-msg hook that rejects good messages costs more than it saves. Fix before committing."
exit $((fail > 0))
