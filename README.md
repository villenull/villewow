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
| `paseo` | Latest [Paseo](https://paseo.sh) AppImage, FUSE, launcher entry, `paseo` command |
| `paseo_settings` | Paseo tools and browser tools for agents, remote access via app.paseo.sh, keep daemon running after quit |
| `paseo_skills` | Paseo's orchestration skills for Claude Code, Codex, OpenCode |
| `paseo_plugin` | My sub-usage Paseo plugin (skipped until it's published) |
| `shell_plugins` | Omarchy shell plugins: OpenCode Go Watcher, System Monitor, Mimarchy |
| `auth` | Guided logins: Google (Chromium), GitHub, Claude, OpenCode |
| `drop_foot` | Removes Foot, last, so a terminal is always available |

What's left afterwards: Chromium, Files, the image viewer, Ghostty and Paseo.

## Configs (`stow/`)

- `hypr` — mouse speed
- `omarchy` — hides Learn, Trigger and Style from the Omarchy menu
- `vill` — `/vill`, my Paseo orchestrator brief, as a skill for Claude Code,
  Codex and OpenCode. Only runs when typed; subagents are told to refuse it.

## Omarchy shell plugins

Installed from GitHub and enabled by the `shell_plugins` step:

- [OpenCode Go Watcher](https://github.com/villenull/OpenCodeGoWatcher) — OpenCode Go usage and rate limits in the agents panel
- [System Monitor](https://github.com/binoymanoj/sys-monitor-omarchy) — live CPU and RAM in the bar
- [Mimarchy](https://github.com/villenull/Mimarchy) — ARGB lighting for CPU cooler fans, GPU and the cooler display

## Secrets

Nothing personal lives here: no tokens, keys or logins. A
[gitleaks](https://github.com/gitleaks/gitleaks) hook scans every commit and
push (`git config core.hooksPath .githooks`, set by the `link` step).
