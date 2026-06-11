# dotfiles

Nix flake-based dotfiles for macOS (`nix-darwin` + Home Manager or Home Manager only) and Linux (Home Manager only).

## Hosts

- `kubrick`: `aarch64-darwin` (macOS)
- `oxum`: `aarch64-darwin` (macOS, Home Manager only)
- `xenakis`: `x86_64-linux`
- `ramiro`: `x86_64-linux`

## What this manages

- Shell + CLI tools (`home/shared.nix`)
- Git + Zsh config (Home Manager)
- macOS system defaults (`darwin/configuration.nix`)
- Homebrew taps/formulas/casks on macOS (`homebrew/packages.nix`)
- Host-specific activation hooks (`home/darwin.nix`, `home/linux.nix`, `home/oxum.nix`)

## Prerequisites

- Nix installed with flakes enabled
- Git
- macOS only: Homebrew (`kubrick` is managed through nix-darwin; `oxum` uses a generated Brewfile)

## Bootstrap

### macOS with nix-darwin (`kubrick`)

```bash
# first run (before darwin-rebuild exists in PATH)
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#kubrick

# subsequent runs
sudo darwin-rebuild switch --flake .#kubrick
```

### macOS without admin rights (`oxum`)

Apply the Home Manager profile:

```bash
home-manager switch --flake .#oxum
```

This writes a Brewfile to:

- `~/.config/homebrew/Brewfile`

Apply Homebrew packages manually when appropriate:

```bash
brew bundle --file ~/.config/homebrew/Brewfile
```

The generated Brewfile installs shared and work casks into `~/Applications`.

### Linux (`xenakis`)

```bash
home-manager switch --flake .#xenakis
```

## Daily usage

```bash
# apply macOS nix-darwin config
sudo darwin-rebuild switch --flake .#kubrick

# apply macOS Home Manager-only config
home-manager switch --flake .#oxum

# apply Linux config
home-manager switch --flake .#xenakis

# update flake inputs
nix flake update
```

## New project bootstrap

Create a Nix + direnv project and copy the AI project setup preferences:

```bash
new-nix-project my-project
```

Without an argument, `new-nix-project` initializes the current directory.

## Post-install

After rebuild/switch, run:

```bash
./scripts/post-install.sh
```

This installs or updates Doom Emacs core, your Doom config, and clones/updates `~/Org`.

## Karabiner (Complex Modifications)

Complex modification JSON files are tracked in this repo and installed via Home Manager to:

- `~/.config/karabiner/assets/complex_modifications/`

`karabiner.json` is intentionally **not** tracked or managed in this repo.

After applying your macOS config, enable the rules you want in Karabiner-Elements UI:

1. Open Karabiner-Elements.
2. Go to `Complex Modifications`.
3. Click `Add predefined rule`.
4. Enable the rules you want (for example: Both Shifts Toggle Caps Lock, Right Option Hyper, Disable Cmd-H).

## Hammerspoon

Hammerspoon config is tracked in this repo and installed via Home Manager to:

- `~/.hammerspoon/`

After applying your macOS config:

1. Open Hammerspoon.
2. If prompted, grant Accessibility permission in macOS settings.
3. Use the Hammerspoon menu bar icon and click `Reload Config`.

## Git

Create a `~/.gitconfig.local` file with the user you want:

```ini
[user]
  name = UserName
  email = user@example.com
```

## Neovim (LazyVim)

Neovim is managed by Home Manager with a LazyVim starter config under `config/nvim`.

After applying your Nix config, start Neovim once to bootstrap plugins:

```bash
nvim
```

If you edit Neovim Lua source directly in this repo (`~/dotfiles/config/nvim`), generate a host-local LuaLS config that points to the current machine's Neovim runtime:

```bash
./scripts/gen-nvim-luarc.sh
```

This writes `config/nvim/.luarc.json` (git-ignored) for local diagnostics while editing dotfiles source.

## DBeaver (Vim keybindings)

DBeaver can install Eclipse plugins. To add Vim-style keybindings:

1. Open DBeaver.
2. Go to `Help` -> `Install New Software...`.
3. Add/update site URL: `http://vrapper.sourceforge.net/update-site/stable`
4. Select `Vrapper` and finish installation.
5. Restart DBeaver when prompted.

If DBeaver was installed in a protected path (for example `/Applications`), plugin installation may require elevated permissions or a user-writable install location.

## PostgreSQL (manual first-time setup for MacOS)

PostgreSQL is installed via Nix and managed by nix-darwin.
After `sudo darwin-rebuild switch --flake .#kubrick`, run this once:

```bash
# if your OS user role does not exist yet
PG_MAJOR="$(psql --version | awk '{print $3}' | cut -d. -f1)"
launchctl bootout gui/$(id -u)/org.nixos.postgresql
printf 'CREATE ROLE "%s" WITH LOGIN SUPERUSER;\n' "$USER" \
  | postgres --single -D "$HOME/.local/share/postgresql-${PG_MAJOR}" postgres
launchctl bootstrap gui/$(id -u) "$HOME/Library/LaunchAgents/org.nixos.postgresql.plist"
launchctl kickstart -k gui/$(id -u)/org.nixos.postgresql

# create a database for your user
createdb "$USER"
```

Optional (for DBeaver/TCP login):

```bash
psql -d postgres -c "ALTER ROLE \"$USER\" PASSWORD 'change-me';"
```

## Org auto-sync

Two user launchd agents execute the same script with different modes:

```bash
~/dotfiles/scripts/org-autocommit.sh
```

On `kubrick`, they are managed by nix-darwin. On `oxum`, where the user does
not have admin rights, they are managed by Home Manager as per-user
LaunchAgents.

Schedules:

- `org-autocommit`: runs on login and every 15 minutes with `ORG_AUTOCOMMIT_MODE=commit-only`
- `org-autosync`: runs daily at 09:00 with `ORG_AUTOCOMMIT_MODE=full-sync`
- `org-orisha-autocommit`: runs on login and every 15 minutes for `~/Org/notes/client/orisha`
- `org-orisha-autosync`: runs daily at 09:05 for `~/Org/notes/client/orisha`

`commit-only` mode:

- stages and commits local changes in `~/Org`
- never fetches, pulls, or pushes
- aborts if the repo is already conflicted or mid-merge/rebase/cherry-pick

`full-sync` mode:

- `git fetch origin`
- abort with a local notification if the repo is conflicted, mid-rebase/merge/cherry-pick, or dirty while behind upstream
- `git pull --ff-only` when the repo is clean and behind
- `git pull --rebase` when the repo has both local commits and remote commits
- auto-commit local changes with an Ollama-generated Org-focused commit message when the repo is not behind
- `git push origin` only when the branch is ahead and not diverged

It never runs a plain `git pull` and never creates merge commits automatically.

Apply the Oxum LaunchAgents with:

```bash
home-manager switch --flake .#oxum
```

Home Manager writes the plists to `~/Library/LaunchAgents` and bootstraps them
into the user launchd domain. Useful checks:

```bash
launchctl list | grep org-autocommit
launchctl list | grep org-autosync
launchctl list | grep org-orisha
tail -f ~/Library/Logs/org-autocommit/org-autocommit.launchd.err.log
tail -f ~/Library/Logs/org-autocommit/commit/org-autocommit.log
tail -f ~/Library/Logs/org-autocommit/orisha-commit/org-autocommit.log
```

### Ollama model setup

Before using auto-sync, make sure Ollama is running and the model is available:

```bash
# start Ollama server
brew services start ollama

# pull model used by the script
ollama pull qwen2.5:14b

# verify Ollama and model availability
ollama ps
ollama list | rg 'qwen2.5:14b'
```

Optional environment variables:

- `ORG_AUTOCOMMIT_ORG_DIR` (default: `~/Org`)
- `ORG_AUTOCOMMIT_MODEL` (default: `qwen2.5:14b`)
- `ORG_AUTOCOMMIT_HOSTNAME_LABEL` (default: output of `hostname -s`)
- `ORG_AUTOCOMMIT_MODE` (`commit-only` or `full-sync`; default: `full-sync`)
- `ORG_AUTOCOMMIT_TITLE_MAX_LEN` (default: `50`; prompt hint for model title length, not enforced by script)
- `ORG_AUTOCOMMIT_MAX_DIFF_FILES` (default: `12`)
- `ORG_AUTOCOMMIT_MAX_DIFF_LINES_PER_FILE` (default: `80`)
- `ORG_AUTOCOMMIT_DRY_RUN=1` (log the pull/commit/push actions it would take without mutating the repo)

## Repo layout

- `flake.nix`: outputs, hosts, module wiring
- `darwin/`: nix-darwin system config for admin-capable macOS hosts
- `homebrew/`: shared and host-specific Homebrew package inventory
- `home/`: shared and host-specific Home Manager modules
- `scripts/`: helper scripts
- `templates/`: reusable project templates and seed files

## Customization

- Add cross-platform packages in `home/shared.nix`
- Add macOS system settings in `darwin/configuration.nix`
- Add macOS-only Homebrew taps, formulas, and shared/personal/work casks in `homebrew/packages.nix`
- Add nix-darwin Homebrew activation behavior in `darwin/homebrew.nix`
- Add platform-specific Home Manager tweaks in `home/darwin.nix`, `home/linux.nix`, or `home/oxum.nix`

## Notes

- Flake profile names, usernames, and home paths are defined in `flake.nix`; profile names do not need to match the machine hostname.
