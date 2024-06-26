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
