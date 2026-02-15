{ config, pkgs, lib, ... }:

{
  imports = [ ./homebrew.nix ];

  # System-level macOS configuration via nix-darwin

  # Basic system settings
  system.stateVersion = 4; # macOS version (adjust as needed)

  # User account
  users.users.rodelrod = {
    name = "rodelrod";
    home = "/Users/rodelrod";
  };

  # Primary user for user-scoped nix-darwin options (e.g. homebrew.enable)
  system.primaryUser = "rodelrod";

  # System packages (installed system-wide)
  environment.systemPackages = with pkgs; [
    # Add system-level packages here if needed
  ];

  # macOS system defaults
  # Uncomment and customize as needed:
  system.defaults.dock.autohide = true;
  system.defaults.dock.orientation = "left";
  system.defaults.finder.AppleShowAllFiles = true;
  system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
  # system.defaults.NSGlobalDomain.KeyRepeat = 2;
  # system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;

  # Launchd services (system-level)
  # Auto-commit Org notes every 15 minutes using Ollama for commit messages.
  launchd.user.agents.org-autocommit = {
    serviceConfig = {
      ProgramArguments = [ "/bin/bash" "/Users/rodelrod/dotfiles/scripts/org-autocommit.sh" ];
      RunAtLoad = true;
      StartInterval = 900;
      StandardOutPath = "/Users/rodelrod/Library/Logs/org-autocommit.launchd.out.log";
      StandardErrorPath = "/Users/rodelrod/Library/Logs/org-autocommit.launchd.err.log";
    };
  };

  # Network settings, keyboard layouts, etc. can go here
  # See: https://daiderd.com/nix-darwin/manual/index.html

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
