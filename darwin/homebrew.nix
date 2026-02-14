# Homebrew integration - replaces Brewfile
# Only for GUI apps and macOS-specific tools that need system integration
{ config, pkgs, lib, ... }:

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

    taps = [
      "d12frosted/emacs-plus"
    ];

    brews = [
      # macOS-specific CLI tools that need system integration
      "pngpaste" # For doom-emacs - needs macOS clipboard access
      "ollama" # If you prefer Homebrew version
      # Emacs with native-comp (macOS-specific patches)
      {
        name = "emacs-plus@29";
        args = [ "with-native-comp" ];
      }
    ];

    casks = [
      # GUI apps
      "alt-tab"
      "cursor"
      "discord"
      "karabiner-elements"
      "libreoffice"
      "google-chrome"
      "meld"
      "monitorcontrol"
      "portfolioperformance"
      "raycast"
      "rectangle-pro"
      "ukelele"
      "visual-studio-code"
      "xmind"
      # Fonts
      "font-source-sans-3"
      "font-source-code-pro"
    ];
  };
}
