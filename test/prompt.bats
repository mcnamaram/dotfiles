#!/usr/bin/env bats

setup() {
  export DOTFILES_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "${DOTFILES_DIR}/system/.prompt_bash"
}

@test "git_prompt_state reports clean repos" {
  local tmpdir
  tmpdir="$(mktemp -d)"

  git init "$tmpdir" >/dev/null 2>&1
  git -C "$tmpdir" config user.name "Test User"
  git -C "$tmpdir" config user.email "test@example.com"
  printf 'hello\n' > "$tmpdir/file.txt"
  git -C "$tmpdir" add file.txt
  git -C "$tmpdir" commit -m 'init' >/dev/null 2>&1

  pushd "$tmpdir" >/dev/null
  run git_prompt_state
  popd >/dev/null

  [ "$status" -eq 0 ]
  [ "$output" = "clean" ]

  rm -rf "$tmpdir"
}

@test "git_prompt_state reports dirty repos" {
  local tmpdir
  tmpdir="$(mktemp -d)"

  git init "$tmpdir" >/dev/null 2>&1
  git -C "$tmpdir" config user.name "Test User"
  git -C "$tmpdir" config user.email "test@example.com"
  printf 'hello\n' > "$tmpdir/file.txt"
  git -C "$tmpdir" add file.txt
  git -C "$tmpdir" commit -m 'init' >/dev/null 2>&1
  printf 'change\n' >> "$tmpdir/file.txt"

  pushd "$tmpdir" >/dev/null
  run git_prompt_state
  popd >/dev/null

  [ "$status" -eq 0 ]
  [ "$output" = "dirty" ]

  rm -rf "$tmpdir"
}
