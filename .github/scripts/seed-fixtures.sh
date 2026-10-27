#!/usr/bin/env bash
# Recreates a fixture session branch from the captures committed under
# .claudinite/canary-fixtures when origin has none. Run from a checkout of
# main with GITHUB_TOKEN and GITHUB_REPOSITORY set.
#   seed-fixtures.sh conversation-logs   four captures in three commits, the
#                                        first pruned from the tip
#   seed-fixtures.sh agent-sessions      one plaintext capture
set -euo pipefail
branch=${1:?conversation-logs or agent-sessions}
url="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
if git ls-remote --exit-code --heads "$url" "$branch" > /dev/null; then
  echo "$branch already exists; nothing to seed"
  exit 0
fi
fixtures="$PWD/.claudinite/canary-fixtures/$branch"
work=$(mktemp -d)
cd "$work"
git init -q -b "$branch"
git config user.name "claudinite-canary"
git config user.email "canary@users.noreply.github.com"
captures=("$fixtures"/*.jsonl)
case $branch in
  conversation-logs)
    if [ "${#captures[@]}" -ne 4 ]; then
      echo "::error::expected four fixture captures, found ${#captures[@]}"
      exit 1
    fi
    cp "${captures[0]}" "${captures[1]}" .
    git add .
    git commit -q -m "fixture captures 1-2"
    cp "${captures[2]}" .
    git add .
    git commit -q -m "fixture capture 3"
    cp "${captures[3]}" .
    git rm -q "$(basename "${captures[0]}")"
    git add .
    git commit -q -m "fixture capture 4, capture 1 pruned"
    ;;
  agent-sessions)
    cp "${captures[@]}" .
    git add .
    git commit -q -m "fixture capture"
    ;;
  *)
    echo "::error::no fixtures for branch $branch"
    exit 1 ;;
esac
git push -q "$url" "$branch"
echo "seeded $branch: $(git rev-list --count HEAD) commits, $(ls | wc -l) captures at the tip"
