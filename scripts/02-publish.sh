#!/usr/bin/env bash
# Create the public GitHub repo and push this plugin. Requires 01-auth.sh first.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_NAME="dsh-web-search-ollama"
cd "$ROOT"

echo "==> 1/5  Auth GitHub"
if ! command -v gh >/dev/null 2>&1; then
  echo "gh absent. Lance d'abord : $ROOT/scripts/01-auth.sh" >&2
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "Pas connecté. Lance d'abord : $ROOT/scripts/01-auth.sh" >&2
  exit 1
fi
USER="$(gh api user --jq .login)"
echo "    compte : $USER"

echo
echo "==> 2/5  Auteur git local (ce repo seulement)"
git config --local user.name "Morad Zekri"
git config --local user.email "mr.morad.zekri@gmail.com"
echo "    $(git config --local user.name) <$(git config --local user.email)>"

echo
echo "==> 3/5  Commit des scripts s'il en manque"
if [[ -n "$(git status --porcelain)" ]]; then
  git add scripts README.md DISCUSSION.md package.json lib cordis.patch.yml LICENSE .gitignore
  git commit -m "Add publish scripts for GitHub upload."
fi

echo
echo "==> 4/5  Repo GitHub + push"
if git remote get-url origin >/dev/null 2>&1; then
  echo "    remote origin déjà là : $(git remote get-url origin)"
  git push -u origin HEAD
else
  if gh repo view "$USER/$REPO_NAME" >/dev/null 2>&1; then
    echo "    le repo $USER/$REPO_NAME existe déjà — j'ajoute origin et je push"
    git remote add origin "https://github.com/$USER/$REPO_NAME.git"
    git push -u origin HEAD
  else
    gh repo create "$REPO_NAME" \
      --public \
      --source="$ROOT" \
      --remote=origin \
      --description "Ollama web_search for DeepSeek Harness (no DEEPSEEK_API_KEY)" \
      --push
  fi
fi

URL="https://github.com/$USER/$REPO_NAME"
DISCUSS="https://github.com/deepseek-ai/deepseek-harness/discussions/new?category=show-and-tell"

echo
echo "==> 5/5  Remplacer le placeholder dans le README local (pas re-push auto)"
if grep -q 'YOUR_GITHUB_USER' README.md DISCUSSION.md 2>/dev/null; then
  sed -i.bak "s/YOUR_GITHUB_USER/$USER/g" README.md DISCUSSION.md
  rm -f README.md.bak DISCUSSION.md.bak
  git add README.md DISCUSSION.md
  git commit -m "Fill GitHub username in install docs."
  git push
fi

echo
echo "========================================"
echo "Repo public : $URL"
echo
echo "Ensuite, la « MR / retour » DeepSeek :"
echo "  1. ouvre  $DISCUSS"
echo "  2. colle le fichier DISCUSSION.md (déjà avec ton user)"
echo
echo "Install :"
echo "  dsh plugin --profile web add -w github:$USER/$REPO_NAME"
echo "========================================"
