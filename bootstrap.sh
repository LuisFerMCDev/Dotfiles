#!/usr/bin/env bash
# Bootstrap Dotfiles para CachyOS / Arch Linux y Fedora (Hyprland + Noctalia).
# Idempotente: respalda lo existente y enlaza por symlinks.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/Backups/pre-bootstrap-$(date +%F-%H%M)"
mkdir -p "$BACKUP"

echo "==> Repo: $REPO"
echo "==> Backup previo en: $BACKUP"

# 1. Detección de distribución e instalación de paquetes
if command -v pacman >/dev/null; then
  echo "==> Detectado CachyOS / Arch Linux (pacman)"
  sudo pacman -S --needed --noconfirm \
    hyprland noctalia kitty starship git github-cli \
    fzf ripgrep fd eza zoxide neovim \
    jq imagemagick ffmpeg uv bat brightnessctl playerctl fastfetch

  # AUR helper (paru o yay)
  if command -v paru >/dev/null; then
    echo "==> Instalando paquetes AUR con paru..."
    paru -S --needed --noconfirm quickshell mpvpaper
  elif command -v yay >/dev/null; then
    echo "==> Instalando paquetes AUR con yay..."
    yay -S --needed --noconfirm quickshell mpvpaper
  else
    echo "!! No se encontró paru ni yay. Instala 'quickshell' y 'mpvpaper' manualmente desde AUR."
  fi

elif command -v dnf >/dev/null; then
  echo "==> Detectado Fedora (dnf)"
  sudo dnf install -y \
    hyprland noctalia kitty starship git gh \
    fzf ripgrep fd-find eza zoxide neovim \
    jq ImageMagick ffmpeg mpvpaper bat fastfetch
  # Quickshell en COPR
  sudo dnf copr enable -y errornointernet/quickshell || true
  sudo dnf install -y quickshell
  sudo dnf install -y uv || (curl -LsSf astral.sh/uv/install.sh | sh)
else
  echo "!! Gestor no reconocido: instala manualmente hyprland, noctalia, kitty, starship, git, gh, fzf, ripgrep, fd, eza, zoxide, neovim, uv, bat, fastfetch, quickshell, mpvpaper."
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

# Configuraciones principales
link_path "hypr" "$HOME/.config/hypr"
link_path "noctalia" "$HOME/.config/noctalia"
link_path "kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
link_path "starship.toml" "$HOME/.config/starship.toml"
link_path "fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
link_path "environment.d/gaming.conf" "$HOME/.config/environment.d/gaming.conf"

# Scripts de utilidad en ~/.local/bin
mkdir -p "$HOME/.local/bin"
link_path "bin/hqp" "$HOME/.local/bin/hqp"
link_path "bin/wall-toggle" "$HOME/.local/bin/wall-toggle"
link_path "bin/audio-toggle" "$HOME/.local/bin/audio-toggle"
link_path "bin/lock-screen" "$HOME/.local/bin/lock-screen"
link_path "bin/sync-wallpaper-hook" "$HOME/.local/bin/sync-wallpaper-hook"
chmod +x "$REPO"/bin/* 2>/dev/null || true

# 2b. Restaurar configuración de Noctalia GUI si no existe
NOCTALIA_STATE="$HOME/.local/state/noctalia"
mkdir -p "$NOCTALIA_STATE"
if [ ! -f "$NOCTALIA_STATE/settings.toml" ] && [ -f "$REPO/noctalia/settings.toml.pc-gamer" ]; then
  echo "  noctalia: restaurando settings.toml base para PC Gamer"
  cp "$REPO/noctalia/settings.toml.pc-gamer" "$NOCTALIA_STATE/settings.toml"
fi

# 2c. HyprQuickPaper (selector visual de wallpapers)
HQ="$HOME/.config/quickshell/hyprquickpaper"
if [ ! -d "$HQ" ]; then
  echo "  clone: hyprquickpaper"
  mkdir -p "$HOME/.config/quickshell"
  git clone https://github.com/ujjalsigdel/hyprquickpaper.git "$HQ"
else
  echo "  hyprquickpaper: ya existe, no toco"
fi
if [ -d "$HQ" ]; then
  echo "  config: hyprquickpaper config.json + enlaces layouts/"
  cp "$REPO/quickshell/hyprquickpaper-config.json" "$HQ/config.json"
  for f in config.json cache.sh commands.sh common.sh assets; do
    [ -e "$HQ/layouts/$f" ] || ln -s "../$f" "$HQ/layouts/$f"
  done
  mkdir -p "$HOME/.cache/hyprquickpaper"
  [ -f "$HOME/.cache/hyprquickpaper/current_wallpaper" ] || touch "$HOME/.cache/hyprquickpaper/current_wallpaper"
fi

# 3. Bloque dev-tools y rice en .bashrc
if ! grep -q "# Starship prompt + aliases (setup gamer)" "$HOME/.bashrc" 2>/dev/null; then
  # Detectar ruta fzf
  FZF_BINDINGS=""
  if [ -f /usr/share/fzf/key-bindings.bash ]; then
    FZF_BINDINGS="/usr/share/fzf/key-bindings.bash"
  elif [ -f /usr/share/fzf/shell/key-bindings.bash ]; then
    FZF_BINDINGS="/usr/share/fzf/shell/key-bindings.bash"
  fi

  cat >> "$HOME/.bashrc" <<EOF

# Starship prompt + aliases (setup gamer)
[ -n "$FZF_BINDINGS" ] && source "$FZF_BINDINGS"
export FZF_DEFAULT_OPTS="--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --multi"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :300 {} 2>/dev/null || cat {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls -la {}'"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
alias lz='eza -la --icons --group-directories-first --git'
alias ll='ls -lah --color=auto'
alias ff='fastfetch'
alias hreload='hyprctl reload'
alias hmon='hyprctl monitors all | grep -E "Monitor|scale|@"'
alias limpieza='flatpak uninstall --unused -y 2>/dev/null || true; rm -rf ~/.cache/gnome-software ~/.cache/thumbnails/*; journalctl --user --vacuum-size=100M; echo "--- Steam ---"; du -sh ~/.local/share/Steam 2>/dev/null; echo "--- Docker ---"; du -sh ~/.docker 2>/dev/null'
alias espacio='du -sh ~/* ~/.cache/* 2>/dev/null | sort -rh | head -n 12'

eval "\$(starship init bash)"
eval "\$(zoxide init bash)"

# Fastfetch greeting
if [[ \$- == *i* ]] && [ -z "\${FASTFETCH_SHOWN:-}" ]; then
    export FASTFETCH_SHOWN=1
    fastfetch 2>/dev/null || true
fi
EOF
  echo "  bashrc: bloque setup gamer agregado"
else
  echo "  bashrc: bloque setup gamer ya existe"
fi

# 4. Defaults git
git config --global init.defaultBranch main 2>/dev/null || true
[ -z "$(git config --global user.name || true)" ] && echo "!! Configura: git config --global user.name 'Tu Nombre'"
[ -z "$(git config --global user.email || true)" ] && echo "!! Configura: git config --global user.email 'tu@email'"
git config --global pull.rebase true 2>/dev/null || true
git config --global core.editor nvim 2>/dev/null || true

echo ""
echo "==> Setup completado con éxito."
echo "  1. Noctalia generará automáticamente el tema de Kitty en kitty/themes/noctalia.conf"
echo "  2. Si deseas cambiar de wallpaper o monitores, usa la GUI de Noctalia (Super + I)"
echo "  3. Aplica cambios con 'hyprctl reload' o reinicia la sesión."
