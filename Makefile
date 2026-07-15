SHELL := /bin/bash
DOTFILES_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos linux)
export PATH := $(DOTFILES_DIR)bin:$(PATH)
NVM_DIR := $(HOME)/.nvm
export XDG_CONFIG_HOME := $(HOME)/.config
export STOW_DIR := $(DOTFILES_DIR)

# Detect Homebrew prefix (Apple Silicon → Linuxbrew → Intel → none)
BREW_PREFIX := $(shell /opt/homebrew/bin/brew --prefix 2>/dev/null || \
	/home/linuxbrew/.linuxbrew/bin/brew --prefix 2>/dev/null || \
	/usr/local/bin/brew --prefix 2>/dev/null || echo /usr/local)
BASH := $(BREW_PREFIX)/bin/bash

# Ensure variables exported to recipe shells (e.g. PATH, HOMEBREW_*)
.EXPORT_ALL_VARIABLES:

.PHONY: all macos linux test packages packages-macos packages-linux \
	stow-macos stow-linux core-macos core-linux \
	brew bash-$(OS) git-$(OS) python-macos \
	sdkman nvm iterm2 aws secrets

# ── entry points ────────────────────────────────────────────────

all: $(OS)

macos: sudo core-macos packages-macos link bash-$(OS)

linux: sudo core-linux stow-linux packages-linux link bash-$(OS)

# ── platform-specific core setup ────────────────────────────────

core-macos: brew bash-macos git-macos sdkman nvm python-macos

core-linux:
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo apt-get dist-upgrade -f
	# Install nvm (needs curl from apt above)
	[ -d $(NVM_DIR)/.git ] || git clone https://github.com/nvm-sh/nvm.git $(NVM_DIR)
	. $(NVM_DIR)/nvm.sh && nvm install --lts --latest-npm 2>/dev/null || true

# ── stow ────────────────────────────────────────────────────────

stow-macos: brew
	is-executable stow || brew install stow

stow-linux:
	is-executable stow || sudo apt-get -y install stow

# ── sudo refresh ────────────────────────────────────────────────

sudo:
	sudo -v
	while true; do sudo -n true; sleep 240; kill -0 "$$" || exit; done 2>/dev/null &

# ── packages (platform split) ───────────────────────────────────

packages-macos: brew-packages node-packages

packages-linux: stow-linux
	sudo apt-get install -y curl wget git build-essential
	# Ensure nvm is installed before using it
	[ -d $(NVM_DIR)/.git ] || git clone https://github.com/nvm-sh/nvm.git $(NVM_DIR)
	. $(NVM_DIR)/nvm.sh && npm install --location global $$(cat install/npmfile)

# ── link / unlink ───────────────────────────────────────────────

link: stow-$(OS)
	for FILE in $$(ls -A runcom); do \
		if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
			mv -v $(HOME)/$$FILE{,.bak}; \
		fi; \
	done
	mkdir -p $(XDG_CONFIG_HOME)
	stow -t $(HOME) runcom
	stow -t $(XDG_CONFIG_HOME) config

unlink: stow-$(OS)
	stow --delete -t $(HOME) runcom
	stow --delete -t $(XDG_CONFIG_HOME) config
	for FILE in $$(ls -A runcom); do \
		if [ -f $(HOME)/$$FILE.bak ]; then \
			mv -v $(HOME)/$$FILE.bak $(HOME)/$${FILE%%.bak}; \
		fi; \
	done

# ── brew ────────────────────────────────────────────────────────

brew:
	is-executable brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash
	export "$$( $(BREW_PREFIX)/bin/brew shellenv )"
	brew analytics off

# ── bash (platform split) ───────────────────────────────────────

bash-macos: brew
	@echo "Set bash as the default shell for the user"
	if ! grep -q $(BASH) /private/etc/shells; then \
		brew install bash bash-completion@2 pcre pcre2 && \
		sudo tee -a /private/etc/shells <<<$(BASH); \
	fi
	chsh -s $(BASH)

bash-linux:
	@echo "Set bash as the default shell for the user"
	which bash >/dev/null 2>&1 || { echo "bash is required"; exit 1; }
	chsh -s /bin/bash

# ── git (platform split) ────────────────────────────────────────

git-macos: brew
	brew install git

git-linux:
	which git >/dev/null 2>&1 || sudo apt-get -y install git

# ── python ────────────────────────────────────────────────────────

python-macos: brew
	brew install python@3.12

# ── shared tools ────────────────────────────────────────────────

brew-packages: brew
	brew bundle --file=$(DOTFILES_DIR)install/Brewfile.$(OS)

sdkman:
	curl -sL https://get.sdkman.io | bash && source ~/.sdkman/bin/sdkman-init.sh

iterm2:
	curl -L https://iterm2.com/shell_integration/bash -o ~/.iterm2_shell_integration.bash && \
	source ~/.iterm2_shell_integration.bash

nvm:
	if ! [ -d $(NVM_DIR)/.git ]; then git clone https://github.com/nvm-sh/nvm.git $(NVM_DIR); fi
	. $(NVM_DIR)/nvm.sh && nvm install --lts --latest-npm 2>/dev/null || true

sdkman-jdk: sdkman
	. ~/.sdkman/bin/sdkman-init.sh && \
	echo y | sdk install java && \
	jdk_ver=$$(sdk current java | awk '{print $$NF}') && \
	sdk use java $$jdk_ver && \
	sdk default java $$jdk_ver

node-packages: nvm
	. $(NVM_DIR)/nvm.sh && npm install --location global $$(cat install/npmfile)

aws: brew
	is-executable aws || brew install awscli
	brew link --overwrite awscli

secrets:
	@echo "Run secrets-manage to store shell secrets in keyring."
	@echo "  secrets-manage set openai api-key"
	@echo "  secrets-manage set github personal-token"
	@echo "Or bulk import: secrets-manage import setup/secrets.list"

test:
	bats test/*.bats
