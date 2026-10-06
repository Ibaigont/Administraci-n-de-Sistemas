#!/bin/bash
# MV4: Script que lee los históricos en NFS y regenera el index.html
# Se ejecuta cada minuto vía cron.

CARPETA_NFS="${1:-/tmp/carpetaRemota}"
DIRECTORIO_WEB="${2:-/home/$USER/miWeb}"
FICHERO_HTML="$DIRECTORIO_WEB/index.html"

mkdir -p "$DIRECTORIO_WEB"

# Obtener última línea de temperatura
fich_temp="$CARPETA_NFS/HistoricoTemperatura.txt"
if [ -f "$fich_temp" ] && [ -s "$fich_temp" ]; then
    ultima_temp=$(tail -n 1 "$fich_temp")
else
    ultima_temp="Esperando mediciones de temperatura..."
fi

# Obtener última línea de humedad (Extensión)
fich_hum="$CARPETA_NFS/HistoricoHumedad.txt"
if [ -f "$fich_hum" ] && [ -s "$fich_hum" ]; then
    ultima_hum=$(tail -n 1 "$fich_hum")
else
    ultima_hum="Esperando mediciones de humedad..."
fi

# Generar index.html con el diseño solicitado
cat << EOF > "$FICHERO_HTML"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="60">
    <title>Monitorización Meteorológica del Campo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f7f9fc; color: #333; }
        .card { background: white; padding: 25px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); max-width: 600px; }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .metric { font-size: 1.2em; margin: 15px 0; padding: 10px; background: #eef2f7; border-left: 5px solid #27ae60; }
        .footer { font-size: 0.85em; color: #7f8c8d; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Estado del Campo de Trigo</h1>
        <div class="metric">
            <strong>Temperatura actual:</strong><br>
            $ultima_temp
        </div>
        <div class="metric">
            <strong>Humedad actual:</strong><br>
            $ultima_hum
        </div>
        <div class="footer">
            Página actualizada automáticamente cada 60 segundos.<br>
            Última generación local: $(date '+%Y-%m-%d %H:%M:%S')
        </div>
    </div>
</body>
</html>
EOF

echo "index.html actualizado con éxito en $FICHERO_HTML"
