#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: new-nix-project [--overwrite] [PROJECT_DIR]

Initialize a Nix + direnv project and copy AI project setup preferences.

Arguments:
  PROJECT_DIR    Directory to initialize. Defaults to the current directory.

Options:
  --overwrite    Replace an existing PROJECT_SETUP_PREFERENCES.md.
  -h, --help     Show this help.
EOF
}

overwrite=0
project_dir="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --overwrite)
      overwrite=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ "$project_dir" != "." ]]; then
        echo "Only one PROJECT_DIR is supported." >&2
        usage >&2
        exit 2
      fi
      project_dir="$1"
      shift
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd "$script_dir/.." && pwd -P)"
template_file="$repo_root/templates/ai/PROJECT_SETUP_PREFERENCES.md"

if [[ ! -f "$template_file" ]]; then
  echo "Template not found: $template_file" >&2
  exit 1
fi

mkdir -p "$project_dir"
project_dir="$(cd "$project_dir" && pwd -P)"

if [[ -e "$project_dir/flake.nix" ]]; then
  echo "flake.nix already exists in $project_dir; refusing to overwrite." >&2
  exit 1
fi

if [[ -e "$project_dir/PROJECT_SETUP_PREFERENCES.md" && "$overwrite" -ne 1 ]]; then
  echo "PROJECT_SETUP_PREFERENCES.md already exists in $project_dir; use --overwrite to replace it." >&2
  exit 1
fi

(
  cd "$project_dir"
  nix flake init -t github:nix-community/nix-direnv
  cp "$template_file" PROJECT_SETUP_PREFERENCES.md
  direnv allow
)

echo "Initialized $project_dir"
