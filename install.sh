#!/usr/bin/env bash
# Villenull's Omarchy setup. Safe to re-run: every step checks before acting.
#
#   ./install.sh            run every step, in order
#   ./install.sh link auth  run only the named steps
#   ./install.sh --list     show the steps

set -Eeuo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STEPS=(terminal debloat link chromium text_files clis default_agent opencode_settings codex_settings paseo paseo_settings paseo_skills shell_plugins auth drop_foot)

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

# Install the agent now, rather than relying on the first-run launcher.
# `omarchy default agent opencode` also opens a session, so save its setting
# directly to keep the setup script noninteractive.
step_default_agent() {
  say "OpenCode as the default AI agent"
  if ! mise where opencode >/dev/null 2>&1; then
    mise use -g opencode
  fi
  mkdir -p ~/.config/omarchy/defaults
  printf '%s\n' opencode >~/.config/omarchy/defaults/agent
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

# Codex's arrow-key question tool outside Plan mode, so orchestrators on Codex
# ask multiple-choice questions like Claude and OpenCode do. The GPT-6 models
# ask through a non-blocking variant that the terminal app shows as plain text
# unless tools.experimental_request_user_input is on. Codex also writes this
# file, so only these keys are touched.
step_codex_settings() {
  say "Codex: multiple-choice questions in every mode"
  python3 - "$HOME/.codex/config.toml" <<'PY'
import pathlib, re, sys, tomllib
path = pathlib.Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
text = path.read_text() if path.exists() else ""
changed = False
for table, key in [("features", "default_mode_request_user_input"),
                   ("tools.experimental_request_user_input", "enabled")]:
    current = tomllib.loads(text)
    for part in table.split("."):
        current = current.get(part, {})
    if current.get(key) is True:
        continue
    header = re.search(rf"^\[{re.escape(table)}\][ \t]*$", text, re.M)
    if header:
        body_end = re.compile(r"^\[", re.M).search(text, header.end())
        body_end = body_end.start() if body_end else len(text)
        line = re.compile(rf"^{key}\s*=.*$", re.M)
        found = line.search(text, header.end(), body_end)
        text = (text[:found.start()] + f"{key} = true" + text[found.end():] if found
                else text[:header.end()] + f"\n{key} = true" + text[header.end():])
    else:
        text = text.rstrip("\n") + ("\n\n" if text.strip() else "") + f"[{table}]\n{key} = true\n"
    changed = True
tomllib.loads(text)
if changed:
    path.write_text(text)
print("    turned on" if changed else "    already on")
PY
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
  local entry id url
  for entry in "${SHELL_PLUGINS[@]}"; do
    id=${entry%%|*}
    url=${entry#*|}
    if omarchy plugin list 2>/dev/null | grep -q "^$id "; then
      note "$id already installed"
    else
      omarchy plugin add "$url" --enable --yes
    fi
  done
}

# Google first (the browser session is used by every later login), then GitHub.
step_auth() {
  say "Logins"

  note "1/4 Google: sign in to Chromium (profile icon, top right)."
  chromium --new-window https://accounts.google.com/ >/dev/null 2>&1 &
  wait_for_user "Signed in to Google?" || note "skipped Google"

  if gh auth status >/dev/null 2>&1; then
    note "2/4 GitHub: already logged in"
  else
    note "2/4 GitHub"
    gh auth login --hostname github.com --git-protocol https --web
    gh auth setup-git
  fi

  if claude auth status --json 2>/dev/null | jq -e .loggedIn >/dev/null; then
    note "3/4 Claude: already logged in"
  else
    note "3/4 Claude"
    claude auth login
  fi

  if opencode auth list 2>/dev/null | grep -q 'OpenCode'; then
    note "4/4 OpenCode: already logged in"
  else
    note "4/4 OpenCode: choose OpenCode Go and paste your key from opencode.ai"
    opencode auth login
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
