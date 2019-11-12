SHELL = /bin/bash
DOTFILES_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos linux)
PATH := $(DOTFILES_DIR)/bin:$(PATH)
NVM_DIR := $(HOME)/.nvm
export XDG_CONFIG_HOME := $(HOME)/.config
export STOW_DIR := $(DOTFILES_DIR)

.PHONY: test

all: $(OS)

macos: sudo core-macos packages link

linux: core-linux link

core-macos: brew bash git npm ruby python

core-linux:
	apt-get update
	apt-get upgrade -y
	apt-get dist-upgrade -f

stow-macos: brew
	is-executable stow || brew install stow

stow-linux: core-linux
	is-executable stow || apt-get -y install stow

sudo:
	sudo -v
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

packages: brew-packages jabba-jdk cask-apps node-packages gems python-packages opam

link: stow-$(OS)
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then mv -v $(HOME)/$$FILE{,.bak}; fi; done
	mkdir -p $(XDG_CONFIG_HOME)
	stow -t $(HOME) runcom
	stow -t $(XDG_CONFIG_HOME) config

unlink: stow-$(OS)
	stow --delete -t $(HOME) runcom
	stow --delete -t $(XDG_CONFIG_HOME) config
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE.bak ]; then mv -v $(HOME)/$$FILE.bak $(HOME)/$${FILE%%.bak}; fi; done

brew:
	is-executable brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install | ruby

bash: BASH=/usr/local/bin/bash
bash: SHELLS=/private/etc/shells
bash: brew
	if ! grep -q $(BASH) $(SHELLS); then brew install bash bash-completion@2 pcre pcre2 && sudo append $(BASH) $(SHELLS) && chsh -s $(BASH); fi
	if [ $(command -v kubectx) ]; then
	  brew unlink kubectx
	  version=$(brew info kubectx --json | jq -r '.[].versions.stable')
	  ln -s /usr/local/Cellar/kubectx/$version/bin/kubectx /usr/local/bin/kctx
	  ln -s /usr/local/Cellar/kubectx/$version/bin/kubens /usr/local/bin/kns
	  ln -s /usr/local/Cellar/kubectx/$version/etc/bash_completion.d/kubectx /usr/local/etc/bash_completion.d/kubectx
	  ln -s /usr/local/Cellar/kubectx/$version/etc/bash_completion.d/kubens /usr/local/etc/bash_completion.d/kubens
	fi

git: brew
	brew install git git-extras

jabba:
	curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash && . ~/.jabba/jabba.sh

npm:
	if ! [ -d $(NVM_DIR)/.git ]; then git clone https://github.com/creationix/nvm.git $(NVM_DIR); fi
	. $(NVM_DIR)/nvm.sh; nvm install --lts --latest-npm

ruby: brew
	brew install ruby

python: brew
	brew install python

brew-packages: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Brewfile

jabba-jdk: jabba
	jabba install zulu@1.8
	jabba alias default 1.8

cask-apps: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Caskfile
	#for EXT in $$(cat install/Codefile); do code --install-extension $$EXT; done
	#if is-executable subl; then curl -fsSL "https://packagecontrol.io/Package%20Control.sublime-package" > "$(HOME)/Library/Application Support/Sublime Text 3/Installed Packages/Package Control.sublime-package" && cp $(DOTFILES_DIR)/install/sublime-text/*.sublime-settings "$(HOME)/Library/Application Support/Sublime Text 3/Packages/User/";	fi

node-packages: npm
	. $(NVM_DIR)/nvm.sh; npm install -g $(shell cat install/npmfile)

gems: ruby
	export PATH="/usr/local/opt/ruby/bin:$PATH"; gem install $(shell cat install/Gemfile)

python-packages: python
	pip install -r install/requirements.txt

opam:
	opam init
	opam update
	opam install patdiff

test:
	bats test/*.bats
