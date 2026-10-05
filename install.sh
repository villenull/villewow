#!/usr/bin/env bash
# Villenull's Omarchy setup. Safe to re-run: every step checks before acting.
#
#   ./install.sh            run every step, in order
#   ./install.sh link auth  run only the named steps
#   ./install.sh --list     show the steps

set -Eeuo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STEPS=(terminal debloat link chromium text_files clis omp default_agent opencode_settings paseo paseo_settings paseo_skills shell_plugins auth drop_foot)

# Linked file by file. Skill folders are linked whole (see step_link).
STOW_PACKAGES=(hypr omarchy)
STOW_SKILLS=(vill villnext)

REMOVE_PKGS=(
  evince gnome-disk-utility localsend mpv mpv-mpris nvim omarchy-nvim
  sushi system-config-printer tensaku btop
)

CLIS=(claude gh opencode)

TEXT_MIME_TYPES=(text/plain text/markdown text/x-markdown text/x-shellscript application/x-shellscript)

PASEO_APPIMAGE="$HOME/.local/opt/Paseo-x86_64.AppImage"
PASEO_SKILLS=(paseo paseo-advisor paseo-committee paseo-handoff paseo-help paseo-plugin)

# id|git url
SHELL_PLUGINS=(
  "io.github.villenull.opencode-go-watcher|https://github.com/villenull/OpenCodeGoWatcher"
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
  for pkg in "${STOW_SKILLS[@]}"; do
    backup_unless_ours ".agents/skills/$pkg" "$stamp"
  done
  # Link files one by one, except skill folders: OpenCode ignores symlinked
  # SKILL.md files, so that one folder is linked whole.
  mkdir -p ~/.agents/skills
  stow --no-folding -d "$DOTFILES/stow" -t "$HOME" -R "${STOW_PACKAGES[@]}"
  stow -d "$DOTFILES/stow" -t "$HOME" -R "${STOW_SKILLS[@]}"

  # Claude Code and Codex read skills from their own folders.
  local dir skill
  for dir in ~/.claude/skills ~/.codex/skills; do
    mkdir -p "$dir"
    for skill in "${STOW_SKILLS[@]}"; do
      ln -sfn ~/.agents/skills/"$skill" "$dir/$skill"
    done
  done

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

# Omarchy's preinstall removal deletes these launchers, so put them back.
step_clis() {
  say "Claude, GitHub, OpenCode and Oh My Pi CLIs"
  local cli
  for cli in "${CLIS[@]}"; do
    if has "$cli"; then
      note "$cli already installed"
    else
      omarchy-mise-install "$cli"
      note "$cli installed (downloads itself on first run)"
    fi
  done
  ensure_omp
}

# Oh My Pi is the default agent. A binary in ~/.local/bin that isn't one of
# mise's own wrappers counts as your install (Omarchy treats it the same way);
# otherwise mise installs it from the same source Omarchy uses. Not part of
# CLIS, whose launchers would overwrite a binary you installed yourself.
ensure_omp() {
  if [[ -x $HOME/.local/bin/omp ]] && ! grep -q '^mise use -g' "$HOME/.local/bin/omp"; then
    note "omp already installed (~/.local/bin/omp)"
  elif mise where github:can1357/oh-my-pi >/dev/null 2>&1; then
    note "omp already installed (mise)"
  else
    mise use -g github:can1357/oh-my-pi
    note "omp installed (downloads itself on first run)"
  fi
}

# Runs on its own too, so it stays a step as well as part of `clis`.
step_omp() {
  say "Oh My Pi"
  ensure_omp
}

# Install the agent now, rather than relying on the first-run launcher.
# `omarchy default agent omp` also opens a session, so save its setting
# directly to keep the setup script noninteractive. Omarchy launches it with
# --auto-approve, so unattended launches never stop for a tool approval.
step_default_agent() {
  say "Oh My Pi as the default AI agent"
  has omp || { echo "Oh My Pi is missing: run ./install.sh omp first." >&2; exit 1; }
  mkdir -p ~/.config/omarchy/defaults
  printf '%s\n' omp >~/.config/omarchy/defaults/agent
  note "applied"
}

# OpenCode approves every permission request (same as always passing --auto),
# and its Build agent runs Space Bunny at medium effort: an agent's variant
# beats the one saved when you pick max in an orchestrator, so workers stay at
# medium while that orchestrator session runs at max.
# Tool details are hidden too (finished commands and their output don't show),
# which is a saved UI toggle in OpenCode's state file, not its config.
step_opencode_settings() {
  say "OpenCode: skip permission prompts, workers at medium effort, tool details hidden"
  merge_json ~/.config/opencode/opencode.json "$DOTFILES/opencode/opencode.json"
  merge_json ~/.local/state/opencode/kv.json "$DOTFILES/opencode/kv.json"
  note "applied"
}

# Merge our settings into a JSON settings file, keeping everything else in it.
# A missing file starts as $3 (default: {}).
merge_json() {
  local target=$1 ours=$2 initial=${3:-'{}'}
  mkdir -p "$(dirname "$target")"
  [[ -s $target ]] || echo "$initial" >"$target"
  jq -s '.[0] * .[1]' "$target" "$ours" >"$target.tmp"
  mv "$target.tmp" "$target"
}

step_paseo() {
  say "Paseo (latest AppImage)"
  omarchy pkg add fuse2

  local release tag url
  release=$(curl -fsSL https://api.github.com/repos/getpaseo/paseo/releases/latest)
  tag=$(jq -r .tag_name <<<"$release")
  url=$(jq -r '.assets[] | select(.name | endswith("x86_64.AppImage")) | .browser_download_url' <<<"$release")

  if [[ -x $PASEO_APPIMAGE && $(cat "$PASEO_APPIMAGE.version" 2>/dev/null) == "$tag" ]]; then
    note "Paseo $tag already installed"
  else
    mkdir -p "$(dirname "$PASEO_APPIMAGE")"
    curl -fL --progress-bar -o "$PASEO_APPIMAGE.part" "$url"
    chmod +x "$PASEO_APPIMAGE.part"
    mv "$PASEO_APPIMAGE.part" "$PASEO_APPIMAGE"
    echo "$tag" >"$PASEO_APPIMAGE.version"
    note "installed Paseo $tag"
  fi

  mkdir -p ~/.local/bin
  ln -sfn "$PASEO_APPIMAGE" ~/.local/bin/paseo

  local icon=~/.local/share/icons/hicolor/128x128/apps/Paseo.png tmp
  if [[ ! -f $icon ]]; then
    tmp=$(mktemp -d)
    (cd "$tmp" && "$PASEO_APPIMAGE" --appimage-extract Paseo.png >/dev/null)
    install -Dm644 "$tmp/squashfs-root/Paseo.png" "$icon"
    rm -rf "$tmp"
  fi

  mkdir -p ~/.local/share/applications
  cat >~/.local/share/applications/Paseo.desktop <<EOF
[Desktop Entry]
Name=Paseo
Exec=$PASEO_APPIMAGE --class=Paseo %U
Terminal=false
Type=Application
Icon=Paseo
StartupWMClass=Paseo
Comment=Paseo desktop app
MimeType=x-scheme-handler/paseo;
Categories=Development;
EOF
}

step_paseo_settings() {
  say "Paseo settings"
  merge_json ~/.paseo/config.json "$DOTFILES/paseo/config.json" '{"version": 1}'
  merge_json ~/.config/Paseo/desktop-settings.json "$DOTFILES/paseo/desktop-settings.json" '{"version": 1}'
  chmod 600 ~/.paseo/config.json
  if paseo daemon status >/dev/null 2>&1; then
    paseo reload >/dev/null
  else
    paseo start >/dev/null
  fi
  note "applied"
}

step_paseo_skills() {
  say "Paseo orchestration skills"
  local args=() skill
  for skill in "${PASEO_SKILLS[@]}"; do args+=(-s "$skill"); done
  mise x node@lts -- npx --yes skills add getpaseo/paseo -g -y \
    -a claude-code -a codex -a opencode "${args[@]}"
}

step_shell_plugins() {
  say "Omarchy shell plugins"
  local entry id url restart_shell=false
  for entry in "${SHELL_PLUGINS[@]}"; do
    id=${entry%%|*}
    url=${entry#*|}
    if [[ -f "$HOME/.config/omarchy/plugins/$id/manifest.json" ]]; then
      note "$id already installed"
      if [[ $id == io.github.villenull.opencode-go-watcher ]] &&
          [[ ! -x "$HOME/.config/omarchy/plugins/$id/bin/my-agents-migrate" ]]; then
        omarchy plugin update "$id"
        restart_shell=true
      fi
    else
      omarchy plugin add "$url" --enable --yes
    fi
    if [[ $id == io.github.villenull.opencode-go-watcher ]]; then
      "$HOME/.config/omarchy/plugins/$id/bin/my-agents-migrate"
      omarchy-shell shell rescanPlugins >/dev/null
    fi
  done
  if [[ $restart_shell == true ]]; then
    omarchy restart shell
  fi
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

  if claude auth status --json 2>/dev/null | jq -e .loggedIn >/dev/null; then
    note "3/5 Claude: already logged in"
  else
    note "3/5 Claude"
    claude auth login
  fi

  if opencode auth list 2>/dev/null | grep -q 'OpenCode'; then
    note "4/5 OpenCode: already logged in"
  else
    note "4/5 OpenCode: choose OpenCode Go and paste your key from opencode.ai"
    opencode auth login
  fi

  # Last login: the default agent, so a fresh install ends ready to use.
  if omp usage --json 2>/dev/null | jq -e '.reports | length > 0' >/dev/null; then
    note "5/5 Oh My Pi: already logged in"
  else
    note "5/5 Oh My Pi: sign in to the providers you want (Anthropic, OpenAI Codex, OpenCode Go)"
    omp login
  fi
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
