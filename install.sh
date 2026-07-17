#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_ZSHRC="$SCRIPT_DIR/.zshrc"
readonly OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
readonly ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}"

install_requirements() {
  local required=(curl git zsh bat)
  local missing=()
  local command_name

  make_bat_available() {
    if command -v bat >/dev/null 2>&1 || ! command -v batcat >/dev/null 2>&1; then
      return
    fi

    mkdir -p "$HOME/.local/bin"
    if [[ -e "$HOME/.local/bin/bat" || -L "$HOME/.local/bin/bat" ]]; then
      printf 'Error: %s exists but the bat command is unavailable.\n' \
        "$HOME/.local/bin/bat" >&2
      exit 1
    fi

    ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
    export PATH="$PATH:$HOME/.local/bin"
    hash -r
  }

  make_bat_available

  for command_name in "${required[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      missing+=("$command_name")
    fi
  done

  if (( ${#missing[@]} == 0 )); then
    return
  fi

  printf 'Installing required packages: %s\n' "${missing[*]}"

  if [[ "$(uname -s)" == Darwin ]]; then
    if ! command -v brew >/dev/null 2>&1; then
      if [[ ! -x /usr/bin/curl ]]; then
        printf 'Error: /usr/bin/curl is needed to install Homebrew.\n' >&2
        exit 1
      fi

      printf 'Homebrew is not installed; installing it now...\n'
      NONINTERACTIVE=1 /bin/bash -c \
        "$(/usr/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi

    if ! command -v brew >/dev/null 2>&1; then
      printf 'Error: Homebrew was installed but could not be found in PATH.\n' >&2
      exit 1
    fi

    brew install "${missing[@]}"
  else
    if ! command -v apt-get >/dev/null 2>&1; then
      printf 'Error: apt-get is required on non-macOS systems.\n' >&2
      exit 1
    fi

    local apt_command=(apt-get)
    if (( EUID != 0 )); then
      if ! command -v sudo >/dev/null 2>&1; then
        printf 'Error: sudo is required to install packages with apt.\n' >&2
        exit 1
      fi
      apt_command=(sudo apt-get)
    fi

    "${apt_command[@]}" update
    "${apt_command[@]}" install -y "${missing[@]}"
  fi

  hash -r
  make_bat_available
  for command_name in "${required[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
      printf 'Error: %s is still unavailable after installation.\n' "$command_name" >&2
      exit 1
    fi
  done
}

if [[ ! -f "$SOURCE_ZSHRC" ]]; then
  printf 'Error: %s was not found.\n' "$SOURCE_ZSHRC" >&2
  exit 1
fi

install_requirements

if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
  printf 'Installing Oh My Zsh...\n'
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  printf 'Oh My Zsh is already installed at %s; skipping.\n' "$OH_MY_ZSH_DIR"
fi

mkdir -p "$ZSH_CUSTOM_DIR/plugins"

install_plugin() {
  local name="$1"
  local repository="$2"
  local destination="$ZSH_CUSTOM_DIR/plugins/$name"

  if [[ -d "$destination/.git" ]]; then
    printf 'Plugin %s is already installed; skipping.\n' "$name"
    return
  fi

  if [[ -e "$destination" ]]; then
    printf 'Error: %s exists but is not a Git repository.\n' "$destination" >&2
    exit 1
  fi

  printf 'Installing plugin %s...\n' "$name"
  git clone --depth=1 "$repository" "$destination"
}

install_plugin \
  zsh-autosuggestions \
  https://github.com/zsh-users/zsh-autosuggestions.git
install_plugin \
  zsh-syntax-highlighting \
  https://github.com/zsh-users/zsh-syntax-highlighting.git

if [[ -e "$HOME/.zshrc" || -L "$HOME/.zshrc" ]]; then
  if cmp -s "$SOURCE_ZSHRC" "$HOME/.zshrc"; then
    printf '%s is already installed; no replacement needed.\n' "$HOME/.zshrc"
    printf 'Installation complete. Restart Zsh or run: exec zsh\n'
    exit 0
  fi

  backup="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S).$$"
  cp -Pp "$HOME/.zshrc" "$backup"
  printf 'Backed up the existing .zshrc to %s\n' "$backup"
fi

rm -f "$HOME/.zshrc"
cp "$SOURCE_ZSHRC" "$HOME/.zshrc"

printf 'Installed %s as %s\n' "$SOURCE_ZSHRC" "$HOME/.zshrc"
printf 'Installation complete. Restart Zsh or run: exec zsh\n'
