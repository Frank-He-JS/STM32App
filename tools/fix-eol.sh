#!/usr/bin/env bash
# Convert CRLF -> LF for text files in the working tree.
# STM32CubeMX always writes CRLF on Windows; run this after every
# code generation so git shows only real changes.
#
# Usage (from Git Bash or MobaXterm, anywhere inside the repo):
#   bash tools/fix-eol.sh          # convert
#   bash tools/fix-eol.sh -n       # dry run: list files only
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

dry_run=0
[ "${1:-}" = "-n" ] && dry_run=1

# Tracked + untracked (not ignored) files whose working copy has CRLF,
# limited to files git treats as text (binary/-text attrs are skipped).
# Build output folders (Debug/, Release/) are left alone.
exclude=(':(exclude)Debug/' ':(exclude)Release/')
mapfile -t files < <(
  { git ls-files --eol -- . "${exclude[@]}"
    git ls-files --others --exclude-standard --eol -- . "${exclude[@]}"; } |
    awk '($2 == "w/crlf" || $2 == "w/mixed") && $3 !~ /-text/ {
           sub(/^[^\t]*\t/, ""); print }'
)

if [ ${#files[@]} -eq 0 ]; then
  echo "fix-eol: no CRLF files, nothing to do."
  exit 0
fi

for f in "${files[@]}"; do
  if [ $dry_run -eq 1 ]; then
    echo "would fix: $f"
  else
    sed -i 's/\r$//' "$f"
    echo "fixed: $f"
  fi
done

[ $dry_run -eq 1 ] && echo "fix-eol: ${#files[@]} file(s) would be converted." \
                   || echo "fix-eol: converted ${#files[@]} file(s) to LF."

# Refresh the index so 'git status' drops files whose only change was CRLF.
[ $dry_run -eq 1 ] || git update-index -q --refresh || true
