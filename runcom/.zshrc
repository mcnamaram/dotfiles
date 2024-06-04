#!/usr/bin/env zsh

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
