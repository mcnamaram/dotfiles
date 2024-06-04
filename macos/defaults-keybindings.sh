#!/usr/bin/env bash

# https://www.maketecheasier.com/fix-home-end-button-for-external-keyboard-mac/

mkdir -p "$HOME/Library/KeyBindings"
for f in "$DOTFILES_DIR/config/keybindings/*.dict"; do cp "$f" "$HOME/Library/KeyBindings/"; done
