#!/usr/bin/env bash

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

# Task Master aliases added on 12/30/2025
alias tm='task-master'
alias taskmaster='task-master'
alias hamster='task-master'
alias ham='task-master'
