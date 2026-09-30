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
| `opencode_settings` | OpenCode skips permission prompts (`"permission": "allow"`), including the OpenCode workers Orca launches |
| `codex_settings` | Codex's arrow-key multiple-choice questions outside Plan mode (`default_mode_request_user_input`) |
| `orca` | [Orca](https://github.com/stablyai/orca) from the AUR (`stably-orca-bin`), with its `orca-ide` command on PATH |
| `orca_skills` | Orca's `orca-cli` and `orchestration` skills for Claude Code, Codex and OpenCode |
| `orca_settings` | My Orca settings from `orca/settings.json`, including OpenCode workers on Space Bunny Free. Orca must have been opened once and be closed |
| `shell_plugins` | Omarchy shell plugins: OpenCode Go Watcher, System Monitor, Mimarchy |
| `auth` | Guided logins: Google (Chromium), GitHub, Claude, OpenCode |
| `drop_foot` | Removes Foot, last, so a terminal is always available |

What's left afterwards: Chromium, Files, the image viewer, Ghostty and Orca.

## Configs (`stow/`)

- `hypr` — mouse speed
- `omarchy` — hides Learn, Trigger, Style and About from the Omarchy menu
- `vill` — `/vill`, my orchestrator brief for [Orca](https://github.com/stablyai/orca),
  as a skill for Claude Code, Codex and OpenCode. The rules are in `SKILL.md`,
  Orca's mechanics in `orca.md`. Only runs when typed; workers are told to
  refuse it.
- `villnext` — `/villnext`, run right after `/vill`: the orchestrator proposes
  what to work on next, favoring parallel work for free workers, and waits for
  my go-ahead.

Earlier versions are tagged: `vill-paseo-v1` (Paseo only) and
`vill-paseo-orca` (Paseo and Orca).

## Orca settings (`orca/settings.json`)

Every Orca setting from my machine except secrets, accounts and per-machine
history, merged into Orca's own settings file by the `orca_settings` step.
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
