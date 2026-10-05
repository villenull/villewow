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
| `clis` | Claude Code, GitHub CLI, OpenCode (via Omarchy's mise launchers), and Oh My Pi unless you already installed it yourself |
| `default_agent` | Checks Oh My Pi is installed and selects it in Omarchy’s Setup → Defaults → Agent |
| `opencode_settings` | OpenCode skips permission prompts (`"permission": "allow"`), and its Build agent runs Space Bunny Free at medium effort. Tool details are hidden: finished commands and their output don't show (toggle with ctrl+p → Toggle tool details) |
| `paseo` | Latest official Paseo AppImage, desktop launcher and `paseo` command |
| `paseo_skills` | Paseo orchestration skills for Claude Code, Codex and OpenCode |
| `shell_plugins` | Omarchy shell plugins: My Agents, Activity Monitor, Mimarchy |
| `dictation` | Voxtype dictation (`wtype voxtype-bin`, model, systemd user service, and the GPU variant where the hardware supports it): F9 to dictate, Super+Ctrl+X to toggle |
| `auth` | Guided logins, Oh My Pi last: Google (Chromium), GitHub, Claude, OpenCode, Oh My Pi |
| `drop_foot` | Removes Foot, last, so a terminal is always available |

What's left afterwards: Chromium, Files, the image viewer, Ghostty and Paseo.

## Configs (`stow/`)

- `hypr` — mouse speed
- `omarchy` — hides Learn, Trigger, Style and About from the Omarchy menu
- `claude` — a systemd timer that keeps Claude Code's sign-in fresh, so the My
  Agents panel shows live limits instead of "SIGN-IN EXPIRED". It also clears a
  stale `~/.claude/.oauth_refresh.lock`, which is what makes refreshes fail after
  one is interrupted.
- `vill` — `/vill`, my original Paseo orchestrator brief, restored from
  `vill-paseo-v1`, shared by Claude Code, Codex and OpenCode.
- `villnext` — the matching Paseo version of `/villnext`.

The original Paseo setup is tagged `vill-paseo-v1`.

## Omarchy shell plugins

Installed from GitHub and enabled by the `shell_plugins` step:

- [My Agents](https://github.com/villenull/OpenCodeGoWatcher) — customized AI usage panel with the OpenCode Go collector and icons bundled
- [Activity Monitor](https://github.com/stappmus/omarchy-activity-monitor) — CPU, memory, GPU, storage and processes in the bar
- [Mimarchy](https://github.com/villenull/Mimarchy) — ARGB lighting for CPU cooler fans, GPU and the cooler display

## Secrets

Nothing personal lives here: no tokens, keys or logins. A
[gitleaks](https://github.com/gitleaks/gitleaks) hook scans every commit and
push (`git config core.hooksPath .githooks`, set by the `link` step).

## License

[MIT](LICENSE)
