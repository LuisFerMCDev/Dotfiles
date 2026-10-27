#!/usr/bin/env bash
# Bootstrap Dotfiles para CachyOS / Arch Linux y Fedora (Hyprland + Noctalia).
# Idempotente: respalda lo existente y enlaza por symlinks.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/Backups/pre-bootstrap-$(date +%F-%H%M)"
mkdir -p "$BACKUP"

echo "==> Repo: $REPO"
echo "==> Backup previo en: $BACKUP"

SKIP_PKG=false
if [ "${1:-}" = "--no-pkg" ] || [ "${1:-}" = "--skip-pkg" ]; then
  SKIP_PKG=true
fi

# 1. Detección de distribución e instalación de paquetes
if [ "$SKIP_PKG" = true ]; then
  echo "==> Omitiendo instalación de paquetes (--no-pkg especificado)"
elif command -v pacman >/dev/null; then
  echo "==> Detectado CachyOS / Arch Linux (pacman)"
  sudo pacman -S --needed --noconfirm \
    hyprland noctalia kitty starship git github-cli \
    fzf ripgrep fd eza zoxide \
    jq imagemagick ffmpeg uv bat brightnessctl playerctl fastfetch \
    hypridle hyprlock hyprpolkitagent ttf-jetbrains-mono-nerd \
    quickshell mpvpaper paru zen-browser-bin

  # AUR fallback si se requiere
  if ! command -v paru >/dev/null && command -v yay >/dev/null; then
    yay -S --needed --noconfirm quickshell mpvpaper || true
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
link_path "fastfetch/cachyos.png" "$HOME/.config/fastfetch/cachyos.png"
link_path "environment.d/gaming.conf" "$HOME/.config/environment.d/gaming.conf"
link_path "environment.d/uwsm.conf" "$HOME/.config/environment.d/uwsm.conf"
link_path "profile" "$HOME/.profile"

# Scripts de utilidad en ~/.local/bin
mkdir -p "$HOME/.local/bin"
link_path "bin/hqp" "$HOME/.local/bin/hqp"
link_path "bin/wall-toggle" "$HOME/.local/bin/wall-toggle"
link_path "bin/audio-toggle" "$HOME/.local/bin/audio-toggle"
link_path "bin/lock-screen" "$HOME/.local/bin/lock-screen"
link_path "bin/sync-wallpaper-hook" "$HOME/.local/bin/sync-wallpaper-hook"
link_path "bin/set-greeter-wallpaper" "$HOME/.local/bin/set-greeter-wallpaper"
link_path "bin/sync-greeter" "$HOME/.local/bin/sync-greeter"
chmod +x "$REPO"/bin/* 2>/dev/null || true

# 2b. Restaurar configuración de Noctalia GUI y paletas
NOCTALIA_STATE="$HOME/.local/state/noctalia"
mkdir -p "$NOCTALIA_STATE/community-palettes"
if [ -f "$REPO/noctalia/settings.toml.pc-gamer" ]; then
  if [ ! -f "$NOCTALIA_STATE/settings.toml" ] || ! grep -q "\[bar.default\]" "$NOCTALIA_STATE/settings.toml" 2>/dev/null; then
    echo "  noctalia: restaurando settings.toml base para PC Gamer"
    [ -f "$NOCTALIA_STATE/settings.toml" ] && cp "$NOCTALIA_STATE/settings.toml" "$NOCTALIA_STATE/settings.toml.bak"
    cp "$REPO/noctalia/settings.toml.pc-gamer" "$NOCTALIA_STATE/settings.toml"
  fi
fi
if [ -d "$REPO/noctalia/palettes" ]; then
  cp -rn "$REPO"/noctalia/palettes/* "$NOCTALIA_STATE/community-palettes/" 2>/dev/null || true
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

# 3. Bloque dev-tools y rice en shells (.bashrc, fish, .zshrc)
# 3a. Bash
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
alias limpieza='flatpak uninstall --unused -y 2>/dev/null || true; rm -rf ~/.cache/thumbnails/*; journalctl --user --vacuum-size=100M; echo "--- Steam ---"; du -sh ~/.local/share/Steam 2>/dev/null; echo "--- Docker ---"; du -sh ~/.docker 2>/dev/null'
alias espacio='du -sh ~/* ~/.cache/* 2>/dev/null | sort -rh | head -n 12'

eval "\$(starship init bash 2>/dev/null)" || true
eval "\$(zoxide init bash 2>/dev/null)" || true

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

# 3b. Fish (shell por defecto en CachyOS)
FISH_CONFIG="$HOME/.config/fish/config.fish"
if [ -d "$HOME/.config/fish" ] || command -v fish >/dev/null 2>&1; then
  mkdir -p "$HOME/.config/fish"
  [ -f "$FISH_CONFIG" ] || touch "$FISH_CONFIG"
  if ! grep -q "# Starship prompt + aliases (setup gamer)" "$FISH_CONFIG" 2>/dev/null; then
    cat >> "$FISH_CONFIG" << 'EOF'

# Starship prompt + aliases (setup gamer)
set -gx FZF_DEFAULT_OPTS "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --multi"
set -gx FZF_CTRL_T_OPTS "--preview 'bat -n --color=always --line-range :300 {} 2>/dev/null || cat {}'"
set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls -la {}'"
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
alias lz='eza -la --icons --group-directories-first --git'
alias ll='ls -lah --color=auto'
alias ff='fastfetch'
alias hreload='hyprctl reload'
alias hmon='hyprctl monitors all | grep -E "Monitor|scale|@"'
alias limpieza='flatpak uninstall --unused -y 2>/dev/null || true; rm -rf ~/.cache/thumbnails/*; journalctl --user --vacuum-size=100M; echo "--- Steam ---"; du -sh ~/.local/share/Steam 2>/dev/null; echo "--- Docker ---"; du -sh ~/.docker 2>/dev/null'
alias espacio='du -sh ~/* ~/.cache/* 2>/dev/null | sort -rh | head -n 12'

if command -v starship >/dev/null 2>&1
    starship init fish | source
end
if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
end
EOF
    echo "  fish: bloque setup gamer agregado"
  else
    echo "  fish: bloque setup gamer ya existe"
  fi
fi

# 3c. Zsh
if [ -f "$HOME/.zshrc" ] && ! grep -q "# Starship prompt + aliases (setup gamer)" "$HOME/.zshrc" 2>/dev/null; then
  cat >> "$HOME/.zshrc" << 'EOF'

# Starship prompt + aliases (setup gamer)
export FZF_DEFAULT_OPTS="--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --multi"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :300 {} 2>/dev/null || cat {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls -la {}'"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
alias lz='eza -la --icons --group-directories-first --git'
alias ll='ls -lah --color=auto'
alias ff='fastfetch'
alias hreload='hyprctl reload'
alias hmon='hyprctl monitors all | grep -E "Monitor|scale|@"'
alias limpieza='flatpak uninstall --unused -y 2>/dev/null || true; rm -rf ~/.cache/thumbnails/*; journalctl --user --vacuum-size=100M; echo "--- Steam ---"; du -sh ~/.local/share/Steam 2>/dev/null; echo "--- Docker ---"; du -sh ~/.docker 2>/dev/null'
alias espacio='du -sh ~/* ~/.cache/* 2>/dev/null | sort -rh | head -n 12'

eval "$(starship init zsh 2>/dev/null)" || true
eval "$(zoxide init zsh 2>/dev/null)" || true
EOF
  echo "  zsh: bloque setup gamer agregado"
fi

# 4. Defaults git
git config --global init.defaultBranch main 2>/dev/null || true
if [ -z "$(git config --global user.name || true)" ]; then
  git config --global user.name "NanKill"
  echo "  git: configurado user.name 'NanKill'"
fi
if [ -z "$(git config --global user.email || true)" ]; then
  git config --global user.email "nankill@nankill.xyz"
  echo "  git: configurado user.email 'nankill@nankill.xyz'"
fi
git config --global pull.rebase true 2>/dev/null || true
git config --global core.editor "code --wait" 2>/dev/null || true

echo ""
echo "==> Setup completado con éxito."
echo "  1. Noctalia generará automáticamente el tema de Kitty en kitty/themes/noctalia.conf"
echo "  2. Si deseas cambiar de wallpaper o monitores, usa la GUI de Noctalia (Super + I)"
echo "  3. Aplica cambios con 'hyprctl reload' o reinicia la sesión."
