{ config, pkgs, lib, ... }:

let
  doomCorePath = "${config.home.homeDirectory}/.config/emacs";
  orgTexlive = pkgs.texlive.combine {
    base = pkgs.texlive."scheme-small";
    wrapfig = pkgs.texlive.wrapfig;
    captOf = pkgs.texlive."capt-of";
  };
in
{
  home.stateVersion = "24.05";
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git.enable = true;

  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    shortcut = "a"; # Changes prefix to Ctrl-a
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    focusEvents = true;
    aggressiveResize = true;
    escapeTime = 0;
    historyLimit = 50000;

    extraConfig = builtins.readFile ../config/tmux/tmux.conf;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      {
        plugin = dracula;
        extraConfig = ''
          set -g @dracula-plugins " "  # Don't show anything on bottom right (empty string shows everything)
          set -g @dracula-show-powerline true
          set -g @dracula-show-flags true
          set -g @dracula-show-left-icon session  # it can accept session, smiley, window, or any character.
          set -g @dracula-border-constrast true
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-strategy-vim 'session'
        '';
      }
    ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    shellAliases = {
      ll = "ls -la";
      gs = "git status";
      doom = "${doomCorePath}/bin/doom";
    };
    envExtra = ''
      # Local machine-only secrets and overrides.
      [[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
    '';
    initContent = ''
      # Local machine-only secrets and overrides.
      [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
    '';
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
  };


  home.packages = with pkgs; [
    # CLI tools (cross-platform via Nix)
    bat
    fd
    fzf
    graphviz
    htop
    nodejs
    nodePackages.typescript
    nodePackages.typescript-language-server
    qpdf
    pandoc
    pdftk
    orgTexlive
    postgresql
    pwgen
    pyright
    ripgrep
    tree
    uv
    wget
  ];

  xdg.configFile."nvim/init.lua".source = ../config/nvim/init.lua;
  xdg.configFile."nvim/lua/config" = {
    source = ../config/nvim/lua/config;
    recursive = true;
  };
  xdg.configFile."nvim/lua/plugins" = {
    source = ../config/nvim/lua/plugins;
    recursive = true;
  };

  # Doom Emacs: install/update via scripts/post-install.sh after darwin-rebuild.
}
