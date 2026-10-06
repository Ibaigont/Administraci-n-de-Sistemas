#!/bin/bash
# Ejercicio 2: see.sh - Muestra contenido con more si es fichero, o lista con ls si es directorio

if [ $# -lt 1 ]; then
    echo "Uso: $0 <nombre_fichero_o_directorio>"
    exit 1
fi

ruta="$1"

if [ -f "$ruta" ]; then
    more "$ruta"
elif [ -d "$ruta" ]; then
    ls "$ruta"
else
    echo "Error: '$ruta' no existe o no es un fichero regular ni un directorio."
    exit 2
fi
