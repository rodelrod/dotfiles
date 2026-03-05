{ config, pkgs, lib, ... }:

{
  # Install reusable Karabiner complex modifications, but leave karabiner.json unmanaged.
  xdg.configFile."karabiner/assets/complex_modifications" = {
    source = ../config/karabiner/assets/complex_modifications;
    recursive = true;
  };

  # Restart Ollama service after Homebrew activation (replaces restart_service: true)
  home.activation.restartOllama = lib.mkAfter ''
    if command -v brew >/dev/null 2>&1; then
      echo "Restarting Ollama service via Homebrew..."
      brew services restart ollama || true
    fi
  '';

  # Ensure emacs-plus@29 is linked as `emacs` in PATH
  home.activation.linkEmacsPlus = lib.mkAfter ''
    if command -v brew >/dev/null 2>&1; then
      if brew list --formula | grep -q '^emacs-plus@29$'; then
        echo "Linking emacs-plus@29 as emacs..."
        brew link emacs-plus@29 --overwrite --force || true
      else
        echo "emacs-plus@29 not installed; skipping brew link."
      fi
    fi
  '';
}
