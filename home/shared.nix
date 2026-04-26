{ config, pkgs, lib, ... }:

let
  doomCorePath = "${config.home.homeDirectory}/.config/emacs";
  orgTexlive = pkgs.texlive.combine {
    base = pkgs.texlive."scheme-small";
    wrapfig = pkgs.texlive.wrapfig;
    captOf = pkgs.texlive."capt-of";
    dvisvgm = pkgs.texlive.dvisvgm;
  };
in
{
  home.stateVersion = "24.05";
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;

    settings = {
      include.path = "${config.home.homeDirectory}/.gitconfig.local";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

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
    defaultKeymap = "emacs";
    enableCompletion = true;
    autosuggestion.enable = true;
    shellAliases = {
      ls = "eza --group-directories-first";
      ll = "eza -lah --git --icons=auto --group-directories-first";
      la = "eza -a --group-directories-first";
      lt = "eza --tree --level=2 --icons=auto";
      z = "cd";
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

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";

      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[>](bold red)";
      };

      cmd_duration = {
        min_time = 500;
        format = "[$duration]($style) ";
      };
    };
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
    eza
    fd
    go
    gopls
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
  xdg.configFile."nvim/after" = {
    source = ../config/nvim/after;
    recursive = true;
  };
  xdg.configFile."ghostty/config".source = ../config/ghostty/config;

  # Doom Emacs: install/update via scripts/post-install.sh after darwin-rebuild.
}
