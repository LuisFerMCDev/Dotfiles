#!/usr/bin/env bash
# Bootstrap Dotfiles en laptop nueva (Fedora + Hyprland).
# Idempotente: hace backup previo y enlaza por symlinks.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/Backups/pre-bootstrap-$(date +%F-%H%M)"
mkdir -p "$BACKUP"

echo "==> Repo: $REPO"
echo "==> Backup previo en: $BACKUP"

# 1. Paquetes (Fedora). Fuera de Fedora, instala manual la misma lista.
if command -v dnf >/dev/null; then
  sudo dnf install -y \
    hyprland noctalia kitty starship git gh \
    fzf ripgrep fd-find eza zoxide neovim
  sudo dnf install -y uv || (curl -LsSf astral.sh/uv/install.sh | sh)
else
  echo "!! Sin dnf: instala manual hyprland noctalia kitty starship git gh fzf ripgrep fd eza zoxide neovim uv"
fi

# 2. Backup de lo existente y symlink al repo
link_path() { # link_path <repo_rel> <dest>
  local src="$REPO/$1" dest="$2"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "  backup: $dest"
    mv "$dest" "$BACKUP/"
  elif [ -L "$dest" ]; then
    rm "$dest"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "  link: $dest -> $src"
}

link_path "hypr" "$HOME/.config/hypr"
link_path "noctalia" "$HOME/.config/noctalia"
link_path "kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
link_path "starship.toml" "$HOME/.config/starship.toml"

# 3. Bloque dev-tools en .bashrc (solo si falta)
if ! grep -q "Dev tools (opencode setup)" "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'EOF'

# Dev tools (opencode setup)
[ -f /usr/share/fzf/shell/key-bindings.bash ] && source /usr/share/fzf/shell/key-bindings.bash
alias lz='eza -la --icons --group-directories-first --git'
alias ll='ls -lah --color=auto'
eval "$(starship init bash)"
eval "$(zoxide init bash)"
EOF
  echo "  bashrc: bloque dev-tools agregado"
else
  echo "  bashrc: bloque dev-tools ya existe"
fi

# 4. Defaults git (solo si faltan)
git config --global init.defaultBranch main 2>/dev/null || true
[ -z "$(git config --global user.name || true)" ] && echo "!! Configura: git config --global user.name 'Tu Nombre'"
[ -z "$(git config --global user.email || true)" ] && echo "!! Configura: git config --global user.email 'tu@email'"
git config --global pull.rebase true 2>/dev/null || true
git config --global core.editor nvim 2>/dev/null || true

echo ""
echo "==> Listo. Ahora:"
echo "  1. Abre Noctalia una vez (genera settings.toml + kitty/themes/noctalia.conf)"
echo "  2. Ajusta monitores y wallpaper en la GUI"
echo "  3. hyprctl reload (o re-login)"
