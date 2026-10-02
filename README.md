# villewow

My dotfiles: my setup on top of a fresh [Omarchy](https://omarchy.org/)
install. It only holds what I change; Omarchy's own defaults stay Omarchy's.

## Install

```bash
git clone https://github.com/villenull/villewow ~/.dotfiles
~/.dotfiles/install.sh
```

The script is safe to re-run, and each step can run on its own:
`./install.sh --list`, then e.g. `./install.sh link auth`.

## What it does

| Step | What |
|------|------|
| `terminal` | Installs Ghostty and makes it the default terminal |
| `debloat` | Omarchy's `remove preinstalls`, plus Evince, Disks, LocalSend, mpv, Neovim, Sushi, printer settings, Tensaku, btop |
| `link` | Links the configs below into place with GNU Stow (old files kept as `.bak.<time>`) |
| `chromium` | Omarchy's Chromium Google-account support |
| `text_files` | `.txt`, `.md` and `.sh` files open in Chromium; nano is the editor for things that need one (git commit messages, Omarchy's edit-config entries) |
| `clis` | Claude Code, GitHub CLI, OpenCode (via Omarchy's mise launchers) |
| `opencode_settings` | OpenCode skips permission prompts (`"permission": "allow"`), and its Build agent runs Space Bunny Free at medium effort, so Orca's OpenCode workers stay at medium even when an orchestrator is switched to max. Tool details are hidden: finished commands and their output don't show (toggle with ctrl+p → Toggle tool details) |
| `codex_settings` | Codex's arrow-key multiple-choice questions outside Plan mode (`default_mode_request_user_input`), and as a picker for the GPT-6 models, whose questions otherwise show as plain text in the terminal (`tools.experimental_request_user_input.enabled`) |
| `paseo` | Latest official Paseo AppImage, desktop launcher and `paseo` command |
| `paseo_settings` | Saved MCP/browser tools, terminal profiles, provider/plugin preferences, relay access and desktop settings |
| `paseo_skills` | Paseo orchestration skills for Claude Code, Codex and OpenCode |
| `orca` | [Orca](https://github.com/stablyai/orca) from the AUR (`stably-orca-bin`), with its `orca-ide` command on PATH |
| `orca_skills` | Orca's `orca-cli` and `orchestration` skills for Claude Code, Codex and OpenCode |
| `orca_settings` | My Orca settings from `orca/settings.json`, including OpenCode workers on Space Bunny Free, written into Orca's own settings database. Orca must be closed; on a fresh install the step opens it once and closes it again to create its profile |
| `shell_plugins` | Omarchy shell plugins: OpenCode Go Watcher, System Monitor, Mimarchy |
| `auth` | Guided logins: Google (Chromium), GitHub, Claude, OpenCode |
| `drop_foot` | Removes Foot, last, so a terminal is always available |

What's left afterwards: Chromium, Files, the image viewer, Ghostty, Paseo and Orca.

## Configs (`stow/`)

- `hypr` — mouse speed
- `omarchy` — hides Learn, Trigger, Style and About from the Omarchy menu
- `vill` — `/vill`, my original Paseo orchestrator brief, restored from
  `vill-paseo-v1`, shared by Claude Code, Codex and OpenCode.
- `villnext` — the matching Paseo version of `/villnext`.

Earlier versions are tagged: `vill-paseo-v1` (Paseo only) and
`vill-paseo-orca` (Paseo and Orca).

## Orca settings (`orca/settings.json`)

Every Orca setting from my machine except secrets, accounts and per-machine
history, merged into Orca's settings by the `orca_settings` step. Orca keeps
them in `profile-state.db`; `orca-data.json` is only an export, and editing it
makes Orca ask which copy to keep, so the step writes the database the way Orca
does (compact JSON, its SHA-256, the next revision).
OpenCode's default arguments are `-m opencode-go/space-bunny-free`, because
Orca can't choose an OpenCode worker's model per task.

## Omarchy shell plugins

Installed from GitHub and enabled by the `shell_plugins` step:

- [OpenCode Go Watcher](https://github.com/villenull/OpenCodeGoWatcher) — OpenCode Go usage and rate limits in the agents panel
- [System Monitor](https://github.com/binoymanoj/sys-monitor-omarchy) — live CPU and RAM in the bar
- [Mimarchy](https://github.com/villenull/Mimarchy) — ARGB lighting for CPU cooler fans, GPU and the cooler display

## Secrets

Nothing personal lives here: no tokens, keys or logins. A
[gitleaks](https://github.com/gitleaks/gitleaks) hook scans every commit and
push (`git config core.hooksPath .githooks`, set by the `link` step).

## License

[MIT](LICENSE)
