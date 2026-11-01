{ config, pkgs, lib, ... }:

{
  # Both Apple Silicon hosts use /opt/homebrew. Keep Docker's config.json
  # writable (contexts/authentication) and expose Brew plugins via user links.
  home.file.".docker/cli-plugins/docker-compose".source =
    config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/opt/docker-compose/bin/docker-compose";
  home.file.".docker/cli-plugins/docker-buildx".source =
    config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/opt/docker-buildx/bin/docker-buildx";

  # Install reusable Karabiner complex modifications, but leave karabiner.json unmanaged.
  xdg.configFile."karabiner/assets/complex_modifications" = {
    source = ../config/karabiner/assets/complex_modifications;
    recursive = true;
  };

  # Install Hammerspoon configuration.
  home.file.".hammerspoon" = {
    source = ../config/hammerspoon;
    recursive = true;
  };

  # Restart Ollama service after Homebrew activation (replaces restart_service: true)
  home.activation.restartOllama = lib.mkAfter ''
    if command -v brew >/dev/null 2>&1; then
      echo "Restarting Ollama service via Homebrew..."
      brew services start ollama || brew services restart ollama || true
    fi
  '';

  # Ensure emacs-plus@30 is linked as `emacs` in PATH
  home.activation.linkEmacsPlus = lib.mkAfter ''
    if command -v brew >/dev/null 2>&1; then
      if brew list --formula | grep -q '^emacs-plus@30$'; then
        echo "Linking emacs-plus@30 as emacs..."
        brew link emacs-plus@30 --overwrite --force || true
      else
        echo "emacs-plus@30 not installed; skipping brew link."
      fi
    fi
  '';
}
