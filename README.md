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
| `./setup` | **Yes** | Saves init choices first; separate approvals for configs and packages |
| `./scripts/setup.sh --plan` | No managed-file writes | Read-only profile/package/readiness report after init |
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
├── setup                        # guided, interactive machine setup
├── scripts/setup.sh             # advanced plan/check/install helper
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
while preserving Pi's runtime-managed top-level `lastChangelogVersion` and
machine-local `deviceId` when they already exist. The settings target remains a non-executable JSON file.

Use `chezmoi source-path TARGET` when the encoded source path is unclear.

## Machine profiles

Initialization detects the platform and asks only relevant questions once.
WSL automatically selects `shell` / `none`; other shell profiles skip the desktop
question. Workstations see only desktops supported on their OS:

| Setting | Values | Default guidance |
| --- | --- | --- |
| `role` | `workstation`, `shell` | WSL is always `shell`; use `shell` on servers |
| `desktop` | Linux: `auto`, `hyprland`, `none`; macOS: `auto`, `aerospace`, `none` | Shell/WSL implies `none` |
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

On WSL2, only choose whether to install missing CLI packages and whether to
auto-attach tmux. Enabling installation never enables desktop packages. Fuzzel
is selected only for native Linux Hyprland workstations.

Desktop profiles **configure an existing desktop; they do not install one**.
The readiness check reports missing desktop programs. Install Hyprland/AeroSpace,
fonts, drivers and desktop dependencies separately. SketchyBar remains optional.

## Validate without touching the live home

Requirements for the full validation suite include `bash`, `zsh`, `chezmoi`,
`jq`, `python3`, and `node`.

```sh
./tests/validate-repository.sh
```

The suite creates temporary config, cache, state, source-render, and destination
paths. It initializes and applies host-native workstation/`auto` and shell/`none`
profiles only in those paths. Darwin runs natively on macOS and Linux runs
natively on Linux. Additional tests simulate WSL and cross-host prompts/package
selection, and execute adapters with mocked commands in temporary homes. Real
WSL desktop behavior and real distro package installations are not exercised.
It also checks:

- Template selection and repeatable second applies
- Shell, JSON, TOML, and JavaScript syntax
- Source modes and symlinks
- Removal of obsolete Neovim files
- Basic secret-pattern exclusions
- Hyprland login guards
- Fresh-home non-ZLE zsh startup, including the fzf integration
- Guided setup in disposable homes: config/package approvals, cancellation and failures
- Approval/disabled-install safety, APT/Pacman/Brew arguments and adapter failures
- Minimum-version readiness checks (old commands are not treated as ready)
- `git diff --check`

It does not apply to the real `$HOME`, install packages, reload programs, stage
files, commit, or push.

## New-machine bootstrap

### Recommended: guided setup

Install **Git, Bash, and chezmoi** using methods you trust. Then clone over HTTPS
(no GitHub SSH credentials required) and run the guided entry point:

```sh
git clone https://github.com/jtabke/dot_files.git
cd dot_files
./setup
```

Already have the checkout? Just run `./setup` from its root. It works regardless
of where the checkout lives and reuses any saved chezmoi profile choices.

The guide walks through five steps:

1. **Initialize:** detect the platform and ask only relevant profile questions.
   This saves chezmoi config/state but does not apply dotfiles.
2. **Plan:** show the effective profile, package adapter, missing packages and
   compatibility warnings. No separate `--plan` command is needed.
3. **Review and apply configs:** show the config diff, then ask for approval
   (default **No**). Config apply excludes script hooks, so this approval cannot
   install packages. Back up existing files before approving replacements.
4. **Optional packages:** if enabled in your profile, show missing packages and
   ask separately (default **No**). Declining leaves the configs applied and
   skips packages for this run; saved preferences are unchanged. The package
   manager may install dependencies; approved installs use APT `-y` or Pacman
   `--noconfirm`. Existing commands are not automatically upgraded.
5. **Final checklist:** report remaining dependencies and manual next steps.
   Missing dependencies are reported, not silently treated as a ready machine.

Cancelling config approval leaves only the saved initialization choices. Failed
config apply stops before package installation. If packages fail, configs remain
applied and the guide reports the partial setup; there is no automatic rollback.
The guide requires a terminal and has no automatic-approval mode. It does not
change your login shell, authenticate applications, or install a full desktop.

### Manual chezmoi and unattended alternatives

Advanced users can still initialize, inspect and apply directly:

```sh
chezmoi --source /path/to/dot_files init
/path/to/dot_files/scripts/setup.sh --plan
chezmoi --source /path/to/dot_files diff
chezmoi --source /path/to/dot_files apply --dry-run --verbose
# Only after reviewing and approving the diff and package plan:
chezmoi --source /path/to/dot_files apply
```

For an existing-machine migration, keep using the target-by-target adoption
workflow below rather than approving a full apply blindly. For a standard
remote initialization, use `chezmoi init https://github.com/jtabke/dot_files.git`,
then run `"$(chezmoi source-path)/../setup"`. Use `--ssh` only after setting up
GitHub SSH access. Do not append `--apply` before reviewing changes.

Direct `chezmoi apply` retains its package approval hook. Non-interactive applies
cannot approve installation implicitly. For unattended setup, explicitly review
`./scripts/setup.sh --plan`, then run `./scripts/setup.sh --install --yes` before
applying. These helpers use the profile selected by init; `--yes` cannot bypass
`installPackages=false`. For Pacman, `--yes` also passes `--noconfirm`; APT uses
`-y`. They are advanced alternatives, not additional steps for the guided flow.

### Complete setup and verify readiness

After applying, run `~/.local/bin/dotfiles-setup --check`. It returns nonzero for
missing/incompatible dependencies; `--plan` is always a read-only report.

- **Activate Zsh yourself.** Try `zsh` first. To make it the login shell, verify
  `command -v zsh` is listed in `/etc/shells`, then explicitly run
  `chsh -s "$(command -v zsh)"` if supported. On WSL check the Windows terminal
  launch profile too. No setup command changes your login shell.
- **Set Git identity** in `~/.config/git/user.inc` (see below).
- **Initialize Neovim deliberately.** First launch downloads plugins, builds
  parsers and installs language servers. It requires network access, Node/npm,
  a C compiler, make, curl and unzip. On macOS install Command Line Tools with
  `xcode-select --install` if needed. Afterwards run `:checkhealth`; editor
  downloads are separate from chezmoi's package-install opt-in.
- **Pi is optional.** Its executable/runtime is not installed by this adapter.
  Install it separately, review the configured package sources before launch,
  then authenticate with `/login`. Neither credentials nor authentication are
  provisioned here.

The portable Pi baseline no longer declares the private `jtabke/pi-extensions`
package or a local `~/Documents/Coding/pi-companion` checkout. Companion uses
its GitHub source on non-WSL machines and remains excluded on WSL. Before
applying on an existing machine, move wanted private or local integrations to a
project's `.pi/settings.json` via
`pi install --local git:git@github.com:jtabke/pi-extensions` or
`pi install --local /absolute/path/to/pi-companion` from that project. Set up
SSH access for the private repository first. Public Pi Git sources use HTTPS.
Do not add those local paths back to the shared baseline.

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

## Desktop prerequisites

The native Linux Hyprland profile also manages `~/.config/waybar`: the bar
configuration, Catppuccin styles, and Wi-Fi, Bluetooth, Tailscale, update, and
power helpers. Their existing unit tests stay in `tests/waybar`, outside chezmoi
source state. Validation runs these tests on temporary copies with mocked system
actions; it does not change networking, install updates, lock, or end the session.

Install desktop dependencies separately; the optional package adapter installs
the CLI tools listed below plus Fuzzel for the Hyprland profile. This desktop uses Waybar, Hyprland, Hypridle,
Hyprlock, Hyprpaper, Ghostty, Fuzzel, Nemo, wlsunset, and Python 3. The bar's
Wi-Fi controls require iwd, `busctl`, `ip`, and Impala; Bluetooth uses
`bluetoothctl` and Bluetui; Tailscale needs its client and daemon. Audio controls
use `wpctl` and Pavucontrol. Menus use Fuzzel, notifications use `notify-send`,
and clipboard/browser actions use `wl-copy` and `xdg-open`. The update helper
is Arch-specific: it uses `checkupdates` from pacman-contrib and opens
`sudo pacman -Syu` in Ghostty only when clicked. Install the Hack Nerd Font and
Font Awesome fonts for the configured icons. The imported bar is not a generic
NetworkManager or cross-distribution configuration.

Hyprland starts Hyprpaper, but wallpaper selection remains machine-local.
Create the unmanaged `~/.config/hypr/hyprpaper.conf` and choose an image that
exists on that host. The current workstation uses
`~/Pictures/Backgrounds/pexels-oleksandr-tiupa-192136.jpg`; neither that file nor
its selection is installed by this repository.

## SSH-agent prerequisite

The shared Pi package list uses HTTPS and does not require a GitHub SSH agent.
If you opt into private SSH packages in project-local settings, configure GitHub
SSH access and make the intended agent available to the shell first. Chezmoi
does not create an SSH-agent service or install keys.

This Linux workstation has an unmanaged `~/.config/zsh/.zshenv` containing:

```sh
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
```

That setting assumes an agent already listens on the named socket. Keep it local:
verify the socket and agent startup on each host instead of copying the Linux path
to macOS or WSL. Preserve SSH forwarding settings on hosts that use them.

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

`home/run_onchange_install-packages.sh.tmpl` and `dotfiles-setup` share one
package plan and readiness implementation. They can install missing Git,
Git LFS, Neovim, zsh, tmux, ripgrep, fzf, Node/npm, make, curl, unzip and Linux
compiler tools through:

- Homebrew from `PATH`, `/opt/homebrew/bin`, or `/usr/local/bin`
- Pacman, with root and sudo handling
- APT

Fuzzel is additionally installed only for native Linux workstations using the
`auto` or `hyprland` desktop profile, never for WSL2, shell-only profiles, or
`desktop=none`.

Installation is disabled when `installPackages=false`; reporting still works.
Existing commands are not automatically upgraded. The readiness check requires
Neovim >= 0.11.3, tmux >= 3.5 (`extended-keys-format`), fzf >= 0.48 (`--zsh`),
and Node >= 22. Older distro packages may require a separate trusted installation
method. No third-party repositories or remote installer scripts are added.

Repository validation renders profile cases and executes only **mocked** package
adapters, never real installations. Review `--plan` before enabling changes.

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
