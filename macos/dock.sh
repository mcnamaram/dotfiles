#!/usr/bin/env bash

dockutil --no-restart --remove all
dockutil --no-restart --add "/Applications/Path Finder.app"
dockutil --no-restart --add "/Applications/iTerm.app"
dockutil --no-restart --add "/Applications/Chrome.app"
dockutil --no-restart --add "/Applications/Slack.app"
dockutil --no-restart --add "/Applications/Microsoft Outlook.app"
dockutil --no-restart --add "/Applications/Microsoft To Do.app"
dockutil --no-restart --add "/Applications/Microsoft Teams (work or school).app"
dockutil --no-restart --add "/Applications/Spotify.app"

killall Dock
