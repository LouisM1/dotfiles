#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="$HOME"
dry_run=false
skip_deps=false
package_file=""
usage() {
  cat <<'HELP'
Usage: ./install.sh [--dry-run] [--packages | --full-packages] [--skip-deps] [--target DIRECTORY]

Install pinned shell/plugin dependencies and link the saved configuration.
Existing configuration files are moved to a timestamped backup first.
  --dry-run        Show actions without changing anything or using the network.
  --packages       Also install core tools and Ghostty using Homebrew.
  --full-packages  Also restore the wider Homebrew list (including large GUI apps).
  --skip-deps      Only link configuration; dependencies must already exist.
  --target DIR     Install configuration/dependencies into DIR instead of your home.
                  Package installation still affects the current machine.
HELP
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) dry_run=true ;;
    --packages) package_file="$repo_dir/Brewfile" ;;
    --full-packages) package_file="$repo_dir/Brewfile.full" ;;
    --skip-deps) skip_deps=true ;;
    --target) [[ $# -ge 2 ]] || { usage; exit 2; }; target_dir="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage; exit 2 ;;
  esac
  shift
done
[[ "$target_dir" = /* && "$target_dir" != / ]] || { echo 'Target must be an absolute directory other than /.' >&2; exit 2; }
backup_dir="$target_dir/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)-$$"
run() {
  if "$dry_run"; then printf 'Would run:'; printf ' %q' "$@"; printf '\n'; else "$@"; fi
}
backup() {
  local relative="$1" destination="$target_dir/$1"
  if [[ -e "$destination" || -L "$destination" ]]; then
    printf 'Backing up %s\n' "$destination"
    run mkdir -p "$(dirname "$backup_dir/$relative")"
    run mv "$destination" "$backup_dir/$relative"
  fi
}
link_file() {
  local source="$repo_dir/$1" relative="$2" destination="$target_dir/$2"
  if [[ -L "$destination" && "$(readlink "$destination")" = "$source" ]]; then
    printf 'Already linked: %s\n' "$relative"
    return
  fi
  backup "$relative"
  run mkdir -p "$(dirname "$destination")"
  run ln -s "$source" "$destination"
}

if [[ -n "$package_file" ]]; then
  brew_cmd="$(command -v brew || true)"
  [[ -n "$brew_cmd" ]] || { [[ ! -x /opt/homebrew/bin/brew ]] || brew_cmd=/opt/homebrew/bin/brew; }
  [[ -n "$brew_cmd" ]] || { [[ ! -x /usr/local/bin/brew ]] || brew_cmd=/usr/local/bin/brew; }
  if [[ -z "$brew_cmd" ]] && ! "$dry_run"; then
    echo 'Install Homebrew from https://brew.sh first, then rerun this command.' >&2
    exit 1
  fi
  run "${brew_cmd:-brew}" bundle install --file="$package_file"
  # Ghostty was installed outside Homebrew on the source laptop.
  if [[ "$package_file" = "$repo_dir/Brewfile.full" ]]; then
    run "${brew_cmd:-brew}" bundle install --file="$repo_dir/Brewfile"
  fi
fi

if ! "$skip_deps"; then
  command -v git >/dev/null || { echo 'Git is required. Run xcode-select --install on a new Mac.' >&2; exit 1; }
  while IFS=$'\t' read -r relative url commit; do
    [[ -n "$relative" && "$relative" != \#* ]] || continue
    destination="$target_dir/$relative"
    if [[ -e "$destination" || -L "$destination" ]]; then
      # Never reset, overwrite or delete an existing dependency checkout.
      existing_commit="$(git -C "$destination" rev-parse HEAD 2>/dev/null || true)"
      if [[ "$existing_commit" = "$commit" ]]; then
        printf 'Keeping existing dependency: %s (matches recorded commit)\n' "$relative"
      else
        printf 'Keeping existing dependency: %s (version differs; review dependencies.tsv)\n' "$relative"
      fi
      continue
    fi
    printf 'Installing %s at %s\n' "$relative" "$commit"
    if "$dry_run"; then
      printf 'Would clone %s and check out %s\n' "$url" "$commit"
    else
      mkdir -p "$(dirname "$destination")"
      staging="$(mktemp -d "${destination}.install.XXXXXX")"
      if git clone --quiet --no-checkout "$url" "$staging" && git -C "$staging" checkout --quiet --detach "$commit"; then
        mv "$staging" "$destination"
      else
        printf 'Dependency installation failed. Partial checkout kept at %s\n' "$staging" >&2
        exit 1
      fi
    fi
  done < "$repo_dir/dependencies.tsv"
fi

link_file zsh/zprofile .zprofile
link_file zsh/zshrc .zshrc
link_file zsh/p10k.zsh .p10k.zsh
link_file tmux/tmux.conf .tmux.conf
link_file git/gitconfig .gitconfig
link_file git/ignore .config/git/ignore
# A newer Ghostty filename could otherwise override this restored config.
backup 'Library/Application Support/com.mitchellh.ghostty/config.ghostty'
link_file ghostty/config 'Library/Application Support/com.mitchellh.ghostty/config'

printf '\nConfiguration ready. Keep this repository in place: the settings are linked to it.\n'
printf 'Any replaced files are preserved under %s\n' "$backup_dir"
printf 'Open a new Ghostty window. See README.md for language runtimes and optional tools.\n'
