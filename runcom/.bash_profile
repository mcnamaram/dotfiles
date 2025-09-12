#!/usr/bin/env bash

# If not running interactively, don't do anything
case "$-" in
*i*) ;;
*) return ;;
esac

# Source the .bashrc file if it exists
if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
# shellcheck disable=SC1091
[ -f "$HOME/.dotfiles/system/.sdkman" ] && source "$HOME/.dotfiles/system/.sdkman"
