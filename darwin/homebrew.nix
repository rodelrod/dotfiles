# Homebrew integration - replaces Brewfile
# Only for GUI apps and macOS-specific tools that need system integration
{ config, pkgs, lib, ... }:

let
  packages = import ../homebrew/packages.nix;
in
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = false;
      # Can't use `uninstall` or `zap` because of tap dependencies (e.g. emacs-plus). I will work but show an error.
      # Use brew's `cleanup` command manually to remove old versions and free up space.
      cleanup = "none";
    };

    taps = packages.taps;

    brews = packages.brews;

    casks =
      packages.casks
      ++ packages.permissionSensitiveCasks
      ++ packages.personalCasks
      ++ packages.adminLikelyCasks;
  };
}
