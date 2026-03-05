# dotfiles

Nix flake-based dotfiles for macOS (`nix-darwin` + Home Manager) and Linux (Home Manager only).

## Hosts

- `kubrick`: `aarch64-darwin` (macOS)
- `xenakis`: `x86_64-linux`

## What this manages

- Shell + CLI tools (`home/shared.nix`)
- Git + Zsh config (Home Manager)
- macOS system defaults (`darwin/configuration.nix`)
- Homebrew taps/formulas/casks on macOS (`darwin/homebrew.nix`)
- Host-specific activation hooks (`home/darwin.nix`, `home/linux.nix`)

## Prerequisites

- Nix installed with flakes enabled
- Git
- macOS only: Homebrew (managed through nix-darwin module settings)

## Bootstrap

### macOS (`kubrick`)

```bash
# first run (before darwin-rebuild exists in PATH)
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#kubrick

# subsequent runs
sudo darwin-rebuild switch --flake .#kubrick
```

### Linux (`xenakis`)

```bash
home-manager switch --flake .#xenakis
```

## Daily usage

```bash
# apply macOS config
sudo darwin-rebuild switch --flake .#kubrick

# apply Linux config
home-manager switch --flake .#xenakis

# update flake inputs
nix flake update
```

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

## Neovim (LazyVim)

Neovim is managed by Home Manager with a LazyVim starter config under `config/nvim`.

After applying your Nix config, start Neovim once to bootstrap plugins:

```bash
nvim
```

## Org auto-commit

On macOS, a user launchd agent (`org-autocommit`) runs every 15 minutes and executes:

```bash
/Users/rodelrod/dotfiles/scripts/org-autocommit.sh
```

The script stages all changes in `~/Org`, asks Ollama (`qwen2.5:14b`) for a notes-focused commit message, and commits automatically when changes exist.

### Ollama model setup

Before using auto-commit, make sure Ollama is running and the model is available:

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
- `ORG_AUTOCOMMIT_TITLE_MAX_LEN` (default: `50`; prompt hint for model title length, not enforced by script)
- `ORG_AUTOCOMMIT_MAX_DIFF_FILES` (default: `12`)
- `ORG_AUTOCOMMIT_MAX_DIFF_LINES_PER_FILE` (default: `80`)
- `ORG_AUTOCOMMIT_DRY_RUN=1` (generate/log message without committing)
- `ORG_AUTOCOMMIT_PUSH=1` (push after commit)

## Repo layout

- `flake.nix`: outputs, hosts, module wiring
- `darwin/`: nix-darwin + Homebrew config
- `home/`: shared and host-specific Home Manager modules
- `scripts/`: helper scripts

## Customization

- Add cross-platform packages in `home/shared.nix`
- Add macOS system settings in `darwin/configuration.nix`
- Add macOS-only brew apps in `darwin/homebrew.nix`
- Add platform-specific tweaks in `home/darwin.nix` or `home/linux.nix`

## Notes

- Hostnames, usernames, and home paths are defined in `flake.nix`
