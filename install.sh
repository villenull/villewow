#!/usr/bin/env bash
# Villenull's Omarchy setup. Safe to re-run: every step checks before acting.
#
#   ./install.sh            run every step, in order
#   ./install.sh link auth  run only the named steps
#   ./install.sh --list     show the steps

set -Eeuo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STEPS=(terminal debloat link chromium text_files clis opencode_settings codex_settings orca orca_skills orca_settings shell_plugins auth drop_foot)

# Linked file by file. Skill folders are linked whole (see step_link).
STOW_PACKAGES=(hypr omarchy)
STOW_SKILLS=(vill villnext)

REMOVE_PKGS=(
  evince gnome-disk-utility localsend mpv mpv-mpris nvim omarchy-nvim
  sushi system-config-printer tensaku btop
)

CLIS=(claude gh opencode)

TEXT_MIME_TYPES=(text/plain text/markdown text/x-markdown text/x-shellscript application/x-shellscript)

ORCA_PACKAGE=stably-orca-bin
ORCA_SKILLS=(orca-cli orchestration)

# id|git url
SHELL_PLUGINS=(
  "io.github.villenull.opencode-go-watcher|https://github.com/villenull/OpenCodeGoWatcher"
  "sys-monitor|https://github.com/binoymanoj/sys-monitor-omarchy.git"
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

# OpenCode approves every permission request (same as always passing --auto),
# and its Build agent runs Space Bunny at medium effort: an agent's variant
# beats the one saved when you pick max in an orchestrator, so workers stay at
# medium while that orchestrator session runs at max.
# This also covers the OpenCode workers Orca launches.
# Tool details are hidden too (finished commands and their output don't show),
# which is a saved UI toggle in OpenCode's state file, not its config.
step_opencode_settings() {
  say "OpenCode: skip permission prompts, workers at medium effort, tool details hidden"
  merge_json ~/.config/opencode/opencode.json "$DOTFILES/opencode/opencode.json"
  merge_json ~/.local/state/opencode/kv.json "$DOTFILES/opencode/kv.json"
  note "applied"
}

# Codex's arrow-key question tool outside Plan mode, so orchestrators on Codex
# ask multiple-choice questions like Claude and OpenCode do. Codex also writes
# this file, so only this one key is touched.
step_codex_settings() {
  say "Codex: multiple-choice questions in every mode"
  python3 - "$HOME/.codex/config.toml" <<'PY'
import pathlib, re, sys, tomllib
path = pathlib.Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
text = path.read_text() if path.exists() else ""
key = "default_mode_request_user_input"
if tomllib.loads(text).get("features", {}).get(key) is True:
    print("    already on")
    raise SystemExit
header = re.search(r"^\[features\][ \t]*$", text, re.M)
if header:
    line = re.compile(rf"^{key}\s*=.*$", re.M)
    text = (line.sub(f"{key} = true", text) if line.search(text)
            else text[:header.end()] + f"\n{key} = true" + text[header.end():])
else:
    text = text.rstrip("\n") + ("\n\n" if text.strip() else "") + f"[features]\n{key} = true\n"
tomllib.loads(text)
path.write_text(text)
print("    turned on")
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

# Orca, from the AUR, with its `orca-ide` command on PATH. On Linux the CLI is
# orca-ide outside Orca's own terminals: bare `orca` is the GNOME screen reader.
step_orca() {
  say "Orca"
  omarchy pkg aur add "$ORCA_PACKAGE"
  mkdir -p ~/.local/bin
  ln -sfn /opt/stably-orca/resources/bin/orca-ide ~/.local/bin/orca-ide
  note "installed; open it once before the orca_settings step"
}

# Orca's orchestration and CLI skills, which /vill tells orchestrators to load.
step_orca_skills() {
  say "Orca skills"
  local args=() skill
  for skill in "${ORCA_SKILLS[@]}"; do args+=(--skill "$skill"); done
  orca-ide skills install "${args[@]}" --agent claude-code,codex,opencode --json >/dev/null
  note "installed ${ORCA_SKILLS[*]}"
}

# Orca re-executes itself on start, so the pid we launch is gone at once and
# Orca is closed by name instead. That only happens in orca_first_run, which
# runs only when no Orca was open, so the one it closes is the one it opened.
ORCA_BIN=/opt/stably-orca/orca-ide

# By process name, not command line: a command line that merely mentions
# Orca's path (a shell running this script, say) must not count.
orca_running() { pgrep -x orca-ide >/dev/null; }

# Orca keeps its state in profile-state.db, one JSON document per domain with
# a SHA-256 of its payload and a revision counter. orca-data.json is only an
# export: editing it makes the two copies disagree, and Orca then asks which
# to keep. So settings are written into the database, the way Orca writes them.
orca_settings_ready() {
  python3 - "$1" <<'PY'
import sqlite3, sys
try:
  db = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
  ok = db.execute("select 1 from profile_state_documents where domain = 'settings'").fetchone()
except sqlite3.Error:
  ok = None
sys.exit(0 if ok else 1)
PY
}

# Open Orca once so it creates its profile, then close it again. Gives up
# after two minutes (closing Orca anyway) if the settings never appear.
orca_first_run() {
  local db=$1 pid i
  setsid "$ORCA_BIN" >/dev/null 2>&1 </dev/null &
  pid=$!
  for ((i = 0; i < 120; i++)); do
    orca_settings_ready "$db" && break
    sleep 1
  done
  # A moment for Orca to finish starting before it is asked to quit.
  sleep 5
  pkill -TERM -x orca-ide || true
  for ((i = 0; i < 30; i++)); do
    orca_running || break
    sleep 1
  done
  orca_settings_ready "$db"
}

# My Orca settings, merged into Orca's own settings (secrets are never stored
# here). Orca must be closed: it holds the database while it runs. On a fresh
# install there is no profile yet, so Orca is opened once and closed again.
step_orca_settings() {
  say "Orca settings"
  local profile=${XDG_CONFIG_HOME:-$HOME/.config}/orca/profiles/local-default
  local db=$profile/profile-state.db
  if orca_running; then
    note "skipped: quit Orca first, then run: ./install.sh orca_settings"
    return
  fi
  if ! orca_settings_ready "$db"; then
    note "opening Orca once so it creates its settings, then closing it"
    if ! orca_first_run "$db"; then
      note "skipped: Orca didn't create its settings. Open it, finish its"
      note "welcome screen, quit it, then run: ./install.sh orca_settings"
      return
    fi
  fi
  local stamp f
  stamp=$(date +%s)
  for f in "$db" "$db-wal" "$db-shm"; do
    [[ -f $f ]] && cp "$f" "${f/profile-state.db/profile-state.db.dotfiles-bak.$stamp}"
  done
  python3 - "$db" "$DOTFILES/orca/settings.json" "$HOME" <<'PY'
import hashlib, json, sqlite3, sys, time
db_path, ours_path, home = sys.argv[1:]

def merge(base, ours):
  """jq's `*`: objects merge key by key, anything else is replaced."""
  if isinstance(base, dict) and isinstance(ours, dict):
    return {**base, **{key: merge(base.get(key), value) for key, value in ours.items()}}
  return ours

ours = json.load(open(ours_path))
if isinstance(ours.get("workspaceDir"), str) and ours["workspaceDir"].startswith("~"):
  ours["workspaceDir"] = home + ours["workspaceDir"][1:]

db = sqlite3.connect(db_path)
with db:
  payload, = db.execute("select payload from profile_state_documents where domain = 'settings'").fetchone()
  merged = json.dumps(merge(json.loads(payload), ours), separators=(",", ":"), ensure_ascii=False)
  if merged == payload:
    print("    already applied")
    sys.exit(0)
  revision = int(db.execute("select value from profile_state_meta where key = 'revision'").fetchone()[0]) + 1
  db.execute("update profile_state_documents set payload = ?, content_hash = ?, revision = ?, updated_at = ?"
             " where domain = 'settings'",
             (merged, hashlib.sha256(merged.encode()).hexdigest(), revision, int(time.time() * 1000)))
  db.execute("update profile_state_meta set value = ? where key = 'revision'", (str(revision),))
print("    applied (previous database kept as profile-state.db.dotfiles-bak.*)")
PY
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
