# Portable dotfiles

> Al dente configs. Firm, never mushy.

This repository manages shell, editor, terminal, Git, tmux, Pi, and selected
desktop configuration with [chezmoi](https://www.chezmoi.io/). It supports:

- Native Linux workstations, including Hyprland
- macOS workstations, including AeroSpace and SketchyBar
- Linux, macOS, and WSL2 shell-only systems
- Homebrew, Pacman, and APT package discovery and optional installation

Package installation, automatic tmux attachment, and desktop configuration are
profile-controlled. Package installation is disabled by default.

## Safety model

Repository work and live-home work are separate operations.

| Operation | Writes to `$HOME` | Other effects |
| --- | ---: | --- |
| Edit files in this repository | No | Changes source only |
| `./tests/validate-repository.sh` | No | Uses temporary directories |
| `chezmoi init` | Yes | Creates chezmoi config/state; does not apply unless requested |
| `chezmoi diff` | No managed-file writes | Reads live files and renders templates |
| `chezmoi apply --dry-run --verbose` | No managed-file writes | Shows planned operations |
| `chezmoi apply` | **Yes** | Replaces managed live files and may run enabled scripts |
| `chezmoi re-add` | No live-target writes | Imports live content into source state |

This repository does not apply itself. Editing, validating, committing, or
pushing source does not update the active home directory.

Before the first apply on an existing machine:

1. Back up every target that chezmoi will manage.
2. Keep `installPackages=false`.
3. Run validation.
4. Review `chezmoi diff` one file at a time.
5. Apply one target at a time before considering a full apply.

Do not use `chezmoi apply`, `chezmoi re-add`, or a compositor reload as a test.
Use the isolated validation script instead.

## Repository layout

`.chezmoiroot` contains `home`, so only `home/` is chezmoi source state.
Project documentation, tests, hooks, and Git metadata cannot be installed into
`$HOME` accidentally.

```text
.
├── .chezmoiroot                 # tells chezmoi to use home/
├── home/
│   ├── .chezmoi.toml.tmpl       # once-only profile questions
│   ├── .chezmoiignore           # platform/profile path selection
│   ├── dot_config/              # installs below ~/.config/
│   ├── dot_pi/                  # installs below ~/.pi/
│   ├── dot_gitconfig.tmpl       # installs as ~/.gitconfig
│   ├── dot_tmux.conf            # installs as ~/.tmux.conf
│   ├── dot_zshenv               # installs as ~/.zshenv
│   └── run_onchange_*           # opt-in package adapter
├── .pi/agent -> ../home/dot_pi/private_agent
├── docs/
├── hooks/
└── tests/
```

Chezmoi source names encode target attributes:

- `dot_foo` becomes `.foo`.
- `private_foo` removes group and world permissions.
- `executable_foo` installs with executable mode.
- `symlink_foo` creates a symlink.
- `foo.tmpl` is rendered as a template.
- `remove_foo` removes an obsolete target during apply.

The Pi agent source uses `private_agent`, so `~/.pi/agent` is mode `0700`.
Its `modify_settings.json` applies the baseline in `.chezmoitemplates/pi-settings.json`
while preserving Pi's runtime-managed top-level `lastChangelogVersion` when it
already exists. The settings target remains a non-executable JSON file.

Use `chezmoi source-path TARGET` when the encoded source path is unclear.

## Machine profiles

A clean initialization asks four questions once:

| Setting | Values | Default guidance |
| --- | --- | --- |
| `role` | `workstation`, `shell` | Use `shell` on servers and WSL2 |
| `desktop` | `auto`, `hyprland`, `aerospace`, `none` | Use `auto` on a workstation |
| `installPackages` | `true`, `false` | Keep `false` until reviewed |
| `autoTmux` | `true`, `false` | Keep `false` until reviewed |

Profile behavior:

| Platform/profile | Shell and CLI | Hyprland | AeroSpace/SketchyBar |
| --- | :---: | :---: | :---: |
| Native Linux workstation + `auto`/`hyprland` | Yes | Yes | No |
| macOS workstation + `auto`/`aerospace` | Yes | No | Yes |
| `shell` role | Yes | No | No |
| WSL2 | Yes | No | No |
| Desktop `none` | Yes | No | No |

The macOS AeroSpace profile manages AeroSpace at
`~/.config/aerospace/aerospace.toml` and the SketchyBar files under
`~/.config/sketchybar`. SketchyBar is currently inactive and optional: the
imported AeroSpace config does not start it or send workspace-change triggers.

WSL2 detection uses the kernel release. WSL2 is always treated as shell/CLI
only, even when workstation options are selected.

## Validate without touching the live home

Requirements for the full validation suite include `bash`, `zsh`, `chezmoi`,
`jq`, `python3`, and `node`.

```sh
./tests/validate-repository.sh
```

The suite creates temporary config, cache, state, source-render, and destination
paths. It initializes and applies host-native workstation/`auto` and shell/`none`
profiles only in those paths. Darwin runs natively on macOS and Linux runs
natively on Linux; WSL and cross-host simulation remain residual gaps. It also
checks:

- Template selection and repeatable second applies
- Shell, JSON, TOML, and JavaScript syntax
- Source modes and symlinks
- Removal of obsolete Neovim files
- Basic secret-pattern exclusions
- Hyprland login guards
- Non-ZLE zsh startup, including the fzf integration
- `git diff --check`

It does not apply to the real `$HOME`, install packages, reload programs, stage
files, commit, or push.

## New-machine bootstrap

Install chezmoi through a method you trust. Clone or reference this repository,
then initialize it without applying:

```sh
chezmoi --source /path/to/dot_files init
chezmoi --source /path/to/dot_files diff
chezmoi --source /path/to/dot_files apply --dry-run --verbose
```

Review the rendered diff. When it is correct, apply individual targets first:

```sh
chezmoi --source /path/to/dot_files apply ~/.zshenv
chezmoi --source /path/to/dot_files apply ~/.config/zsh
```

A full apply is a separate, explicit decision:

```sh
chezmoi --source /path/to/dot_files apply
```

After a standard remote initialization into chezmoi's default source directory,
bare commands can be used:

```sh
chezmoi init --ssh jtabke/dot_files
chezmoi diff
chezmoi apply --dry-run --verbose
```

Do not append `--apply` to `chezmoi init` until the complete diff is approved.

## Existing-machine adoption

Treat an existing machine as a migration, not as a new installation.

### Source-first change

Edit the encoded source file in this repository, validate it, and inspect the
live difference:

```sh
$EDITOR home/dot_config/zsh/30-platform.zsh
./tests/validate-repository.sh
chezmoi --source /path/to/dot_files diff ~/.config/zsh/30-platform.zsh
```

Only apply after review:

```sh
chezmoi --source /path/to/dot_files apply ~/.config/zsh/30-platform.zsh
```

### Live-first change

For a non-templated target that was intentionally changed live, import only
that file:

```sh
chezmoi --source /path/to/dot_files re-add ~/.tmux.conf
chezmoi --source /path/to/dot_files diff ~/.tmux.conf
```

Never re-add an entire home directory. Do not blindly re-add rendered template
files because the live file no longer contains template logic. Edit the source
template or use `chezmoi merge` and review every change.

## Shell and tmux behavior

Zsh uses `~/.config/zsh` through `ZDOTDIR`. The interactive loader sources
numbered fragments in order:

```text
10-portable.zsh  -> portable key bindings and shell behavior
30-platform.zsh  -> completion, tools, aliases, and platform integrations
90-tmux.zsh      -> optional local and SSH tmux attachment
```

fzf bindings load only when Zsh Line Editor (ZLE) is active in a real terminal.
This avoids `can't change option: zle` warnings from non-terminal health checks
such as `zsh -lic`.

Automatic tmux attachment requires `autoTmux=true` and excludes existing tmux
sessions, continuous integration, and non-terminal shells. It applies to local
and SSH interactive sessions. Leaving tmux returns to the outer shell.

## Hyprland safeguards

Hyprland is managed only for a native Linux workstation profile. The login
profile can start the compositor only when all of these conditions are true:

- Input and output are terminals.
- The terminal is exactly `/dev/tty1`.
- `XDG_VTNR=1`.
- No Wayland or X11 display already exists.
- The shell is not inside tmux or SSH.

This prevents a login shell in a tmux pane from starting another compositor.

Portable settings live in `home/dot_config/hypr/hyprland.lua`. Optional
host-specific settings load from the unmanaged file:

```text
~/.config/hypr/hyprland.local.lua
```

Keep monitor layouts, device identifiers, and other hardware-specific values
there. Start from `docs/hyprland-local.example.lua`.

If Hyprland shows an autogenerated-config warning, first inspect the active
provider without reloading or restarting:

```sh
hyprctl systeminfo | grep configProvider
```

An unexpected `~/.config/hypr/hyprland.conf` can select the Hyprlang provider.
Moving that file does not affect open windows, but changing from Hyprlang to the
Lua provider requires a compositor restart and will end the graphical session.
Save all work before restarting.

## Git identity and secrets

The managed Git configuration includes this unmanaged file:

```text
~/.config/git/user.inc
```

Store personal identity there:

```ini
[user]
    name = Your Name
    email = you@example.com
```

Do not commit credentials, access tokens, private keys, machine-specific secret
files, or rendered secret-manager output. This repository does not manage
`~/.git-credentials`.

## Optional package installation

`home/run_onchange_install-packages.sh.tmpl` checks for missing commands and can
install Git, Neovim, zsh, tmux, ripgrep, and fzf through:

- Homebrew from `PATH`, `/opt/homebrew/bin`, or `/usr/local/bin`
- Pacman, with root and sudo handling
- APT

The script is disabled when `installPackages=false`. Repository validation does
not execute it. Review its rendered output before enabling package changes.

## Git workflow

Enable the repository hook if desired:

```sh
git -C /path/to/dot_files config core.hooksPath hooks
```

A cautious source-only workflow is:

```sh
git status --short
git diff --check
./tests/validate-repository.sh
git diff
```

Committing and pushing source still do not update the active home directory.
Applying to `$HOME` remains a separate manual operation.

More migration detail is available in `docs/chezmoi-migration.md`.
