{
  taps = [
    "d12frosted/emacs-plus"
  ];

  brews = [
    # macOS-specific CLI tools that need system integration
    "pngpaste" # For doom-emacs - needs macOS clipboard access
    "ollama" # If you prefer Homebrew version

    # Emacs with native-comp support via libgccjit.
    "emacs-plus@30"
  ];

  casks = [
    # GUI apps
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
  ];

  permissionSensitiveCasks = [
    # Keep out of Oxum's manual Brewfile: these have Accessibility/TCC grants
    # that were approved out-of-band on the work machine.
    "codex"
    "google-chrome"
    "hammerspoon"
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
