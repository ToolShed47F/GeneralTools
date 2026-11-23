#!/usr/bin/env bash
# Registers the "gclip" command in ~/.zshrc or ~/.bashrc.
# gclip: copies the code block in clipboard.md (GeneralTools, clipboard branch) to the clipboard.
# Usage:  curl -fsSL https://raw.githubusercontent.com/ToolShed47F/GeneralTools/clipboard/install.sh | bash
# Re-running replaces the existing gclip block. Set GH_TOKEN to raise the API rate limit.
set -e

case "$(basename "${SHELL:-bash}")" in
  zsh) rc="$HOME/.zshrc" ;;
  *)   rc="$HOME/.bashrc" ;;
esac
touch "$rc"

# Remove any previous block
tmp="$(mktemp)"
awk '/^# >>> gclip >>>$/{skip=1} !skip{print} /^# <<< gclip <<<$/{skip=0}' "$rc" > "$tmp"
cat "$tmp" > "$rc"
rm -f "$tmp"

cat >> "$rc" <<'EOF'
# >>> gclip >>>
gclip() {
  local url='https://api.github.com/repos/ToolShed47F/GeneralTools/contents/clipboard.md?ref=clipboard'
  local body v
  if [ -n "$GH_TOKEN" ]; then
    body="$(curl -fsSL -H 'Accept: application/vnd.github.raw' -H "Authorization: Bearer $GH_TOKEN" "$url")" || { echo "gclip: fetch failed" >&2; return 1; }
  else
    body="$(curl -fsSL -H 'Accept: application/vnd.github.raw' "$url")" || { echo "gclip: fetch failed" >&2; return 1; }
  fi
  v="$(printf '%s\n' "$body" | awk '/^```/{f=!f;next} f')"
  [ -n "$v" ] || { echo "gclip: no code block found" >&2; return 1; }
  if command -v pbcopy >/dev/null 2>&1; then printf %s "$v" | pbcopy
  elif [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null 2>&1; then printf %s "$v" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then printf %s "$v" | xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then printf %s "$v" | xsel --clipboard --input
  elif command -v clip.exe >/dev/null 2>&1; then printf %s "$v" | iconv -f UTF-8 -t UTF-16LE | clip.exe
  else printf '%s\n' "$v"; echo "gclip: no clipboard tool found (printed instead)" >&2; return 1
  fi
  echo "copied: $v"
}
# <<< gclip <<<
EOF

echo "gclip registered in $rc"
echo "Run 'source $rc' or open a new terminal to use it."
