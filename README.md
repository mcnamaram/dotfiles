# mcnamaram's dotfiles

> Originally forked from [Mathias's dotfiles](https://mths.be/dotfiles) and revamped with ideas from [webpro/dotfiles](https://github.com/webpro/dotfiles)

## Package overview

- [Homebrew](https://brew.sh) (packages: [Brewfile.macos](./install/Brewfile.macos) / [Brewfile.linux](./install/Brewfile.linux))
- [Node.js + npm LTS](https://nodejs.org/en/download/) (packages: [npmfile](./install/npmfile))
- Latest Git, Bash, Python 3, GNU coreutils, curl
- `$EDITOR` (and Git editor) is [Cursor](https://cursor.sh/) on macOS, `vim` on Linux/WSL

## Architecture

This is the **standard** (home) setup — TypeScript, Docker, KinD, Python, core tools.

Work-specific config lives in a separate private overlay repo (`dotfiles-work`) that layers on top via symlinked `.work` files. See [how it works](#work-overlay) below.

## Installation

**Warning:** Don't blindly use these settings. Always review the code.

On a sparkling fresh installation of macOS:

    sudo softwareupdate -i -a
    xcode-select --install

Then install with `curl`:

    bash -c "`curl -fsSL https://raw.githubusercontent.com/mcnamaram/dotfiles/main/remote-install.sh`"

Or clone manually:

    git clone https://github.com/mcnamaram/dotfiles.git ~/.dotfiles

The Makefile auto-detects macOS vs Linux. On Linux/WSL it runs `apt-get` instead of Homebrew and uses [Brewfile.linux](./install/Brewfile.linux) (no macOS casks). Use it to install everything and symlink configs (via [stow](https://www.gnu.org/software/stow/)):

    cd ~/.dotfiles
    make

## Secrets

Secrets are stored in macOS Keychain, never in plaintext files. Use the `secrets-manage` tool:

    secrets-manage set openai api-key        # prompts for value
    secrets-manage get openai api-key        # retrieves it
    secrets-manage list                      # shows all dotfiles-managed secrets

Shell startup reads secrets from Keychain automatically via `system/.secrets`.

## Work overlay

Work-specific config lives in a separate private repo. When present, it layers on top:

1. `.work` files in `system/` are sourced after standard files (can override functions)
2. Git config uses `[includeIf]` to apply work email/hooks only in work repos
3. Work packages install via a separate Brewfile in the overlay

To set up work on top of standard:

    git clone <private-overlay-repo> ~/.dotfiles-work
    cd ~/.dotfiles-work
    make work

## Post-install

**macOS only:** Open a new shell and run:

- `dotfiles dock` (set [Dock items](./macos/dock.sh))
- `dotfiles macos` (set [macOS defaults](./macos/defaults.sh))

## The `dotfiles` command

    $ dotfiles help
    Usage: dotfiles <command>

    Commands:
       clean            Clean up caches (brew, nvm)
       dock             Apply macOS Dock settings
       edit             Open dotfiles in IDE
       help             This help message
       macos            Apply macOS system defaults
       test             Run tests
       update           Update packages and pkg managers (OS, brew, npm)

## Additional resources

- [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)
- [Homebrew](https://brew.sh)
- [Bash prompt](https://wiki.archlinux.org/index.php/Color_Bash_Prompt)
- [Solarized Color Theme for GNU ls](https://github.com/seebi/dircolors-solarized)

## Credits

Many thanks to the [dotfiles community](https://dotfiles.github.io) and particularly Mathias and webpro.
