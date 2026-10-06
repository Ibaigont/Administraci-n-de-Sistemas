#!/bin/bash
# Ejercicio 9: orden.sh - Muestra /etc/passwd ordenado por usuario, UID o GID

if [ $# -lt 1 ]; then
    echo "Uso: $0 {usuario|uid|gid}"
    exit 1
fi

case "$1" in
    usuario|user|-u)
        echo "=== Ordenado por NOMBRE DE USUARIO (campo 1) ==="
        sort -t: -k1,1 /etc/passwd
        ;;
    uid|UID|-i)
        echo "=== Ordenado por UID (campo 3 numérico) ==="
        sort -t: -k3,3n /etc/passwd
        ;;
    gid|GID|-g)
        echo "=== Ordenado por GID (campo 4 numérico) ==="
        sort -t: -k4,4n /etc/passwd
        ;;
    *)
        echo "Error: Criterio desconocido '$1'."
        echo "Opciones válidas: usuario, uid, gid"
        exit 2
        ;;
esac
