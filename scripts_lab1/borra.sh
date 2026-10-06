#!/bin/bash
# Ejercicio 8: borra.sh - Recibe parámetros (de 0 a 9) y borra el fichero correspondiente a su suma

if [ $# -lt 1 ]; then
    echo "Uso: $0 <num1> <num2> ... <numN>"
    echo "Ejemplo: $0 1 4 5 9  (borrará el fichero con sufijo 19)"
    exit 1
fi

suma=0
for arg in "$@"; do
    if ! [[ "$arg" =~ ^[0-9]+$ ]]; then
        echo "Error: El parámetro '$arg' no es un número válido."
        exit 2
    fi
    suma=$((suma + arg))
done

# El fichero puede estar en el directorio actual o en cosas/
# y puede tener extensión .txt o .t
posibles=(
    "cosas/fich${suma}.txt"
    "cosas/fich${suma}.t"
    "fich${suma}.txt"
    "fich${suma}.t"
)

borrado=0
for f in "${posibles[@]}"; do
    if [ -f "$f" ]; then
        rm "$f"
        echo "Fichero '$f' borrado exitosamente (suma total = $suma)."
        borrado=1
        break
    fi
done

if [ $borrado -eq 0 ]; then
    echo "No se encontró ningún fichero correspondiente a la suma $suma (fich${suma}.txt o fich${suma}.t)."
fi
