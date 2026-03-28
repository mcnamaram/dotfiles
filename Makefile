SHELL = /bin/bash
DOTFILES_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos linux)
PATH := $(DOTFILES_DIR)bin:$(PATH)
# Use $(shell …) here so GNU Make does not eat $(brew …) meant for the shell (see pyenv-defaults).
BREW_PREFIX := $(shell PATH="$(PATH):/opt/homebrew/bin:/usr/local/bin:/opt/homebrew/sbin:/usr/local/sbin" brew --prefix 2>/dev/null)
PYENV_EXE := $(shell PATH="$(PATH):/opt/homebrew/bin:/usr/local/bin:$(BREW_PREFIX)/bin" brew --prefix pyenv 2>/dev/null)/bin/pyenv
RUBY_BIN_PREFIX := $(shell PATH="$(PATH):/opt/homebrew/bin:/usr/local/bin:$(BREW_PREFIX)/bin" brew --prefix ruby 2>/dev/null)/bin
NVM_DIR := $(HOME)/.nvm
export XDG_CONFIG_HOME := $(HOME)/.config
export STOW_DIR := $(DOTFILES_DIR)

.PHONY: test zsh pyenv-defaults

all: $(OS)

macos: sudo core-macos packages link set-default-shell

linux: core-linux link set-default-shell

core-macos: brew bash git sdkman nvm ruby

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
	while true; do sudo -n true; sleep 240; kill -0 "$$" || exit; done 2>/dev/null &

packages: brew-packages pyenv-defaults sdkman cursor-exts node-packages gems python-packages aws

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
	@if is-executable brew; then :; \
	else \
	  NONINTERACTIVE=1 /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi
	@eval "$$([ -x /opt/homebrew/bin/brew ] && /opt/homebrew/bin/brew shellenv || /usr/local/bin/brew shellenv)"
	brew analytics off

bash: brew
	@BASH_PATH=$$(brew --prefix bash)/bin/bash; \
	if ! grep -qFx "$$BASH_PATH" /private/etc/shells 2>/dev/null; then \
	  brew install bash bash-completion@2 pcre pcre2; \
	  echo "$$BASH_PATH" | sudo tee -a /private/etc/shells >/dev/null; \
	fi

zsh: brew
	@ZSH_PATH=$$(brew --prefix zsh)/bin/zsh; \
	if ! grep -qFx "$$ZSH_PATH" /private/etc/shells 2>/dev/null; then \
	  brew install zsh zsh-completions pcre pcre2; \
	  echo "$$ZSH_PATH" | sudo tee -a /private/etc/shells >/dev/null; \
	fi

set-default-shell: bash
	@echo "Set bash as the default shell for the user"
	@PATH="$$(brew --prefix)/bin:$$PATH" chsh -s "$$(brew --prefix bash)/bin/bash"

git: brew
	brew install git

sdkman:
	@if [ -f "$$HOME/.sdkman/bin/sdkman-init.sh" ]; then \
	  :; \
	else \
	  curl -sL https://get.sdkman.io | bash; \
	fi

iterm2:
	curl -L https://iterm2.com/shell_integration/bash -o ~/.iterm2_shell_integration.bash && source ~/.iterm2_shell_integration.bash

nvm:
	if ! [ -d $(NVM_DIR)/.git ]; then git clone https://github.com/creationix/nvm.git $(NVM_DIR); fi
	. $(NVM_DIR)/nvm.sh; nvm install --lts --latest-npm

ruby: brew
	brew install ruby

brew-packages: brew
	brew bundle --file=$(DOTFILES_DIR)install/Brewfile
	@test -f $(DOTFILES_DIR)install/Brewfile.local && brew bundle --file=$(DOTFILES_DIR)install/Brewfile.local || true
	@-PREFIX=$$(brew --prefix); \
	KX=$$(brew --prefix kubectx); \
	if [ -x "$$KX/bin/kubectx" ]; then \
	  brew unlink kubectx 2>/dev/null || true; \
	  ln -sf "$$KX/bin/kubectx" "$$PREFIX/bin/kctx"; \
	  ln -sf "$$KX/bin/kubens" "$$PREFIX/bin/kns"; \
	  for c in kubectx kubens; do \
	    if [ -e "$$KX/etc/bash_completion.d/$$c" ]; then \
	      ln -sf "$$KX/etc/bash_completion.d/$$c" "$$PREFIX/etc/bash_completion.d/$$c"; \
	    fi; \
	  done; \
	fi

pyenv-defaults: brew-packages
	@export PATH="$(BREW_PREFIX)/bin:$$PATH"; \
	PYENV_ROOT="$${PYENV_ROOT:-$$HOME/.pyenv}"; export PYENV_ROOT; \
	eval "$$($(PYENV_EXE) init - bash)"; \
	$(PYENV_EXE) install -s 3.12; \
	$(PYENV_EXE) global 3.12

sdkman-jdk: sdkman
	$(shell . ~/.sdkman/bin/sdkman-init.sh && \
	sdk install java && \
	jdk_ver=$$(sdk current java | awk '{print $$NF}') && \
	sdk use java $$jdk_ver && \
	sdk default java $$jdk_ver)

cursor-exts: brew
	@-is-executable cursor && { \
	  LIST=$$(mktemp); \
	  cursor --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' | cut -d@ -f1 | sort -u >"$$LIST" || true; \
	  CODE_FILES="$(DOTFILES_DIR)install/Codefile"; \
	  test -f "$(DOTFILES_DIR)install/Codefile.local" && CODE_FILES="$$CODE_FILES $(DOTFILES_DIR)install/Codefile.local"; \
	  for EXT in $$(cat $$CODE_FILES | grep -v '^#' | grep -v '^[[:space:]]*$$'); do \
	    EXT_ID=$$(echo "$$EXT" | cut -d@ -f1 | tr '[:upper:]' '[:lower:]'); \
	    if grep -qFx "$$EXT_ID" "$$LIST" 2>/dev/null; then continue; fi; \
	    if ! NODE_OPTIONS='--no-deprecation' cursor --install-extension "$$EXT"; then \
	      curl -sSL "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$${EXT%%.*}/vsextensions/$${EXT##*.}/latest/vspackage" -o "$$EXT.vsix"; \
	      NODE_OPTIONS='--no-deprecation' cursor --install-extension "$$EXT.vsix"; \
	    fi; \
	  done; \
	  rm -f "$$LIST"; \
	}

node-packages: nvm
	. $(NVM_DIR)/nvm.sh; npm install --location global $(shell cat install/npmfile)

# install/Gemfile: one gem id per line; lines starting with # are ignored (do not use
# $(shell cat Gemfile) here — Make joins lines and a # comment makes the shell drop all args).
gems: ruby
	@PATH="$(RUBY_BIN_PREFIX):$$PATH"; \
	grep -v '^#' "$(DOTFILES_DIR)install/Gemfile" | grep -v '^[[:space:]]*$$' | while IFS= read -r g; do \
	  gem install "$$g"; \
	done

python-packages: pyenv-defaults
	@$(PYENV_EXE) exec python -m pip install -r $(DOTFILES_DIR)install/requirements.txt

aws: brew
	is-executable aws || brew install awscli
	brew link --overwrite awscli

test:
	@DOTFILES_DIR="$(CURDIR)" PATH="$(CURDIR)/bin:$(PATH)" bats test/*.bats
