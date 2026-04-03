{ config, pkgs, lib, ... }:

{
  targets.genericLinux = {
    enable = true;
    gpu.enable = false;
  };

  programs.zsh.completionInit = "autoload -U compinit && compinit -i";

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nix
    gcc
    gnumake
    emacs-gtk
    nerd-fonts.jetbrains-mono
    source-code-pro
    source-sans
  ];
}
