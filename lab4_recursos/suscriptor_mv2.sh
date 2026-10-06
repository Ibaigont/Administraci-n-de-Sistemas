#!/bin/bash
# MV2: Suscriptor MQTT continuo que guarda los datos en la carpeta NFS compartida
# Se ejecuta como servicio o en segundo plano en MV2.

CARPETA_NFS="${1:-/tmp/carpetaRemota}"
USUARIO_MQTT="sensor"
PASS_MQTT="sensor123"

mkdir -p "$CARPETA_NFS"

echo "Iniciando captura de datos MQTT en $CARPETA_NFS..."

# Suscripción a temperatura
mosquitto_sub -h 127.0.0.1 -t "campo/temperatura" -u "$USUARIO_MQTT" -P "$PASS_MQTT" >> "$CARPETA_NFS/HistoricoTemperatura.txt" &
SUB_TEMP_PID=$!

# Suscripción a humedad (Extensión)
mosquitto_sub -h 127.0.0.1 -t "campo/humedad" -u "$USUARIO_MQTT" -P "$PASS_MQTT" >> "$CARPETA_NFS/HistoricoHumedad.txt" &
SUB_HUM_PID=$!

echo "Suscriptores activos en segundo plano (PIDs: $SUB_TEMP_PID, $SUB_HUM_PID)."
wait
