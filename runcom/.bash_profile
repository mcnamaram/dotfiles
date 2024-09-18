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
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
