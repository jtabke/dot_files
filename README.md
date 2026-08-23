# dot_files

A chezmoi source repository for portable shell, editor, terminal, Pi, and
selected desktop configuration. The repository supports Linux, macOS, and
WSL2. Validation never writes to the real home directory.

## Source root and bootstrap

`.chezmoiroot` points chezmoi at `home/`. All managed source state and chezmoi
special files live below that directory. README, docs, hooks, tests, and the
project `.pi` metadata stay outside the source root automatically. The project
`.pi/agent` path is one symlink to `home/dot_pi/agent`; there is no second Pi
configuration tree.

```text
.
├── .chezmoiroot             # selects home/ as chezmoi source state
├── home/                    # only this subtree installs into $HOME
│   ├── .chezmoi.toml.tmpl   # once-only machine profile questions
│   ├── .chezmoiignore       # OS, WSL, role, and desktop selection
│   ├── dot_config/          # installs as ~/.config/
│   ├── dot_pi/              # installs as ~/.pi/
│   ├── dot_zshenv           # installs as ~/.zshenv
│   └── run_onchange_*       # opt-in package bootstrap
├── .pi/agent -> ../home/dot_pi/agent
├── docs/                    # design and migration documentation
├── hooks/                   # repository Git hooks
└── tests/                   # isolated validation; never targets real $HOME
```

Chezmoi encodes target attributes in source names: `dot_` adds a leading dot,
`executable_` installs executable mode, `symlink_` creates a symlink, and
`.tmpl` renders machine-specific content. Use `chezmoi source-path TARGET` when
you do not know the encoded source path.

Install chezmoi with the platform's normal, user-approved method. Then run:

```sh
chezmoi --source /path/to/dot_files init
chezmoi --source /path/to/dot_files diff
chezmoi --source /path/to/dot_files apply
```

The first clean init asks once for:

- `role`: `workstation` or `shell`
- `desktop`: `auto`, `hyprland`, `aerospace`, or `none`
- `installPackages`: false by default
- `autoTmux`: false by default

Review `chezmoi --source /path/to/dot_files diff` before applying. Package installation is disabled by
default and is never needed for repository validation. Enable it only after
reviewing the rendered run script.

Enable the repository hook for source changes:

```sh
git -C /path/to/dot_files config core.hooksPath hooks
```

## Profiles and platform behavior

The `shell` role excludes every desktop path. WSL is detected from
`.chezmoi.kernel.osrelease` and receives shell and command-line files only.
Native Linux manages Hyprland for `auto` or `hyprland`. Linux never manages
AeroSpace or SketchyBar. macOS manages AeroSpace and SketchyBar for `auto` or
`aerospace`; macOS never manages Hyprland. `none` excludes all desktop paths.

The source names use chezmoi path encoding. For example, `home/dot_zshenv`
installs `~/.zshenv`, `home/dot_config/nvim` installs `~/.config/nvim`, and
`home/dot_config/kitty/symlink_theme.conf` installs a relative Kitty symlink at
`~/.config/kitty/theme.conf`. Executable source files use the `executable_`
attribute.

The managed Git config includes an unmanaged
`~/.config/git/user.inc`. Put personal `[user]` settings there; no identity is
stored in this repository.

## Packages

`home/run_onchange_install-packages.sh.tmpl` is opt-in. It checks commands
first and installs only missing Git, Neovim, zsh, tmux, ripgrep, and fzf through
Homebrew, Pacman, or APT. Homebrew is found through `PATH`,
`/opt/homebrew/bin`, or `/usr/local/bin`. Pacman supports root without sudo and
reports a clear error when sudo is unavailable or fails.

## Source-first and live-first cutover

Source-first workflow:

```sh
chezmoi --source /path/to/dot_files diff
chezmoi --source /path/to/dot_files apply
```

For a live-first cutover, review one live path at a time and import only an
intentional change:

```sh
chezmoi --source /path/to/dot_files re-add ~/.config/zsh/.zshrc
chezmoi --source /path/to/dot_files diff
```

Do not use `re-add` on an entire home directory. A templated source file must
not be blindly re-added: its rendered live content does not contain the
original template logic. Edit the template or use
`chezmoi --source /path/to/dot_files merge` after reviewing the live change.

After this repository is committed and available remotely, a new machine can
clone it into chezmoi's default source directory. Bare commands are safe after
that standard initialization:

```sh
chezmoi init --ssh jtabke/dot_files
chezmoi diff
chezmoi apply
```

Run isolated repository checks with:

```sh
./tests/validate-repository.sh
```

That test uses real chezmoi with temporary source/config/cache/state and
 destination paths. It does not apply to `$HOME`, install packages, stage,
commit, or push changes.
