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
    ++ map caskLine packages.casks
    ++ [ "" ]
  );
in
{
  imports = [
    ./darwin.nix
  ];

  home.sessionVariables = {
    HOMEBREW_CASK_OPTS = "--appdir=$HOME/Applications";
  };

  xdg.configFile."homebrew/Brewfile".text = brewfile;
}
