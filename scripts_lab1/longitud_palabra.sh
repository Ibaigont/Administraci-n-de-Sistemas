#!/bin/bash
# Ejercicio 3: Pedir una palabra al usuario y mostrar su número de caracteres

read -p "Introduce una palabra: " palabra
echo "La palabra '${palabra}' tiene ${#palabra} caracteres."
