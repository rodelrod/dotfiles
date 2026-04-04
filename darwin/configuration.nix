{ config, pkgs, lib, ... }:

let
  homeDir = config.users.users.rodelrod.home;
in
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
  # Commit local Org edits every 15 minutes for fine-grained history.
  launchd.user.agents.org-autocommit = {
    serviceConfig = {
      ProgramArguments = [ "/bin/bash" "${homeDir}/dotfiles/scripts/org-autocommit.sh" ];
      EnvironmentVariables = {
        ORG_AUTOCOMMIT_MODE = "commit-only";
        ORG_AUTOCOMMIT_LOG_DIR = "${homeDir}/Library/Logs/org-autocommit/commit";
      };
      RunAtLoad = true;
      StartInterval = 900;
      StandardOutPath = "${homeDir}/Library/Logs/org-autocommit/org-autocommit.launchd.out.log";
      StandardErrorPath = "${homeDir}/Library/Logs/org-autocommit/org-autocommit.launchd.err.log";
    };
  };

  # Pull/push Org notes once per day with a strict fast-forward-only workflow.
  launchd.user.agents.org-autosync = {
    serviceConfig = {
      ProgramArguments = [ "/bin/bash" "${homeDir}/dotfiles/scripts/org-autocommit.sh" ];
      EnvironmentVariables = {
        ORG_AUTOCOMMIT_MODE = "full-sync";
        ORG_AUTOCOMMIT_LOG_DIR = "${homeDir}/Library/Logs/org-autocommit/sync";
      };
      StartCalendarInterval = {
        Hour = 9;
        Minute = 0;
      };
      StandardOutPath = "${homeDir}/Library/Logs/org-autocommit/org-autosync.launchd.out.log";
      StandardErrorPath = "${homeDir}/Library/Logs/org-autocommit/org-autosync.launchd.err.log";
    };
  };

  # PostgreSQL server managed by nix-darwin.
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    port = 5432;
    package = pkgs.postgresql;
    dataDir = "${homeDir}/.local/share/postgresql-${pkgs.postgresql.psqlSchema}";
  };

  # Network settings, keyboard layouts, etc. can go here
  # See: https://daiderd.com/nix-darwin/manual/index.html

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
