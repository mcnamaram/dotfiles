#!/usr/bin/env bash

# If not running interactively, don't do anything

[ -z "$PS1" ] && return

# else
source $HOME/.bash_profile;

[ -s "/Users/mcnamaram2/.jabba/jabba.sh" ] && source "/Users/mcnamaram2/.jabba/jabba.sh"
