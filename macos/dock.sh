#!/usr/bin/env bash

dockutil --no-restart --remove all
dockutil --no-restart --add "/Applications/Path Finder.app"
dockutil --no-restart --add "/Applications/Firefox.app"
dockutil --no-restart --add "/Applications/iTerm.app"
dockutil --no-restart --add "/Applications/Slack.app"
dockutil --no-restart --add "/Applications/Microsoft Outlook.app"

killall Dock
