#!/usr/bin/env bash
# Install GitHub CLI if needed, then log in. You confirm in the browser.
set -euo pipefail

echo "==> 1/3  GitHub CLI"
if command -v gh >/dev/null 2>&1; then
  echo "    gh déjà là : $(gh --version | head -1)"
else
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew introuvable. Installe-le puis relance ce script." >&2
    exit 1
  fi
  echo "    installation de gh via Homebrew…"
  brew install gh
fi

echo
echo "==> 2/3  Session GitHub"
if gh auth status >/dev/null 2>&1; then
  echo "    déjà connecté :"
  gh auth status
  echo
  echo "Si ce n'est PAS le compte de mr.morad.zekri@gmail.com :"
  echo "    gh auth logout"
  echo "    puis relance ce script."
  exit 0
fi

echo "    login interactif — choisis :"
echo "      • GitHub.com"
echo "      • HTTPS"
echo "      • Login with a web browser"
echo "      • le compte où mr.morad.zekri@gmail.com est vérifié"
echo
gh auth login

echo
echo "==> 3/3  Vérif"
gh auth status
echo
echo "OK. Lance ensuite :"
echo "    ~/.dsh/plugins/dsh-web-search-ollama/scripts/02-publish.sh"
