#!/bin/bash
# MV1: Generador y publicador de datos meteorológicos vía MQTT
# Se ejecuta 1 vez cada minuto vía cron.

BROKER_HOST="${1:-127.0.0.1}"
USUARIO_MQTT="sensor"
PASS_MQTT="sensor123"

# Generar temperatura aleatoria entre 10.0 y 24.0 (1 decimal)
# Generamos un entero entre 100 y 240 y dividimos entre 10
temp_raw=$((RANDOM % 141 + 100))
temperatura=$(awk "BEGIN {printf \"%.1f\", $temp_raw / 10}")

# Extensión: Humedad del campo (entero entre 50 y 60)
humedad=$((RANDOM % 11 + 50))

timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Publicar temperatura
msg_temp="$timestamp | Temperatura: ${temperatura} ºC"
mosquitto_pub -h "$BROKER_HOST" -t "campo/temperatura" -u "$USUARIO_MQTT" -P "$PASS_MQTT" -m "$msg_temp"

# Publicar humedad (Extensión)
msg_hum="$timestamp | Humedad: ${humedad} %"
mosquitto_pub -h "$BROKER_HOST" -t "campo/humedad" -u "$USUARIO_MQTT" -P "$PASS_MQTT" -m "$msg_hum"

echo "Publicado a las $timestamp -> Temp: $temperatura ºC | Hum: $humedad %"
