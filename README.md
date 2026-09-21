# Dotfiles · LuisFerMCDev

Setup Fedora + Hyprland + Noctalia + Kitty + Starship.

## Estructura

| Carpeta/archivo   | Destino en la máquina              |
|-------------------|------------------------------------|
| `hypr/`           | `~/.config/hypr/`                  |
| `noctalia/`       | `~/.config/noctalia/` (capa base)  |
| `kitty/kitty.conf`| `~/.config/kitty/kitty.conf`       |
| `starship.toml`   | `~/.config/starship.toml`          |
| `bootstrap.sh`    | instalador (laptop nueva)          |
| `hyprland-backup-legacy/` | respaldo viejo waybar/wofi, no se enlaza |

## Notas importantes

- **Noctalia tiene dos capas**: `~/.config/noctalia/config.toml` (este repo, base)
  y `~/.local/state/noctalia/settings.toml` (lo que genera la GUI, tiene prioridad).
  La GUI **no** se versiona: monitores, wallpaper y `notification_history` son por máquina.
- **`kitty/themes/noctalia.conf` lo genera Noctalia** (template `kitty` activo).
  No está en el repo; se crea al abrir Noctalia una vez.
- En la máquina principal los archivos están *hardlinkeados* al repo
  (editar uno edita el otro). En laptop nueva el bootstrap usa *symlinks*.

## Laptop nueva (Fedora)

```bash
sudo dnf install -y git
git clone https://github.com/LuisFerMCDev/Dotfiles ~/Dotfiles
cd ~/Dotfiles && ./bootstrap.sh
```

Luego:

1. Abre Noctalia una vez (genera `settings.toml` + tema de kitty).
2. Ajusta monitores y wallpaper en la GUI.
3. `hyprctl reload` o re-login.

## Restaurar backup local

```bash
# Repo completo desde bundle:
git clone ~/Backups/dotfiles-FECHA.bundle ~/Dotfiles-restore
# Config efectiva (settings.toml, hypr, kitty, bashrc, starship):
tar -xzf ~/Backups/configs-FECHA.tar.gz -C ~/
```

## Flujo diario

```bash
cd ~/Dotfiles
git status -sb      # ver qué cambió (la GUI de Noctalia no toca este repo)
git add -A && git commit -m "..." && git push
```
