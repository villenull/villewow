#!/usr/bin/env bash
# Villenull's Omarchy setup. Safe to re-run: every step checks before acting.
#
#   ./install.sh            run every step, in order
#   ./install.sh link auth  run only the named steps
#   ./install.sh --list     show the steps

set -Eeuo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STEPS=(terminal debloat link chromium text_files media_files clis default_agent claude_desktop shell_plugins auth drop_foot)

# Linked file by file.
STOW_PACKAGES=(hypr omarchy)

REMOVE_PKGS=(
  evince gnome-disk-utility localsend mpv mpv-mpris nvim omarchy-nvim
  sushi system-config-printer tensaku btop
)

CLIS=(claude gh opencode)

TEXT_MIME_TYPES=(text/plain text/markdown text/x-markdown text/x-shellscript application/x-shellscript)

# id|git url
SHELL_PLUGINS=(
  "stappmus.activity-monitor|https://github.com/stappmus/omarchy-activity-monitor.git"
  "io.github.villenull.mimarchy|https://github.com/villenull/Mimarchy.git"
)

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
note() { printf '    %s\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }

# Wait for the user to finish something in the browser. Returns 1 if skipped.
wait_for_user() {
  local answer
  read -rp "    $1 Press Enter when done, or type s to skip: " answer
  [[ $answer != s ]]
}

# --- steps -------------------------------------------------------------------

# Ghostty goes in first: Foot is still the terminal running this script.
step_terminal() {
  say "Ghostty as the default terminal"
  if has ghostty && [[ $(omarchy default terminal) == ghostty ]]; then
    note "already done"
  else
    omarchy install terminal ghostty
  fi
}

step_debloat() {
  say "Removing Omarchy preinstalls and unwanted apps"
  if [[ -f ~/.local/state/omarchy/preinstalls-removed ]]; then
    note "preinstalls already removed"
  else
    omarchy remove preinstalls
  fi
  omarchy pkg drop "${REMOVE_PKGS[@]}"
}

# Move $HOME/$1 aside as .bak.$2, unless it is missing, a link, or already
# resolves into this repo.
backup_unless_ours() {
  local rel=$1 stamp=$2 target="$HOME/$1"
  [[ -e $target && ! -L $target ]] || return 0
  [[ $(realpath "$target") == "$DOTFILES"/* ]] && return 0
  mv "$target" "$target.bak.$stamp"
  note "kept your old $rel as $rel.bak.$stamp"
}

# Link configs into place. Existing files are kept as <file>.bak.<time>.
step_link() {
  say "Linking configs with Stow"
  has stow || omarchy pkg add stow

  local pkg rel stamp
  stamp=$(date +%s)
  for pkg in "${STOW_PACKAGES[@]}"; do
    while IFS= read -r rel; do
      backup_unless_ours "$rel" "$stamp"
    done < <(cd "$DOTFILES/stow/$pkg" && find . -type f -printf '%P\n')
  done
  stow --no-folding -d "$DOTFILES/stow" -t "$HOME" -R "${STOW_PACKAGES[@]}"
  git -C "$DOTFILES" config core.hooksPath .githooks
  has hyprctl && hyprctl reload >/dev/null || true
}

step_chromium() {
  say "Chromium Google account support"
  if grep -qs -- '--oauth2-client-id' ~/.config/chromium-flags.conf; then
    note "already done"
  else
    omarchy install chromium google account
  fi
}

# Chromium views text and Markdown files; nano handles anything that needs an
# editor (git commit messages, Omarchy's "edit config" menu entries).
step_text_files() {
  say "Text files open in Chromium, nano as the editor"
  omarchy pkg add nano
  # `omarchy default editor` doesn't list nano, but omarchy-launch-editor
  # supports it, so write the same setting file that command writes.
  mkdir -p ~/.local/state/omarchy/defaults
  echo nano >~/.local/state/omarchy/defaults/editor
  xdg-mime default chromium.desktop "${TEXT_MIME_TYPES[@]}"
}

# Every video and audio type the system knows about plays in Chromium (mpv is
# removed by the debloat step).
step_media_files() {
  say "Video and audio files play in Chromium"
  local types
  mapfile -t types < <(grep -E '^(video|audio)/' /usr/share/mime/types)
  xdg-mime default chromium.desktop "${types[@]}"
  note "applied (${#types[@]} file types)"
}

# Omarchy's preinstall removal deletes these launchers, so put them back.
step_clis() {
  say "Claude, GitHub and OpenCode CLIs"
  local cli
  for cli in "${CLIS[@]}"; do
    if has "$cli"; then
      note "$cli already installed"
    else
      omarchy-mise-install "$cli"
      note "$cli installed (downloads itself on first run)"
    fi
  done
}

# `omarchy default agent claude` also opens a session, so save its setting
# directly to keep the setup script noninteractive.
step_default_agent() {
  say "Claude Code as the default AI agent"
  has claude || { echo "Claude Code is missing: run ./install.sh clis first." >&2; exit 1; }
  mkdir -p ~/.config/omarchy/defaults
  printf '%s\n' claude >~/.config/omarchy/defaults/agent
  note "applied"
}

# Omarchy's own package repo carries the official Linux build (Anthropic only
# ships it as a .deb). It updates with the rest of the system.
step_claude_desktop() {
  say "Claude desktop app"
  if pacman -Q claude-desktop >/dev/null 2>&1; then
    note "already installed"
  else
    omarchy pkg add claude-desktop
  fi
}

step_shell_plugins() {
  say "Omarchy shell plugins"
  local entry id url
  for entry in "${SHELL_PLUGINS[@]}"; do
    id=${entry%%|*}
    url=${entry#*|}
    if [[ -f "$HOME/.config/omarchy/plugins/$id/manifest.json" ]]; then
      note "$id already installed"
    else
      omarchy plugin add "$url" --enable --yes
    fi
  done
}

# Google first (the browser session is used by every later login), then GitHub.
step_auth() {
  say "Logins"

  note "1/5 Google: sign in to Chromium (profile icon, top right)."
  chromium --new-window https://accounts.google.com/ >/dev/null 2>&1 &
  wait_for_user "Signed in to Google?" || note "skipped Google"

  if gh auth status >/dev/null 2>&1; then
    note "2/5 GitHub: already logged in"
  else
    note "2/5 GitHub"
    gh auth login --hostname github.com --git-protocol https --web
    gh auth setup-git
  fi

  if opencode auth list 2>/dev/null | grep -q 'OpenCode'; then
    note "3/5 OpenCode: already logged in"
  else
    note "3/5 OpenCode: choose OpenCode Go and paste your key from opencode.ai"
    opencode auth login
  fi

  # Claude last: it's the default agent, so a fresh install ends ready to use.
  if claude auth status --json 2>/dev/null | jq -e .loggedIn >/dev/null; then
    note "4/5 Claude Code: already logged in"
  else
    note "4/5 Claude Code"
    claude auth login
  fi

  note "5/5 Claude desktop: sign in in the window that opens (skip if it opens signed in)."
  claude-desktop >/dev/null 2>&1 &
  wait_for_user "Signed in to the Claude app?" || note "skipped Claude desktop"
}

# Last, so there is always a working terminal while the script runs.
step_drop_foot() {
  say "Removing Foot"
  omarchy pkg drop foot
  rm -f ~/.local/share/applications/foot*.desktop
}

# --- main --------------------------------------------------------------------

if [[ ${1:-} == --list ]]; then
  printf '%s\n' "${STEPS[@]}"
  exit 0
fi

has omarchy || { echo "This setup is for Omarchy only."; exit 1; }
[[ $EUID -ne 0 ]] || { echo "Run this as your user, not root."; exit 1; }

selected=("$@")
((${#selected[@]})) || selected=("${STEPS[@]}")

for step in "${selected[@]}"; do
  declare -F "step_$step" >/dev/null || { echo "Unknown step: $step (see --list)"; exit 1; }
  "step_$step"
done

say "Done"
