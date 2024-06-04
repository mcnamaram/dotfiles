#!/usr/bin/env zsh

# If not running interactively, don't do anything
case "$-" in
*i*) ;;
*) return ;;
esac

# Source the .bashrc file if it exists
if [ -f "$HOME/.zshrc" ]; then
  source "$HOME/.zshrc"
fi
