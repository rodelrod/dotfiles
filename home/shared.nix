{ config, pkgs, lib, ... }:

let
  doomCorePath = "${config.home.homeDirectory}/.config/emacs";
in
{
  home.stateVersion = "24.05";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    shellAliases = {
      ll = "ls -la";
      gs = "git status";
      doom = "${doomCorePath}/bin/doom";
    };
  };

  programs.git.enable = true;

  home.packages = with pkgs; [
    # CLI tools (cross-platform via Nix)
    bat
    fd
    fzf
    graphviz
    htop
    neovim
    pdftk
    pwgen
    ripgrep
    tmux
    tree
    uv
    wget
  ];

  # Doom Emacs: install/update via scripts/post-install.sh after darwin-rebuild.
}
