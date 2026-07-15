#!/usr/bin/env bash

# Fix WSL/Windows hybrid env — HOME can leak from Windows %USERPROFILE%
if [[ "$HOME" == /c/Users/* ]]; then
  export HOME=/home/skully
fi

# Resolve DOTFILES_DIR
if [ -d "$HOME/.dotfiles" ]; then
  DOTFILES_DIR="$HOME/.dotfiles"
else
  echo "Unable to find dotfiles, exiting."
  return
fi

if [ -f "$DOTFILES_DIR/runcom/.setuprc" ]; then
  source "$DOTFILES_DIR/runcom/.setuprc"
fi
