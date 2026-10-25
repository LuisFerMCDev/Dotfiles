# Dotfiles · LuisFerMCDev

Setup Rice & Dev: **Hyprland + Noctalia Shell + Kitty + Starship + Fastfetch** (Compatible con **CachyOS / Arch Linux** y **Fedora**).

---

## Estructura del Repositorio

| Carpeta / Archivo | Destino en el Sistema (`$HOME`) | Propósito |
| :--- | :--- | :--- |
| `hypr/` | `~/.config/hypr/` | Configuración de Hyprland (`hyprland.lua`), `hypridle`, `hyprlock` |
| `noctalia/` | `~/.config/noctalia/` | Barra superior cápsula, launcher y temas de Noctalia (capa base) |
| `noctalia/settings.toml.pc-gamer` | `~/.local/state/noctalia/settings.toml` | Plantilla de estado GUI (Noctalia) con el layout de la PC Gamer |
| `kitty/kitty.conf` | `~/.config/kitty/kitty.conf` | Configuración de Kitty terminal con auto-inclusión de tema Noctalia |
| `starship.toml` | `~/.config/starship.toml` | Prompt minimalista con iconos de desarrollo y estado de git |
| `fastfetch/` | `~/.config/fastfetch/` | Rice de bienvenida en terminal con módulos y paleta personalizada |
| `environment.d/` | `~/.config/environment.d/` | Variables de entorno gamer (`SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0`) |
| `bin/` | `~/.local/bin/` | Scripts de soporte (`audio-toggle`, `lock-screen`, `sync-wallpaper-hook`, `hqp`, `wall-toggle`) |
| `quickshell/` | `~/.config/quickshell/` | Selector visual de wallpapers con HyprQuickPaper |
| `bootstrap.sh` | Instalador automático | Detecta el sistema (CachyOS/Arch o Fedora), instala paquetes y enlaza todo |

---

## Guía de Instalación en CachyOS (o Arch Linux)

Para la **PC Gamer** o **Laptop** recién instalada con CachyOS:

```bash
# 1. Asegurar git
sudo pacman -S --needed git

# 2. Clonar el repositorio
git clone https://github.com/LuisFerMCDev/Dotfiles.git ~/Dotfiles

# 3. Ejecutar el bootstrap
cd ~/Dotfiles
chmod +x bootstrap.sh
./bootstrap.sh
```

El script `bootstrap.sh` se encargará automáticamente de:
- Instalar los paquetes nativos de Arch/CachyOS (`hyprland`, `noctalia`, `kitty`, `starship`, `fastfetch`, `fzf`, `bat`, `eza`, `zoxide`, etc.).
- Instalar dependencias de AUR con `paru` o `yay` (`quickshell`, `mpvpaper`).
- Crear los symlinks en `~/.config/` y `~/.local/bin/`.
- Restaurar `settings.toml.pc-gamer` en `~/.local/state/noctalia/settings.toml`.
- Configurar el bloque gamer en `~/.bashrc` (fzf Catppuccin, bat previews, alias gamer y fastfetch).

---

## Instrucciones para Antigravity / Asistente IA en CachyOS

Si un agente de IA (Antigravity) se encuentra en una instalación limpia de CachyOS:

1. **Verificar usuario y rutas absolutas**:
   * Las rutas en `hypr/hyprland.lua` y en los scripts de `bin/` asumen el usuario `luisfernando`. Si el usuario en CachyOS es diferente, adaptar el `PATH` y las rutas en `hypr/hyprland.lua`.
2. **Monitores**:
   * **PC Gamer**: El monitor principal está configurado en `hypr/hyprland.lua` como `HDMI-A-1` a `1920x1080@75`.
   * **Laptop**: Si se ejecuta en laptop, la pantalla integrada será `eDP-1`. Ajustar en `hypr/hyprland.lua` o usar la regla fallback `output = ""`.
3. **Noctalia First Run**:
   * Tras el bootstrap, ejecutar `noctalia` una vez o reiniciar Hyprland (`hyprctl reload`).
   * Noctalia generará automáticamente el template de colores de Kitty en `~/.config/kitty/themes/noctalia.conf`.
4. **Permisos y Audio**:
   * En CachyOS PipeWire y WirePlumber vienen activos por defecto. El script `bin/audio-toggle` conmuta entre salidas usando `wpctl` / `pactl`.
   * El script `bin/sync-wallpaper-hook` y `bin/wall-toggle` coordinan el fondo entre Noctalia y mpvpaper/HyprQuickPaper.

---

## Atajos de Teclado Clave (Hyprland Rice)

* `SUPER + Q`: Abrir Kitty terminal
* `SUPER + SPACE` o clic en la barra: Launcher de Noctalia
* `SUPER + L`: Bloqueo de pantalla con `hyprlock`
* `SUPER + O`: Conmutar salida de audio (`audio-toggle`)
* `SUPER + W` o `CTRL + W`: Selector de wallpapers HyprQuickPaper
* `SUPER + SHIFT + N`: Conmutar luz nocturna (Nightlight)
* `SUPER + I`: Panel de configuración de Noctalia
* `SUPER + C`: Cerrar ventana activa
