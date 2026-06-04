{
  taps = [
    "d12frosted/emacs-plus"
  ];

  brews = [
    # macOS-specific CLI tools that need system integration
    "pngpaste"  # For doom-emacs - needs macOS clipboard access
    "ollama"
    "emacs-plus@30"  # Emacs with native-comp support via libgccjit.
  ];

  sharedCasks = [
    "alt-tab"
    "cursor"
    "dbeaver-community"
    "ghostty"
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
    "font-symbols-only-nerd-font"
  ];

  personalCasks = [
    "codex"
    "discord"
    "google-chrome"
    "hammerspoon"
    "karabiner-elements"
    "monitorcontrol"
    "portfolioperformance"
    "rectangle-pro"
  ];

  workCasks = [
    "copilot-cli"
    "kiro"
    "kiro-cli"
  ];
}
