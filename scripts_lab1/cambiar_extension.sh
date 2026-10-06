#!/bin/bash
# Ejercicio 7: Modificar la extensión de todos los ficheros .txt de un directorio a .t

directorio="${1:-.}"

if [ ! -d "$directorio" ]; then
    echo "Error: El directorio '$directorio' no existe."
    exit 1
fi

shopt -s nullglob
ficheros=("$directorio"/*.txt)

if [ ${#ficheros[@]} -eq 0 ]; then
    echo "No se encontraron ficheros .txt en '$directorio'."
    exit 0
fi

for f in "${ficheros[@]}"; do
    destino="${f%.txt}.t"
    mv "$f" "$destino"
done

echo "Se cambiaron ${#ficheros[@]} ficheros de extensión .txt a .t en '$directorio'."
