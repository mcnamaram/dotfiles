# Dotfiles Restructure Design — Work vs Standard Split

**Date:** 2026-04-01
**Author:** Michael McNamara (with AI assist)
**Status:** Implemented

---

## Problem Statement

The dotfiles repo (`mcnamaram/dotfiles`) is a single public repo that contains both personal/home development config and work-specific tooling. Work artifacts (API tokens, internal repo references, commit hooks, work-only packages, employer-specific functions) are entangled with standard home dev config. This creates:

- **Security risk:** Plaintext secrets in `system/.secrets`, work email/config in tracked files.
- **Noise:** 144 Brewfile entries and 117 VS Code extensions when ~50% are work-only.
- **Compromising content:** References to internal employer repos, tooling, and infrastructure in a public GitHub repo.
- **Arch mismatch:** Intel paths hardcoded in Makefile while current work laptop is Apple Silicon.
- **Stale code:** Commented-out rbenv, missing jabba target, dead zsh files, deprecated packages.

## Decision

**Two repos with overlay pattern.**

- **Standard repo** (`mcnamaram/dotfiles`, public): Clean home dev setup. TypeScript, Docker, KinD, Python, core UNIX tools. No work artifacts.
- **Work overlay repo** (private): Small delta repo with work-only packages, functions, secrets, git config, and hooks. Layers on top of standard via symlinks and shell sourcing.

## Architecture

### Repo Structure

#### Standard Repo (`mcnamaram/dotfiles`)

```
dotfiles/
├── bin/
│   ├── dotfiles              # CLI tool
│   ├── secrets-manage        # Keychain CRUD for shell secrets
│   ├── git-ci
│   ├── is-executable
│   ├── is-macos
│   ├── is-supported
│   ├── json, append, plistbuddy, set-config
│   └── ...
├── config/
│   └── git/
│       ├── config            # user.email = noreply, [includeIf] for work
│       ├── hooks/            # empty (.gitkeep)
│       ├── ignore
│       └── attributes
├── install/
│   ├── Brewfile              # standard-only packages
│   ├── Codefile              # standard-only extensions
│   └── npmfile               # npm-check-updates only
├── macos/
│   ├── defaults.sh
│   ├── defaults-chrome.sh
│   ├── defaults-keybindings.sh
│   └── dock.sh
├── runcom/
│   ├── .bash_profile
│   ├── .bashrc               # clean — no work aliases or secrets
│   ├── .setuprc              # sources system/*, then *.work, then ~/.extra
│   ├── .inputrc
│   └── .hushlogin
├── system/
│   ├── .alias                # standard aliases only
│   ├── .alias.macos
│   ├── .completion
│   ├── .dir_colors
│   ├── .direnv
│   ├── .env
│   ├── .env.macos
│   ├── .function             # core functions
│   ├── .function_ai          # empty or home AI helpers
│   ├── .function_fs
│   ├── .function_kube        # KinD only
│   ├── .function_network
│   ├── .function_text
│   ├── .grep
│   ├── .iterm
│   ├── .nvm
│   ├── .path
│   ├── .prompt_bash
│   ├── .pyenv
│   ├── .sdkman
│   └── .secrets              # Keychain reads only (no plaintext)
├── test/
│   ├── bin.bats
│   └── function.bats
├── Makefile                  # arch-aware, no jabba/zsh/gems
├── remote-install.sh
├── .gitignore                # includes *.work exclusions
├── .editorconfig
├── LICENSE-MIT.txt
└── README.md
```

**Deleted from standard:**

- `runcom/.zshrc`, `runcom/.zprofile`, `system/.prompt_zsh` (don't use zsh)
- `system/.rbenv` (entirely commented out)
- `install/Gemfile` (don't use Ruby)
- `install/requirements.txt` (work-only content)
- `config/git/hooks/commit-msg` (JIRA hook moves to work overlay)
- `config/pgcli/` (work database tooling, moves to overlay)

#### Work Overlay Repo (private)

```
dotfiles-work/
├── install/
│   ├── Brewfile.work          # work-only brew packages
│   ├── Codefile.work          # work-only VS Code extensions
│   └── npmfile.work           # work-only global npm
├── system/
│   ├── .function_ai.work      # work AI helpers
│   ├── .function_aws.work     # AWS SSO, ECR, profile resolution
│   ├── .alias.work            # work shortcuts
│   └── .secrets.work          # work Keychain exports
├── config/
│   └── git/
│       ├── config.work        # [user] work email, [core] hooksPath
│       └── hooks/
│           └── commit-msg     # ticket enforcement
├── setup/
│   ├── bootstrap.sh           # first-run: store work secrets in Keychain
│   └── secrets.list           # service/account/description for bootstrap
├── Makefile                   # `make work` = standard + overlay
└── README.md
```

### Layering Mechanism

#### `.setuprc` source order (standard repo)

```bash
# 1. Source standard system files (skip *.work files)
for DOTFILE in "$DOTFILES_DIR"/system/.{env,function,function_*,path,alias,grep,completion,prompt_bash,nvm,iterm,pyenv,direnv,secrets,sdkman}; do
  [[ -f "$DOTFILE" && "$DOTFILE" != *.work ]] && source "$DOTFILE"
done

# 2. macOS-specific standard files
if is-macos; then
  for DOTFILE in "$DOTFILES_DIR"/system/.{env,alias,function,path}.macos; do
    [ -f "$DOTFILE" ] && source "$DOTFILE"
  done
fi

# 3. Source .work overrides (from overlay, symlinked into system/)
for DOTFILE in "$DOTFILES_DIR"/system/.*.work; do
  [ -f "$DOTFILE" ] && source "$DOTFILE"
done

# 4. Source ~/.extra (existing hook)
```

Work `.work` files are sourced after standard, so they can override or extend functions.

#### Work overlay `make work` (overlay Makefile)

```make
STANDARD_REPO := https://github.com/mcnamaram/dotfiles.git
STANDARD_DIR := $(HOME)/.dotfiles
OVERLAY_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

work: standard overlay-link overlay-packages overlay-secrets

standard:
	@if [ ! -d "$(STANDARD_DIR)" ]; then \
	    git clone $(STANDARD_REPO) $(STANDARD_DIR); \
	else \
	    git -C $(STANDARD_DIR) pull --rebase || true; \
	fi
	$(MAKE) -C $(STANDARD_DIR)

overlay-link:
	@for f in $(OVERLAY_DIR)system/.*.work; do \
	    [ -f "$$f" ] && ln -sf "$$f" $(STANDARD_DIR)/system/; \
	done

overlay-packages:
	brew bundle --file=$(OVERLAY_DIR)install/Brewfile.work
	# extensions, npm globals, etc.

overlay-secrets:
	$(OVERLAY_DIR)setup/bootstrap.sh
```

#### Git config conditional includes (standard repo)

```ini
[user]
    name = Michael McNamara
    email = mcnamaram@users.noreply.github.com

[includeIf "hasconfig:remote.*.url:*<employer>*"]
    path = ~/.dotfiles-work/config/git/config.work
```

Work `config.work`:

```ini
[user]
    email = <work-email>
[core]
    hooksPath = ~/.dotfiles-work/config/git/hooks
```

Result: work email and commit hooks apply only in employer repos. Home repos use noreply email and no hook.

## Secrets Management

### `bin/secrets-manage`

General-purpose Keychain CRUD tool. Lives in standard repo.

```
Usage: secrets-manage <command> <service> [account]

Commands:
  set <service> <account>     Store a secret (prompts for value)
  get <service> <account>     Retrieve a secret
  delete <service> <account>  Remove a secret
  list                        List all dotfiles-managed secrets
  import <file>               Bulk import from secrets.list format
```

All entries use `dotfiles:` prefix in the Keychain service name for easy filtering.

### `system/.secrets` (standard)

```bash
#!/usr/bin/env bash
_secret() { security find-generic-password -s "dotfiles:$1" -a "$2" -w 2>/dev/null; }

export OPENAI_API_KEY="$(_secret 'openai' 'api-key')"
export GITHUB_TOKEN="$(_secret 'github' 'personal-token')"

unset -f _secret
```

### `system/.secrets.work` (overlay)

```bash
#!/usr/bin/env bash
_secret() { security find-generic-password -s "dotfiles:$1" -a "$2" -w 2>/dev/null; }

export WORK_API_TOKEN="$(_secret '<service>' '<account>')"
# ... additional work secrets

unset -f _secret
```

No plaintext secrets anywhere in either repo.

## Package Audit Summary

### Standard Brewfile

Core UNIX tools, shell, git, Docker, KinD, Python toolchain, Go, and essential casks (1Password, VS Code, iTerm2, etc.). ~54 entries total.

### Work Brewfile.work

CI/CD tools (ArgoCD, Helm, Kustomize, Testkube), language toolchains (Gradle, Maven, Scala), database tools (pgcli, libpq, kcat), infra tools (Terraform, Terragrunt), testing (k6, JMeter, Hoverfly), and work-specific casks. ~34 entries total.

### Extensions

- **Standard Codefile:** ~40 extensions — editor essentials, Docker, Kubernetes, Python, Bash, Git, Markdown, TypeScript.
- **Work Codefile.work:** ~45 extensions — Java/Kotlin/Scala, Spring Boot, AWS, Angular, Terraform, Jupyter, SQL, data tools.

### Other package lists

| List             | Standard            | Work | Cut                    |
| ---------------- | ------------------- | ---- | ---------------------- |
| npmfile          | `npm-check-updates` | `nx` | `dotenv` (project dep) |
| Gemfile          | (deleted)           | —    | `rake`, `rdoc`         |
| requirements.txt | (deleted)           | —    | `awscli-local`         |

## Makefile Changes (Standard Repo)

### Fixes

- Arch-aware brew prefix: detect `/opt/homebrew` vs `/usr/local` dynamically
- Remove `jabba-jdk` from `packages` dependency
- Remove `zsh` from `core-macos`
- Remove `gems` target and `install/Gemfile`
- Remove `python-packages` target
- Fix `bash` target to use detected `BREW_PREFIX` instead of hardcoded `/usr/local/bin/bash`
- Add `secrets` target to run initial Keychain setup

### New/changed targets

- `make` (default) — installs standard packages, links, sets shell
- `make secrets` — runs `secrets-manage import` for home secrets
- `make clean` — existing cleanup

## Dead Code Removal

| Item                                               | Action                     |
| -------------------------------------------------- | -------------------------- |
| `runcom/.zshrc`, `.zprofile`                       | Delete                     |
| `system/.prompt_zsh`                               | Delete                     |
| `system/.rbenv`                                    | Delete                     |
| `install/Gemfile`                                  | Delete                     |
| `install/requirements.txt`                         | Delete                     |
| Makefile `zsh`, `gems`, `python-packages` targets  | Remove                     |
| Makefile `jabba-jdk` in `packages`                 | Remove                     |
| `.alias` gradle/intellij aliases                   | Move to work `.alias.work` |
| `.alias` minikube aliases (`minienv`, `deminienv`) | Delete                     |
| `.alias` dead `~/.functions` reference             | Delete                     |
| `.function_kube` `ministart`, `minidie`            | Delete                     |
| `.function_network` `srv()`                        | Delete (dead dependency)   |
| `config/git/config` `sopsdiffer` section           | Delete                     |
| `config/git/config` `init.defaultBranch = develop` | Change to `main`           |
| `config/pgcli/`                                    | Move to work overlay       |

## Implementation Phases

### Phase 1: Standard Repo — Structure & Secrets

- `bin/secrets-manage` tool
- `system/.secrets` rewrite (Keychain)
- Makefile fixes (arch, dead targets)
- Delete dead files (zsh, rbenv, Gemfile)
- Clean tracked files of work content
- Git config (noreply email, includeIf, defaultBranch=main)
- .gitignore updates
- .setuprc overlay sourcing
- README fixes

### Phase 2: Standard Repo — Package Trim

- Rewrite Brewfile (standard only)
- Rewrite Codefile (standard only)
- Clean npmfile
- Delete Gemfile, requirements.txt
- Update Makefile targets

### Phase 3: Work Overlay Repo — Bootstrap

- Create private repo
- Overlay structure and Makefile
- Work system files
- Work git config and hooks
- Work package lists
- Bootstrap script for Keychain secrets

### Phase 4: Migration & Cleanup

- Migrate plaintext secrets to Keychain
- Verify all exports
- Run bats tests
- Final README updates
- Git history rewrite to remove work content

## Risks

- **Keychain prompts:** On first use after reboot, macOS may prompt for Keychain access. The `2>/dev/null` suppression handles this gracefully (exports are empty until unlocked).
- **Stow conflicts:** Symlinked `.work` files in `system/` are not stow-managed. Stow only manages `runcom/` and `config/`. The `.work` files are direct symlinks from the overlay — stow won't touch them.
- **Git history:** Previously committed work content exists in public git history. A force-push rewrite can clean this (implemented in Phase 4).
