#!/bin/bash
# One-command portfolio deploy. Prereq: `gh auth login` (once).
# Creates/updates the public repo and serves index.html via GitHub Pages.
set -euo pipefail
cd "$(dirname "$0")"
REPO="portfolio"

gh auth status >/dev/null || { echo "Run: gh auth login"; exit 1; }
USER=$(gh api user -q .login)

git add -A
git diff --cached --quiet || git commit -m "Update portfolio"

if ! gh repo view "$USER/$REPO" >/dev/null 2>&1; then
    gh repo create "$REPO" --public --source=. --push
else
    git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$USER/$REPO.git"
    git push -u origin main
fi

# Enable Pages from main:/ (idempotent — 409 means already enabled)
gh api "repos/$USER/$REPO/pages" -f 'source[branch]=main' -f 'source[path]=/' 2>/dev/null \
    || gh api -X PUT "repos/$USER/$REPO/pages" -f 'source[branch]=main' -f 'source[path]=/' >/dev/null 2>&1 || true

echo
echo "Live in ~1 min at: https://$USER.github.io/$REPO/"
