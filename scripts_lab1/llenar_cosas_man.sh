#!/bin/bash
# Ejercicio 6: Extender el script para que cada fichero contenga la N-ésima línea del manual de ls

mkdir -p cosas

# Guardamos el manual de ls en texto plano (col -b elimina caracteres de formato/backspaces)
man_tmp=$(mktemp)
man ls | col -b > "$man_tmp"

for i in $(seq 0 99); do
    # Si consideramos 0-indexado: fich0.txt recibe la línea 1 del manual, fich1.txt la línea 2...
    # (o si se interpreta 1-indexado exacto: línea i para i>0 y vacía para 0)
    linea_num=$((i + 1))
    sed -n "${linea_num}p" "$man_tmp" > "cosas/fich${i}.txt"
done

rm -f "$man_tmp"
echo "Ficheros creados y llenados con las líneas del manual de ls en cosas/."
