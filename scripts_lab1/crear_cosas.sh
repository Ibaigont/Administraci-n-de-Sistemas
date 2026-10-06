#!/bin/bash
# Ejercicio 5: Crear una carpeta llamada cosas y 100 ficheros vacíos fich<numero>.txt (0 a 99)

mkdir -p cosas

for i in $(seq 0 99); do
    touch "cosas/fich${i}.txt"
done

echo "Se han creado 100 ficheros en el directorio cosas/ (fich0.txt a fich99.txt)."
