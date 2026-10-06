#!/bin/bash
# Ejercicio 4: Pedir una palabra al usuario y comprobar si es un comando del sistema

read -p "Introduce una palabra: " palabra

if [ -z "$palabra" ]; then
    echo "No has introducido ninguna palabra."
    exit 1
fi

if command -v "$palabra" > /dev/null 2>&1; then
    tipo=$(type -t "$palabra")
    ubicacion=$(type -p "$palabra")
    echo "'$palabra' SÍ es un comando del sistema (tipo: $tipo, ruta: ${ubicacion:-integrado/alias})."
else
    echo "'$palabra' NO es un comando del sistema."
fi
