{ config, pkgs, lib, ... }:

let
  packages = import ../homebrew/packages.nix;

  quote = value: "\"${lib.escape [ "\\" "\"" ] value}\"";

  tapLine = tap: "tap ${quote tap}";

  brewLine = brew:
    if builtins.isString brew then
      "brew ${quote brew}"
    else
      let
        args = lib.concatMapStringsSep ", " quote brew.args;
      in
      "brew ${quote brew.name}, args: [${args}]";

  caskLine = cask: "cask ${quote cask}";

  brewfile = lib.concatStringsSep "\n" (
    [
      "# Managed by Home Manager from ~/dotfiles/homebrew/packages.nix"
      "# Apply manually on non-admin macOS hosts with:"
      "#   brew bundle --file ~/.config/homebrew/Brewfile"
      "cask_args appdir: \"~/Applications\""
      ""
    ]
    ++ map tapLine packages.taps
    ++ [ "" ]
    ++ map brewLine packages.brews
    ++ [ "" ]
    ++ map caskLine (packages.sharedCasks ++ packages.workCasks)
    ++ [ "" ]
  );
in
{
  imports = [
    ./darwin.nix
  ];

  # Home Manager-only macOS host: make Nix and HM profile tools available in
  # fresh terminals without relying on system-level nix-darwin shell setup.
  home.sessionPath = [
    "/nix/var/nix/profiles/default/bin"
    "$HOME/.nix-profile/bin"
  ];

  # Oxum is a non-admin work machine, so keep Homebrew quiet and install casks
  # into the user Applications folder by default.
  home.sessionVariables = {
    HOMEBREW_NO_AUTO_UPDATE = "1";
    HOMEBREW_NO_ENV_HINTS = "1";
    HOMEBREW_CASK_OPTS = "--appdir=$HOME/Applications";
  };

  # Homebrew was installed outside the default shell setup path on Oxum.
  programs.zsh.initContent = lib.mkAfter ''
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  '';

  xdg.configFile."homebrew/Brewfile".text = brewfile;
}
