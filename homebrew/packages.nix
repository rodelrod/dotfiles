{
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
    "codex"
    "cursor"
    "dbeaver-community"
    "ghostty"
    "google-chrome"
    "hammerspoon"
    "libreoffice"
    "meld"
    "raycast"
    "ukelele"
    "visual-studio-code"
    "xmind"

    # Fonts
    "font-jetbrains-mono-nerd-font"
    "font-source-code-pro"
    "font-source-sans-3"
  ];

  personalCasks = [
    "discord"
    "portfolioperformance"
  ];

  adminLikelyCasks = [
    "karabiner-elements"
    "monitorcontrol"
    "rectangle-pro"
  ];
}
