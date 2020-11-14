#!/usr/bin/env bash

# https://www.maketecheasier.com/fix-home-end-button-for-external-keyboard-mac/

mkdir -p "$HOME/Library/KeyBindings"
cp "$HOME/.config/keybindings/*.dict" "$HOME/Library/KeyBindings/"
