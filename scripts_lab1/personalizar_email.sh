#!/bin/bash
# Ejercicio 10: Generar emails personalizados a partir de cuerpo.txt y nombres.txt

fichero_cuerpo="${1:-cuerpo.txt}"
fichero_nombres="${2:-nombres.txt}"

if [ ! -f "$fichero_cuerpo" ]; then
    echo "Error: No se encuentra el fichero de plantilla '$fichero_cuerpo'."
    exit 1
fi

if [ ! -f "$fichero_nombres" ]; then
    echo "Error: No se encuentra el fichero de nombres '$fichero_nombres'."
    exit 2
fi

mkdir -p emails_generados

contador=0
while IFS= read -r linea || [ -n "$linea" ]; do
    # Limpiar retornos de carro si el fichero viene de Windows (\r)
    nombre=$(echo "$linea" | tr -d '\r' | xargs)
    
    # Omitir líneas vacías
    [ -z "$nombre" ] && continue

    fichero_salida="emails_generados/email_${nombre}.txt"
    sed "s/NOMBRE/${nombre}/g" "$fichero_cuerpo" > "$fichero_salida"
    echo "Generado email para '${nombre}' -> $fichero_salida"
    contador=$((contador + 1))
done < "$fichero_nombres"

echo "Proceso finalizado. Total emails generados: $contador en el directorio emails_generados/."
