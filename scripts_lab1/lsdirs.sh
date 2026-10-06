#!/bin/bash
# Ejercicio 1: Mostrar los directorios contenidos en el directorio actual

for item in */; do
    if [ -d "$item" ]; then
        echo "${item%/}"
    fi
done
