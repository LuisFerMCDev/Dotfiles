# ~/.profile: ejecutado por shells compatibles con POSIX y gestores de login (greetd)

# Silenciar mensajes de inicio de UWSM (1: suprime stdout, 2: suprime también warnings)
export UWSM_SILENT_START=2

# Limpiar la pantalla de la consola TTY para una transición limpia a la sesión gráfica
if [ -t 1 ]; then
    clear
fi
