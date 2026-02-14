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

This installs or updates Doom Emacs core and your Doom config.

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
