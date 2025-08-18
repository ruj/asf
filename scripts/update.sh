#!/bin/bash
set -e

BRANCH="master"

git add -A || true

MESSAGE="$(git status --porcelain | wc -l) files | $(git status --porcelain | sed '{:q;N;s/\n/, /g;t q}' | sed 's/^ *//g')"

git commit -a -m "$MESSAGE" || true

git push origin "$BRANCH" || true

echo "Files committed and pushed!"
