# Dotfiles Migration Guide — Home Laptop Setup

> Steps for setting up the Intel Mac Pro at home.
> Delete this file once complete.

---

## 1. Re-clone the repo

The git history was rewritten (force-pushed). Delete the old clone and start fresh:

```bash
rm -rf ~/.dotfiles
git clone git@github.com:mcnamaram/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

---

## 2. Run the standard install

```bash
make
```

This will:

- Install Homebrew (if missing)
- Install all standard Brewfile packages
- Install VS Code extensions from Codefile
- Install global npm packages
- Set up bash as the default shell
- Stow runcom and config symlinks

---

## 3. Set up secrets in Keychain

```bash
secrets-manage set openai api-key
# paste your OPENAI_API_KEY when prompted

secrets-manage set github personal-token
# paste your GITHUB_TOKEN when prompted
```

Verify:

```bash
source ~/.bashrc
echo $OPENAI_API_KEY    # should show value
echo $GITHUB_TOKEN      # should show value
secrets-manage list     # should show both entries
```

---

## 4. Uninstall removed packages

These packages were removed from the standard Brewfile. Uninstall them to clean up:

### Brew formulae

```bash
brew uninstall automake blackbox bzt cmake cython doxygen ffmpeg gcc glib \
  gnutls graphicsmagick imagemagick jid ldns libarchive libass libfido2 \
  libheif llvm lynx mkcert nghttp2 peco pcre2 psgrep pv rbenv rbenv-gemset \
  rbenv-vars ruby ruby-build grip socat sops srt ssh-copy-id stunnel \
  tesseract tidy-html5 unbound yarn yarn-completion zlib zsh \
  zsh-completions dockutil
```

Some may fail with "dependency required by..." — that's fine. Then:

```bash
brew autoremove
brew cleanup
```

### Brew casks

```bash
brew uninstall --cask basictex tunnelblick
```

### Ruby gems

```bash
gem uninstall rake rdoc
```


### npm globals

```bash
npm uninstall -g dotenv nx task-master 2>/dev/null
```

---

## 5. Verify

```bash
brew bundle check --file=~/.dotfiles/install/Brewfile
echo $EDITOR                    # code --wait
git config user.email           # mcnamaram@users.noreply.github.com
secrets-manage list             # stored secrets
type kindstart                  # should show function
```

Open a new terminal to confirm everything loads cleanly with no errors.

---

## 6. Rotate tokens (optional but recommended)

Since plaintext tokens previously existed in tracked files and on disk:

| Token          | Where to rotate                      |
| -------------- | ------------------------------------ |
| OPENAI_API_KEY | https://platform.openai.com/api-keys |
| GITHUB_TOKEN   | https://github.com/settings/tokens   |

After rotating, update in Keychain:

```bash
secrets-manage set <service> <account>
```
