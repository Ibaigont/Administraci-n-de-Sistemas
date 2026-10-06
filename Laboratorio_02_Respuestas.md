# Soluciones y Respuestas: Laboratorio 2 - Sistemas de Ficheros

**Asignatura:** Administración de Sistemas  
**Temario:** Tema 1.2 - Sistemas de Ficheros (Particionado, LVM, RAID, Copias de Seguridad)  
**Estado para el examen:** **TODO EL NÚCLEO TÉCNICO ENTRA EN EL EXAMEN**.
- **Qué entra:** El particionado (`fdisk`, `parted`), formateo de sistemas de ficheros (`ext4`, `btrfs`, `xfs`), montaje estático y automático (`/etc/fstab`), redimensión de sistemas de ficheros (`resize2fs`), gestión completa de LVM (`pvcreate`, `vgcreate`, `lvcreate`, `lvextend`), RAID con `mdadm` y copias de seguridad con `rsnapshot`. (De hecho, el Ejercicio 2 del modelo de examen oficial evalúa exactamente particiones, fstab y LVM).
- **Qué aspectos de infraestructura web quedan excluidos:** La adquisición de discos SSD adicionales a través de la consola web de Google Cloud Platform y la consulta de tablas de facturación/precios en la web de GCP (Apartado 3, puntos 2 y 8) son detalles de la nube que no se exigen en el examen práctico de terminal en una sola MV. Sin embargo, los comandos de estrés con `fio` y las preguntas conceptuales sobre I/O y sistemas de ficheros sí se detallan aquí al completo.

---

## 1. Configuración del entorno

Para realizar las prácticas se requiere un disco virtual secundario (en los ejemplos se asume `/dev/sdb` de 10 GB).
Para identificar el nombre del disco:
```bash
lsblk
sudo fdisk -l
```

---

## 2. Gestión básica

### 1) Crear 4 particiones de 1 GB cada una y formatearlas: ext3, btrfs, xfs y ext4

#### Creación de particiones con `fdisk`:
```bash
sudo fdisk /dev/sdb
```
Dentro del intérprete interactivo de `fdisk`:
1. `n` -> `p` -> `1` -> Primer sector por defecto -> `+1G`
2. `n` -> `p` -> `2` -> Primer sector por defecto -> `+1G`
3. `n` -> `p` -> `3` -> Primer sector por defecto -> `+1G`
4. `n` -> `p` -> `4` -> Primer sector por defecto -> `+1G`
5. `w` (guardar y escribir la tabla de particiones en el disco)

*Alternativa no interactiva mediante `parted`:*
```bash
sudo parted /dev/sdb --script mklabel gpt \
  mkpart p1 ext3 1MiB 1025MiB \
  mkpart p2 btrfs 1025MiB 2049MiB \
  mkpart p3 xfs 2049MiB 3073MiB \
  mkpart p4 ext4 3073MiB 4097MiB
```

#### Formateo de cada partición:
```bash
sudo mkfs.ext3 /dev/sdb1
sudo mkfs.btrfs -f /dev/sdb2
sudo mkfs.xfs -f /dev/sdb3
sudo mkfs.ext4 /dev/sdb4
```

---

### 2) Configurar montaje automático en el arranque en `/disco[X]` (X = 1, 2, 3, 4)

#### Crear los puntos de montaje:
```bash
sudo mkdir -p /disco1 /disco2 /disco3 /disco4
```

#### Obtener los UUIDs:
```bash
sudo blkid /dev/sdb1 /dev/sdb2 /dev/sdb3 /dev/sdb4
```
*Ejemplo de salida:*
```text
/dev/sdb1: UUID="a1111111-..." TYPE="ext3"
/dev/sdb2: UUID="b2222222-..." TYPE="btrfs"
/dev/sdb3: UUID="c3333333-..." TYPE="xfs"
/dev/sdb4: UUID="d4444444-..." TYPE="ext4"
```

#### Configurar `/etc/fstab`:
Añadir al final del archivo `/etc/fstab` (utilizando `sudo nano /etc/fstab` o `sudo vim /etc/fstab`):
```text
UUID=a1111111-...  /disco1  ext3   defaults,nofail  0  2
UUID=b2222222-...  /disco2  btrfs  defaults,nofail  0  0
UUID=c3333333-...  /disco3  xfs    defaults,nofail  0  0
UUID=d4444444-...  /disco4  ext4   defaults,nofail  0  2
```
> **Nota técnica:** La opción `nofail` es una buena práctica imprescindible en máquinas virtuales: si el disco no estuviese presente al arrancar, el sistema no se quedará bloqueado en modo de emergencia.

#### Verificar el montaje sin reiniciar:
```bash
sudo mount -a
df -h | grep disco
```

---

### 3) Meta-información: ¿Cuál de los sistemas de ficheros creados utiliza más espacio?

- **Comprobación:**
  ```bash
  df -m /disco1 /disco2 /disco3 /disco4
  ```
- **Respuesta:**
  Por regla general, **Btrfs o XFS** consumen mayor espacio inicial en metadatos que ext3/ext4:
  1. **Btrfs:** Utiliza estructuras de árbol B (*B-Trees*) y, de forma predeterminada, duplica los metadatos (*profile DUP*) para mayor tolerancia a fallos incluso en un disco individual. Además, preasigna bloques enteros (*chunks*) de metadatos (a menudo entre 16 MB y 256 MB según la versión del kernel).
  2. **XFS:** Preasigna grupos de asignación (*Allocation Groups*), árboles B+ para indexación de inodos y bloques libres, y un diario interno (*journal/log*) de al menos 32 MB.
  3. **ext3 / ext4:** Reservan la tabla de inodos estática (aproximadamente un inodo cada 16 KB) y el *journal* (típicamente 32 a 64 MB para 1 GB), ocupando habitualmente entre 30 y 45 MB.

---

### 4) ¿Es posible acceder a una partición ext3 montada como ext4? ¿Y al revés? ¿Por qué?

1. **Montar una partición ext3 como ext4:**
   - **SÍ es posible.**
   - **Por qué:** El subsistema ext4 del núcleo Linux posee compatibilidad retroactiva hacia atrás (*backward compatibility*). El driver de ext4 es capaz de interpretar sin problemas el formato de disco de ext3 mientras no se habiliten características específicas que modifiquen el formato físico de inodos y bloques.

2. **Montar una partición ext4 como ext3:**
   - **NO es posible** (de forma predeterminada).
   - **Por qué:** Los sistemas de ficheros ext4 activan de forma predeterminada banderas de características incompatibles (*incompatible feature flags*) en el superbloque, tales como **extents** (que sustituyen el direccionamiento indirecto de bloques tradicional), soporte para ficheros mayores a 2 TB (`huge_file`), inodos de 256 bytes o checksums de metadatos (`metadata_csum`). Al intentar montarlo con el driver ext3, el kernel detecta estas banderas desconocidas y rechaza el montaje para proteger la integridad de los datos.

---

### 5) Desmontar y borrar las 3 últimas particiones. Crear una única partición ext4 de 8 GB

```bash
# 1. Desmontar
sudo umount /disco2 /disco3 /disco4

# 2. Modificar con fdisk
sudo fdisk /dev/sdb
# Comandos interactivos:
# d -> 2
# d -> 3
# d -> 4
# n -> p -> 2 -> Primer sector por defecto -> +8G
# w

# 3. Formatear la nueva partición ext4
sudo mkfs.ext4 /dev/sdb2
```

---

### 6) Copiar `/var` a la nueva partición ext4 y redimensionarla al mínimo posible

#### 1. Montar y copiar datos:
```bash
sudo mkdir -p /mnt/var_test
sudo mount /dev/sdb2 /mnt/var_test
sudo cp -a /var/* /mnt/var_test/
```
*(El modificador `-a` preserva permisos, propietarios, timestamps y enlaces simbólicos).*

#### 2. Desmontar y verificar el sistema de ficheros:
```bash
sudo umount /mnt/var_test
sudo e2fsck -f /dev/sdb2
```

#### 3. Reducir el sistema de ficheros al mínimo:
> **Regla de oro de redimensión en Linux:**
> - Para **aumentar**: primero se amplía la partición y luego el sistema de ficheros.
> - Para **reducir**: primero se reduce el sistema de ficheros (`resize2fs`) y luego la partición.

```bash
sudo resize2fs -M /dev/sdb2
```
*Salida representativa:*
```text
Resizing the filesystem on /dev/sdb2 to 142560 (4k) blocks.
The filesystem on /dev/sdb2 is now 142560 blocks (4k) long.
```

#### 4. Reducir la partición en disco:
Calculamos el tamaño necesario: $142560 \times 4096 \text{ bytes} \approx 584 \text{ MB}$. Por seguridad, dejamos un margen (p.e. 800 MB o 1 GB).
```bash
sudo parted /dev/sdb resizepart 2 1825MiB
```
O con `fdisk` borrando la partición 2 y recreándola con el nuevo tamaño seguro comenzando en el mismo sector inicial.

#### 5. Ajustar el sistema de ficheros al tamaño final de la partición:
```bash
sudo resize2fs /dev/sdb2
```

---

### 7) Eliminar la configuración de montaje automático
Editar `/etc/fstab` y borrar las líneas correspondientes a `/disco1`, `/disco2`, `/disco3` y `/disco4`.
Desmontar `/disco1` si seguía montado:
```bash
sudo umount /disco1
```

---

## 3. Comparativa de rendimiento (`fio`)

### Parámetros de prueba con `fio`:
Instalación:
```bash
sudo apt update && sudo apt install -y fio
```

#### Medición de IOPS y velocidad de Escritura Aleatoria:
```bash
sudo fio --name=test_randwrite \
  --filename=/discoBalanceado/fio_test \
  --ioengine=libaio \
  --direct=1 \
  --rw=randwrite \
  --bs=4k \
  --iodepth=256 \
  --size=1G \
  --runtime=60 \
  --time_based \
  --group_reporting
```

#### Medición de IOPS y velocidad de Lectura Aleatoria:
```bash
sudo fio --name=test_randread \
  --filename=/discoBalanceado/fio_test \
  --ioengine=libaio \
  --direct=1 \
  --rw=randread \
  --bs=4k \
  --iodepth=256 \
  --size=1G \
  --runtime=60 \
  --time_based \
  --group_reporting
```

### Respuestas a las preguntas conceptuales:
- **Diferencia entre disco balanceado y SSD:** Los discos SSD alcanzan una tasa de IOPS y ancho de banda (MB/s) drásticamente superior en operaciones aleatorias de 4 KB (frecuentemente órdenes de magnitud mayor), debido a la ausencia de latencias mecánicas de búsqueda y los límites de rendimiento aprovisionados en la nube.
- **Variación de Lectura vs Escritura:** En dispositivos de estado sólido, la lectura aleatoria suele ofrecer latencias inferiores y mayor rendimiento sostenido frente a la escritura aleatoria, ya que escribir requiere ciclos de borrado de bloques en memoria NAND flash.

---

## 4. LVM y RAID

### 4.1 LVM (Logical Volume Manager)

#### 1) Crear volúmenes físicos (PV) y grupo de volúmenes (VG):
Suponiendo 4 particiones creadas (`/dev/sdb1`, `/dev/sdb2`, `/dev/sdb3`, `/dev/sdb4` de 2 GB cada una):
```bash
sudo pvcreate /dev/sdb1 /dev/sdb2 /dev/sdb3
sudo vgcreate vg_datos /dev/sdb1 /dev/sdb2 /dev/sdb3
```

#### 2) Crear el volumen lógico (LV) con el 100% del espacio libre:
```bash
sudo lvcreate -l 100%FREE -n lv_almacen vg_datos
```

#### 3) Formatear como ext4 y montar:
```bash
sudo mkfs.ext4 /dev/vg_datos/lv_almacen
sudo mkdir -p /miVolumen
sudo mount /dev/vg_datos/lv_almacen /miVolumen
```

#### 4) Copiar datos y crear fichero de 50 MB:
```bash
sudo dd if=/dev/urandom of=/miVolumen/fichero50M.img bs=1M count=50
ls -lh /miVolumen/fichero50M.img
```

#### 5) Añadir la 4ª partición y extender el volumen lógico y el sistema de ficheros:
```bash
sudo pvcreate /dev/sdb4
sudo vgextend vg_datos /dev/sdb4
# El flag -r (--resizefs) amplía automáticamente el sistema de ficheros al nuevo tamaño:
sudo lvextend -r -l +100%FREE /dev/vg_datos/lv_almacen
```
Verificar que los datos siguen existiendo:
```bash
ls -lh /miVolumen/fichero50M.img
df -h /miVolumen
```

#### 6) Eliminar el volumen lógico y limpiar LVM:
```bash
sudo umount /miVolumen
sudo lvremove -y /dev/vg_datos/lv_almacen
sudo vgremove vg_datos
sudo pvremove /dev/sdb1 /dev/sdb2 /dev/sdb3 /dev/sdb4
```

---

### 4.2 RAID con `mdadm`

#### 1) Instalar la herramienta:
```bash
sudo apt update && sudo apt install -y mdadm
```

#### 2) Crear un sistema RAID 5 con 3 particiones:
```bash
sudo mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sdb1 /dev/sdb2 /dev/sdb3
```
Verificar el estado inicial del RAID:
```bash
cat /proc/mdstat
sudo mdadm --detail /dev/md0
```

#### 3) Crear sistema de ficheros ext4 y copiar `/var`:
```bash
sudo mkfs.ext4 /dev/md0
sudo mkdir -p /discoRaid
sudo mount /dev/md0 /discoRaid
sudo cp -a /var/* /discoRaid/
```

#### 4) Simular un fallo en el 3er disco (`-f`):
```bash
sudo mdadm /dev/md0 --fail /dev/sdb3
cat /proc/mdstat
# El array se marcará en estado degraded [U_U]
```

#### 5) Reemplazar y recuperar la información con la partición libre:
```bash
sudo mdadm /dev/md0 --add /dev/sdb4
cat /proc/mdstat
# Se observará el proceso de reconstrucción (recovery / resync).
```
Una vez terminado el resync, los datos de `/discoRaid` permanecen completamente accesibles e intactos.

#### 6) Desmontar y eliminar el dispositivo RAID:
```bash
sudo umount /discoRaid
sudo mdadm --stop /dev/md0
sudo mdadm --zero-superblock /dev/sdb1 /dev/sdb2 /dev/sdb3 /dev/sdb4
```

---

## 5. Copias de seguridad con `rsnapshot`

### 1) Preparar punto de montaje:
```bash
sudo mkdir -p /backups
sudo mount /dev/sdb1 /backups
```

### 2) Instalar `rsnapshot`:
```bash
sudo apt update && sudo apt install -y rsnapshot
```

### 3) Configurar `/etc/rsnapshot.conf`:
> **¡Atención!** El fichero `/etc/rsnapshot.conf` **requiere tabuladores (`\t`)** entre comandos y argumentos. Si se colocan espacios corrientes, `rsnapshot configtest` fallará.

Editar `/etc/rsnapshot.conf` y asegurarse de los siguientes parámetros clave:
```text
snapshot_root	/backups/

retain	horaria	24
retain	diaria	7
retain	semanal	4

backup	/home/		localhost/
backup	/etc/		localhost/
backup	/var/log/	localhost/
```

### 4) Comprobar la sintaxis:
```bash
sudo rsnapshot configtest
```
*Debe responder:* `Syntax OK`.

### 5) Ejecutar la primera copia horaria:
```bash
sudo rsnapshot horaria
ls -la /backups/horaria.0/localhost/
```

### 6) Crear un nuevo fichero y realizar la segunda copia horaria:
```bash
echo "Archivo de prueba para backup incremental" > /home/$USER/prueba_backup.txt
sudo rsnapshot horaria
```

### 7) Analizar diferencias con `rsnapshot-diff`:
```bash
sudo rsnapshot-diff /backups/horaria.1 /backups/horaria.0
```
- **Resultado:** Mostrará únicamente los ficheros nuevos o modificados (como `prueba_backup.txt`). Los ficheros inalterados comparten inodos mediante enlaces duros (*hard links*), ahorrando espacio de almacenamiento de forma transparente.
