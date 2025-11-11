#!/bin/sh

install_neovim() {
  brew_install_formulas neovim ripgrep fd stylua node python@3.12 pipx tree-sitter tree-sitter-cli \
    typescript-language-server eslint_d prettierd

  if command -v pipx >/dev/null 2>&1; then
    pipx ensurepath
    pipx install --force --include-deps pynvim
    pipx install --force neovim-remote
  fi

  if command -v npm >/dev/null 2>&1; then
    npm list -g neovim >/dev/null 2>&1 || npm install -g neovim
    if brew list --formula vtsls >/dev/null 2>&1; then
      : # installed via Homebrew
    else
      npm list -g '@vtsls/language-server' >/dev/null 2>&1 || npm install -g @vtsls/language-server
    fi
  fi
}

register_installer install_neovim
