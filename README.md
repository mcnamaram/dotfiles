# mcnamaram's dotfiles

> (originally forked from [Mathias’s dotfiles](https://mths.be/dotfiles)) and revamped with ideas from [webpro/dotfiles](https://github.com/webpro/dotfiles)

## Package overview

- [Homebrew](https://brew.sh) (packages: [Brewfile](./install/Brewfile))
- [homebrew-cask](https://formulae.brew.sh/cask/) (packages: [Caskfile](./install/Caskfile))
- [Node.js + npm LTS](https://nodejs.org/en/download/) (packages: [npmfile](./install/npmfile))
- Latest Ruby (packages: [Gemfile](./install/Gemfile))
- Latest Git, Bash, Python 3, GNU coreutils, curl
- `$EDITOR` (and Git editor) is [Sublime Text 3](https://www.sublimetext.com/)

## Installation

This targets macOS but with some apt-get should be fine for \*nix.

**Warning:** Don’t blindly use these settings. Always review the code and understand what you are getting into. Check these references for help:

    * Lars Kappert [Getting Started With Dotfiles](https://medium.com/@webprolific/getting-started-with-dotfiles-43c3602fd789)
    * Thoughtbot [Intro to Dotfiles](https://thoughtbot.com/upcase/videos/intro-to-dotfiles)
    * ArchWiki [Dotfiles](https://wiki.archlinux.org/index.php/Dotfiles)

_Use at your own risk!_  And please, _please_, triple check to not check in api-keys, passwords, and anything else sensitive that might linger in your configs.

On a sparkling fresh installation of macOS:

    sudo softwareupdate -i -a
    xcode-select --install

The Xcode Command Line Tools includes `git` and `make` (not available on stock macOS).
Then, install this repo with `curl` available:

    bash -c "`curl -fsSL https://raw.githubusercontent.com/mcnamaram/dotfiles/master/remote-install.sh`"

This will clone (using `git`), or download (using `curl` or `wget`), this repo to `~/.dotfiles`. Alternatively, clone manually into the desired location:

    git clone https://github.com/mcnamaram/dotfiles.git ~/.dotfiles

Use the [Makefile](./Makefile) to install everything [listed above](#package-overview), and symlink [runcom](./runcom) and [config](./config) (using [stow](https://www.gnu.org/software/stow/)):

    cd ~/.dotfiles
    make

## Everything else

Alternatively, you can have an additional, personal dotfiles repo at `~/.extra`. The runcom `.bash_profile` sources all `~/.extra/runcom/*.sh` files.

My `~/.extra/runcom/custom.sh` looks something like this:

    # Git credentials
    # Not in the repository, to prevent people from accidentally committing under my name
    GIT_AUTHOR_NAME="Michael McNamara"
    GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
    git config --global user.name "$GIT_AUTHOR_NAME"
    GIT_AUTHOR_EMAIL="mcnamaram@example.com"
    GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
    git config --global user.email "$GIT_AUTHOR_EMAIL"

You could also use `~/.extra/runcom` scripts to override settings, functions, and aliases from my dotfiles repository. It’s probably better to [fork this repository](https://github.com/mcnamaram/dotfiles/fork) instead, though.

### ssshhh...and use a keepass or something

You can put your custom secret settings, such as Git credentials in the `system/.secrets` file which will be sourced from `.bash_profile` automatically. This file is in `.gitignore`.

## Post-install

Open a new shell and run:

- `dotfiles dock` (set [Dock items](./macos/dock.sh))
- `dotfiles macos` (set [macOS defaults](./macos/defaults.sh))

## The `dotfiles` command

    $ dotfiles help
    Usage: dotfiles <command>

    Commands:
       clean            Clean up caches (brew, npm, gem, rvm)
       dock             Apply macOS Dock settings
       edit             Open dotfiles in IDE (code) and Git GUI (stree)
       help             This help message
       macos            Apply macOS system defaults
       test             Run tests
       update           Update packages and pkg managers (OS, brew, npm, gem)

## Additional resources

- [Awesome Dotfiles](https://github.com/webpro/awesome-dotfiles)
- [Homebrew](https://brew.sh)
- [Homebrew Cask](http://caskroom.io)
- [Bash prompt](https://wiki.archlinux.org/index.php/Color_Bash_Prompt)
- [Solarized Color Theme for GNU ls](https://github.com/seebi/dircolors-solarized)

## Credits

Many thanks to the [dotfiles community](https://dotfiles.github.io) and particularly Mathias and webpro.
