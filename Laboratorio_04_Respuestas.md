# Soluciones y Respuestas: Laboratorio 4 - NFS y MQTT

**Asignatura:** Administración de Sistemas  
**Temario:** Tema 2.1 - Servicios en Red: NFS y MQTT  
**Estado para el examen:**
- **QUÉ NO ENTRA EN EL EXAMEN:**
  1. **Despliegue y coordinación de múltiples máquinas virtuales:** En la diapositiva 3 de `Preparación examen.pdf` se especifica: *"Contenido excluido del examen: Creación de varias máquinas virtuales. El examen se podrá hacer con sólo 1."* Por consiguiente, la arquitectura distribuida de 4 MVs independientes en la nube NO se pedirá en el examen.
  2. **RabbitMQ:** Citado expresamente como excluido (*"RabbitMQ"*).
- **QUÉ SÍ ENTRA EN EL EXAMEN:**
  - **Servicios NFS:** Instalación (`nfs-kernel-server`, `nfs-common`), configuración del servidor (`/etc/exports` con opciones `rw`, `ro`, `sync`, `no_subtree_check`, `no_root_squash`), recarga con `exportfs -ra`, montaje en clientes (`mount -t nfs`) y montaje automático en `/etc/fstab`.
  - **Servicios MQTT con Mosquitto:** Instalación del broker (`mosquitto`, `mosquitto-clients`), control de acceso y autenticación con `mosquitto_passwd`, configuración de listas de control de acceso (ACLs) con `acl_file`, topics y comodines (`+`, `#`), y clientes de línea de comandos (`mosquitto_pub` y `mosquitto_sub`).
  - **Servidor web ligero:** Exposición de directorios y contenido HTML con `python3 -m http.server 80`.
  - **Scripts de automatización:** Generación de métricas aleatorias y actualización dinámica de ficheros mediante tareas de `cron`.
  *(En el examen, todos estos servicios se configuran e interconectan dentro de la **única máquina virtual del examen** utilizando la interfaz de loopback `127.0.0.1` / `localhost`).*

---

## 1. Arquitectura y Recursos del Laboratorio

Todos los scripts ejecutables y ficheros de configuración de este laboratorio se encuentran preparados en la carpeta `lab04_recursos/`:
- `sensor_mv1.sh`: Script del sensor meteorológico (temperatura y humedad).
- `suscriptor_mv2.sh`: Demonio/suscriptor de recepción MQTT hacia el histórico NFS.
- `generar_web_mv4.sh`: Generador automático del fichero `index.html`.
- `mosquitto_lab4.conf`: Archivo de configuración del broker Mosquitto.
- `mosquitto_acl`: Reglas de control de acceso ACL.
- `exports_ejemplo`: Configuración de exportaciones para `/etc/exports`.

A continuación se detalla la solución completa tanto para el escenario distribuido de 4 máquinas como para el escenario de 1 sola máquina virtual para el examen.

---

## 2. Configuración Máquina por Máquina (Escenario Distribuido)

### 2.1 MV3: Servidor NFS
*(Se configura en primer lugar para que la carpeta compartida esté disponible para MV2 y MV4).*

#### 1. Instalar el servidor NFS:
```bash
sudo apt update && sudo apt install -y nfs-kernel-server nfs-common
```

#### 2. Crear y configurar la carpeta compartida:
```bash
sudo mkdir -p /datosNfs
sudo chown nobody:nogroup /datosNfs
sudo chmod 777 /datosNfs
```
*(Asignar propietario `nobody:nogroup` y permisos de escritura garantiza que los clientes NFS puedan escribir sin problemas de permisos locales).*

#### 3. Configurar `/etc/exports`:
Editar `/etc/exports` con permisos `rw` (lectura/escritura) para MV2 y `ro` (sólo lectura) para MV4:
```text
/datosNfs  <IP_MV2>(rw,sync,no_subtree_check,no_root_squash) <IP_MV4>(ro,sync,no_subtree_check)
```
- **Opciones explicadas:**
  - `rw`: Permite operaciones de lectura y escritura.
  - `ro`: Restringe a solo lectura.
  - `sync`: Confirma las peticiones a cliente únicamente cuando los datos se han escrito en disco.
  - `no_subtree_check`: Desactiva la comprobación de subárboles, mejorando fiabilidad y rendimiento.
  - `no_root_squash`: Permite que las operaciones de root en el cliente mantengan privilegios de superusuario en el servidor.

#### 4. Aplicar los cambios y reiniciar el servicio:
```bash
sudo exportfs -ra
sudo exportfs -v
sudo systemctl restart nfs-kernel-server
```
*(Asegurar que el puerto TCP `2049` de NFS está accesible en el firewall/GCP).*

---

### 2.2 MV2: Broker MQTT y Puente a NFS

#### 1. Instalar Mosquitto y cliente NFS:
```bash
sudo apt update && sudo apt install -y mosquitto mosquitto-clients nfs-common
```

#### 2. Montar la carpeta NFS remota desde MV3:
```bash
sudo mkdir -p /tmp/carpetaRemota
sudo mount -t nfs <IP_MV3>:/datosNfs /tmp/carpetaRemota
```
- Para montaje permanente al arranque en `/etc/fstab`:
  ```text
  <IP_MV3>:/datosNfs  /tmp/carpetaRemota  nfs  defaults,nofail,_netdev  0  0
  ```

#### 3. Configurar autenticación y ACLs en Mosquitto:
Crear fichero de contraseñas con el usuario `sensor`:
```bash
sudo mosquitto_passwd -c /etc/mosquitto/passwd sensor
# Introducir una contraseña (por ejemplo: sensor123)
```

Crear fichero de ACLs `/etc/mosquitto/acl`:
```text
user sensor
topic readwrite campo/temperatura
topic readwrite campo/humedad
```

Crear fichero de configuración en `/etc/mosquitto/conf.d/campo.conf`:
```text
listener 1883 0.0.0.0
allow_anonymous false
password_file /etc/mosquitto/passwd
acl_file /etc/mosquitto/acl
```

Reiniciar y verificar Mosquitto:
```bash
sudo systemctl restart mosquitto
sudo systemctl status mosquitto
```

#### 4. Suscriptor continuo para registrar datos en el histórico NFS:
Se utiliza el script `lab04_recursos/suscriptor_mv2.sh` (o ejecutado directamente en segundo plano / como servicio systemd):
```bash
mosquitto_sub -h 127.0.0.1 -t "campo/temperatura" -u "sensor" -P "sensor123" >> /tmp/carpetaRemota/HistoricoTemperatura.txt &
```
*(Con la extensión de humedad, se añade un segundo proceso suscriptor):*
```bash
mosquitto_sub -h 127.0.0.1 -t "campo/humedad" -u "sensor" -P "sensor123" >> /tmp/carpetaRemota/HistoricoHumedad.txt &
```

---

### 2.3 MV1: Recolección y Envío de Datos (Sensor)

#### 1. Instalar cliente Mosquitto:
```bash
sudo apt update && sudo apt install -y mosquitto-clients
```

#### 2. Script de recolección (`lab04_recursos/sensor_mv1.sh`):
```bash
#!/bin/bash
BROKER_HOST="<IP_MV2>"
USUARIO_MQTT="sensor"
PASS_MQTT="sensor123"

# Temperatura aleatoria entre 10.0 y 24.0 (1 decimal)
temp_raw=$((RANDOM % 141 + 100))
temperatura=$(awk "BEGIN {printf \"%.1f\", $temp_raw / 10}")

# Humedad aleatoria entre 50 y 60 (Extensión)
humedad=$((RANDOM % 11 + 50))

timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Publicar temperatura
msg_temp="$timestamp | Temperatura: ${temperatura} ºC"
mosquitto_pub -h "$BROKER_HOST" -t "campo/temperatura" -u "$USUARIO_MQTT" -P "$PASS_MQTT" -m "$msg_temp"

# Publicar humedad
msg_hum="$timestamp | Humedad: ${humedad} %"
mosquitto_pub -h "$BROKER_HOST" -t "campo/humedad" -u "$USUARIO_MQTT" -P "$PASS_MQTT" -m "$msg_hum"
```

#### 3. Programación periódica con `cron` cada minuto:
```bash
crontab -e
```
Añadir la línea:
```cron
* * * * * /home/usuario/sensor_mv1.sh >> /tmp/sensor.log 2>&1
```

---

### 2.4 MV4: Servidor Web Dinámico

#### 1. Instalar cliente NFS y montar la carpeta en modo sólo lectura:
```bash
sudo apt update && sudo apt install -y nfs-common python3
sudo mkdir -p /tmp/carpetaRemota
sudo mount -t nfs -o ro <IP_MV3>:/datosNfs /tmp/carpetaRemota
```
- En `/etc/fstab`:
  ```text
  <IP_MV3>:/datosNfs  /tmp/carpetaRemota  nfs  ro,defaults,nofail,_netdev  0  0
  ```

#### 2. Directorio web e inicio del servidor HTTP:
```bash
mkdir -p /home/$USER/miWeb
cd /home/$USER/miWeb
sudo python3 -m http.server 80 &
```

#### 3. Script para regenerar `index.html` cada minuto (`lab04_recursos/generar_web_mv4.sh`):
```bash
#!/bin/bash
CARPETA_NFS="/tmp/carpetaRemota"
DIRECTORIO_WEB="/home/$USER/miWeb"
FICHERO_HTML="$DIRECTORIO_WEB/index.html"

# Obtener último valor de temperatura
if [ -s "$CARPETA_NFS/HistoricoTemperatura.txt" ]; then
    ultima_temp=$(tail -n 1 "$CARPETA_NFS/HistoricoTemperatura.txt")
else
    ultima_temp="Esperando mediciones de temperatura..."
fi

# Obtener último valor de humedad (Extensión)
if [ -s "$CARPETA_NFS/HistoricoHumedad.txt" ]; then
    ultima_hum=$(tail -n 1 "$CARPETA_NFS/HistoricoHumedad.txt")
else
    ultima_hum="Esperando mediciones de humedad..."
fi

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
```

#### 4. Programación periódica en `cron`:
```bash
crontab -e
```
Añadir:
```cron
* * * * * /home/usuario/generar_web_mv4.sh >> /tmp/generar_web.log 2>&1
```

---

## 3. Adaptación Completa a 1 Sola Máquina Virtual (Para el Examen)

Si en el examen práctico se solicita configurar NFS, MQTT o el Servidor Web en una única máquina virtual:

### 1) NFS en Local (Loopback):
```bash
# Servidor:
sudo apt install -y nfs-kernel-server nfs-common
sudo mkdir -p /datosNfs /tmp/carpetaRemota
sudo chmod 777 /datosNfs

# Añadir a /etc/exports:
echo "/datosNfs 127.0.0.1(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server

# Cliente (montaje en local):
sudo mount -t nfs 127.0.0.1:/datosNfs /tmp/carpetaRemota
df -h | grep /tmp/carpetaRemota
```

### 2) Mosquitto en Local:
```bash
sudo apt install -y mosquitto mosquitto-clients

# Configurar sin anónimos y con usuario:
sudo mosquitto_passwd -c /etc/mosquitto/passwd sensor
echo "user sensor" | sudo tee /etc/mosquitto/acl
echo "topic readwrite campo/#" | sudo tee -a /etc/mosquitto/acl

sudo tee /etc/mosquitto/conf.d/examen.conf << 'EOF'
listener 1883 127.0.0.1
allow_anonymous false
password_file /etc/mosquitto/passwd
acl_file /etc/mosquitto/acl
EOF

sudo systemctl restart mosquitto

# Publicar y suscribir en localhost:
mosquitto_pub -h 127.0.0.1 -t "campo/temperatura" -u "sensor" -P "sensor123" -m "Prueba Examen"
mosquitto_sub -h 127.0.0.1 -t "campo/temperatura" -u "sensor" -P "sensor123" -v
```

### 3) Servidor Web en Local:
```bash
mkdir -p ~/miWeb
echo "<h1>Prueba Examen AS</h1>" > ~/miWeb/index.html
cd ~/miWeb && sudo python3 -m http.server 80 &
curl http://127.0.0.1:80
```
