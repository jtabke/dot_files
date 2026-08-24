# Chezmoi migration

## Source layout

The repository root contains `.chezmoiroot` with the value `home`. Chezmoi
therefore reads only `home/` as source state. The root keeps project material
outside that source root:

- `README.md`, `docs/`, `hooks/`, and `tests/` are repository files.
- `.pi/agent` is a tracked directory symlink to `home/dot_pi/private_agent`.
- `home/.chezmoi.toml.tmpl`, `home/.chezmoiignore`, managed `dot_*` entries,
  and run scripts are the chezmoi state.

This layout avoids repository-metadata ignore rules. `.chezmoiignore` contains
only decoded target paths for profile selection.

## Clean bootstrap

After installing chezmoi through an approved user-level method, initialize the
checkout and answer the four prompts:

```sh
chezmoi --source /path/to/dot_files init
chezmoi --source /path/to/dot_files diff
chezmoi --source /path/to/dot_files apply
```

The prompt owner is `home/.chezmoi.toml.tmpl`. It uses the exact once-only
functions `promptChoiceOnce . "role" "Machine role" (list "workstation" "shell")`,
`promptChoiceOnce . "desktop" "Desktop environment" (list "auto" "hyprland" "aerospace" "none")`,
`promptBoolOnce . "installPackages" "Install missing packages during apply?"`, and
`promptBoolOnce . "autoTmux" "Automatically attach interactive shells to tmux?"`.
Choose `workstation`, `auto`, `false`, and `false` for the standard workstation
profile. The generated config stores the answers and derived public platform facts. There is no duplicate static
profile data file.

## Profile contract

- `shell` excludes all desktop paths.
- Native Linux uses Hyprland for `auto` or `hyprland`.
- macOS uses AeroSpace and SketchyBar for `auto` or `aerospace`.
- `none` excludes all desktop paths.
- WSL detection uses a safe lookup of the lower-cased kernel release; WSL is shell/CLI only.
- Linux never manages AeroSpace or SketchyBar.
- macOS never manages Hyprland.
- The macOS AeroSpace profile manages `.config/aerospace` and
  `.config/sketchybar`. SketchyBar is currently inactive and optional because
  the imported AeroSpace config does not start it or send workspace-change
  triggers. The migration removes the legacy `~/.aerospace.toml` target.

`.chezmoiignore` matches decoded targets such as `.config/hypr` and
`.config/aerospace`, not source names such as `dot_config/hypr`.

## Cutover

Review live drift one path at a time:

```sh
chezmoi --source /path/to/dot_files diff
chezmoi --source /path/to/dot_files re-add ~/.config/zsh/.zshrc
chezmoi --source /path/to/dot_files diff
chezmoi --source /path/to/dot_files apply
```

Do not re-add an entire home directory. Live-first imports of templated files
are unsafe if they replace the source template with rendered output: the live
file does not contain template logic. Edit the source template or use
`chezmoi --source /path/to/dot_files merge` after reviewing the live change.

Package installation is opt-in. Keep `installPackages=false` for validation;
no validation command executes package installation. When enabled, the adapter
finds Brew in `PATH`, `/opt/homebrew/bin`, or `/usr/local/bin`, supports root
Pacman without sudo, and reports sudo failures clearly.

Run the migration checks:

```sh
./tests/validate-repository.sh
```

The test runs chezmoi v2.72.0 with isolated `--source`, `--config`, `--cache`,
`--destination`, and persistent-state paths. It prompts through stdin into a
temporary config, renders host-native workstation/`auto` and shell/`none`
profiles, performs a dry run and apply, verifies a clean second diff, and checks
paths, modes, JSON, TOML, shell syntax, the Kitty relative symlink, Pi link,
secrets, and `git diff --check`. Darwin runs natively on macOS and Linux runs
natively on Linux. It does not change the real `$HOME`. WSL and cross-host
simulation remain residual platform test gaps.
