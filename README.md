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
| `media_files` | Video and audio files play in Chromium |
| `clis` | Claude Code, GitHub CLI and OpenCode (via Omarchy's mise launchers) |
| `default_agent` | Checks Claude Code is installed and selects it in Omarchy's Setup → Defaults → Agent |
| `claude_settings` | Claude Code settings (`claude/settings.json`): automatic theme, voice input (hold to talk), no warning before bypass-permissions mode. Merged into your file, so anything else in it stays |
| `claude_desktop` | The Claude desktop app (Chat, Cowork and Claude Code), from Omarchy's package repo, and its settings (`claude-desktop/`): Quick Entry shortcut off, menu bar off, keep computer awake, Cowork web search, browser tools in the built-in browser, and scheduled tasks. Merged only while the app is closed |
| `shell_plugins` | Omarchy shell plugins: Activity Monitor, Mimarchy |
| `auth` | Guided logins, Claude last: Google (Chromium), GitHub, OpenCode, Claude Code, the Claude desktop app |
| `drop_foot` | Removes Foot, last, so a terminal is always available |

What's left afterwards: Chromium, Files, the image viewer, Ghostty and Claude.

## Configs (`stow/`)

- `hypr` — mouse speed
- `omarchy` — hides Learn, Trigger, Style and About from the Omarchy menu

## Omarchy shell plugins

Installed from GitHub and enabled by the `shell_plugins` step:

- [Activity Monitor](https://github.com/stappmus/omarchy-activity-monitor) — CPU, memory, GPU, storage and processes in the bar
- [Mimarchy](https://github.com/villenull/Mimarchy) — ARGB lighting for CPU cooler fans, GPU and the cooler display

## Secrets

Nothing personal lives here: no tokens, keys or logins. A
[gitleaks](https://github.com/gitleaks/gitleaks) hook scans every commit and
push (`git config core.hooksPath .githooks`, set by the `link` step).

## License

[MIT](LICENSE)
