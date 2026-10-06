# Soluciones y Respuestas: Laboratorio 3 - Monitorización

**Asignatura:** Administración de Sistemas  
**Temario:** Tema 1.3 - Monitorización, Gestión de Recursos, Profiling y Logs  
**Estado para el examen:**
- **QUÉ NO ENTRA EN EL EXAMEN:**
  1. **Apartado 4 ("Monitorización en Google Cloud Platform"):** **EXCLUIDO EXPLÍCITAMENTE**. En la diapositiva 3 de `Preparación examen.pdf` se especifica de forma textual: *"Contenido excluido del examen: ... Funciones de monitorización de Google Cloud. Vistas en Laboratorio 3 (Monitorización), apartado 4."* No se evalúan dashboards gráficos ni la interfaz web de GCP.
  2. **Esquema de red en parejas con 2 MVs (Apartado 1, puntos 9, 10 y 11):** En el examen se dispone de **UNA SOLA máquina virtual** (*"Creación de varias máquinas virtuales: El examen se podrá hacer con sólo 1"*). Por ello, la coordinación entre compañeros o dos instancias no se evalúa como tal. Sin embargo, los comandos individuales (`nc`, `nethogs`, `scp`, `dd`) **sí pueden preguntarse** ejecutados en local (`localhost` / `127.0.0.1`) o a nivel conceptual. Por tanto, se resuelven en ambos modos.
- **QUÉ SÍ ENTRA AL 100%:**
  - **Apartado 1 (Puntos 1 a 8):** Gestión de procesos, señales (`SIGSTOP`, `SIGCONT`), prioridades (`nice`, `renice`), límites de recursos (`ulimit`, `limits.conf`) y tareas periódicas con `cron`.
  - **Apartado 2 (Puntos 1 a 8):** Análisis de rendimiento y optimización de código Python (`time`, `cProfile`, estructuras hash y complejidad algorítmica).
  - **Apartado 3 (Puntos 1 a 4):** Registros del sistema (`logger`, configuración de `rsyslog` y rotación con `logrotate`).

---

## 1. Gestión de recursos del sistema

### 1) Obtener el número de procesos en ejecución en el sistema
```bash
ps -eo pid --no-headers | wc -l
# O con pgrep:
pgrep -c .
# Alternativa:
ps -e | tail -n +2 | wc -l
```
- **Explicación:** `ps -eo pid --no-headers` lista únicamente la columna de PID sin la fila de encabezado, y `wc -l` cuenta el número total de líneas (procesos activos).

---

### 2) Obtener el número de procesos en ejecución que pertenezcan al usuario root
```bash
ps -u root --no-headers | wc -l
# Alternativa con pgrep:
pgrep -u root -c
```
- **Explicación:** El parámetro `-u root` filtra los procesos cuyo usuario efectivo o real sea `root`.

---

### 3) Instalar “stress-ng” y ejecutar benchmark para 1 núcleo de CPU durante 20 segundos
```bash
sudo apt update && sudo apt install -y stress-ng
stress-ng --cpu 1 --timeout 20s --metrics-brief
```
- **Explicación:** `--cpu 1` genera carga en 1 worker/hilo de CPU; `--timeout 20s` finaliza automáticamente tras 20 segundos; `--metrics-brief` muestra un resumen del rendimiento (operaciones bogo por segundo).

---

### 4) Ejecutar “stress-ng” sin límite de tiempo y manipular su ejecución

Lanzamos el proceso en segundo plano:
```bash
stress-ng --cpu 1 &
# Obtenemos su PID (por ejemplo, con $! o con pgrep):
STRESS_PID=$!
echo "PID de stress-ng: $STRESS_PID"
```

#### a. Pausar su ejecución con una señal:
```bash
kill -STOP $STRESS_PID
# o bien:
kill -SIGSTOP $STRESS_PID
```
- **Comprobación:**
  ```bash
  ps -o pid,stat,comm -p $STRESS_PID
  ```
  El proceso pasa al estado `T` (*Stopped / paused*). En `top` el uso de CPU desciende inmediatamente al 0%.

#### b. Reanudar su ejecución con una señal:
```bash
kill -CONT $STRESS_PID
# o bien:
kill -SIGCONT $STRESS_PID
```
- **Comprobación:**
  El proceso vuelve al estado `R` (*Running*) y recupera el 100% de uso del núcleo de CPU.

#### c. Reducir la prioridad del proceso al mínimo. ¿Cambia algo?
En Linux, la prioridad de usuario se gestiona mediante el valor de **nice**, que abarca de `-20` (máxima prioridad) a `+19` (mínima prioridad).
```bash
renice +19 -p $STRESS_PID
```
- **¿Cambia algo?**
  - **Si no hay otros procesos compitiendo por la CPU:** **No cambia su consumo**. El proceso seguirá consumiendo el 100% de ese núcleo porque ningún otro hilo necesita tiempo de computación (el scheduler CFS de Linux no desperdicia ciclos de reloj).
  - **Si entran otros procesos en ejecución (con prioridad estándar nice = 0):** El planificador penalizará fuertemente a `stress-ng` (nice +19), otorgándole únicamente una mínima fracción del tiempo de CPU disponible (aproximadamente el 5% o menos) y cediendo el restante 95%+ a los procesos de mayor prioridad.

Para terminar el proceso al finalizar la prueba:
```bash
kill -9 $STRESS_PID
```

---

### 5) Detectar qué proceso tiene la mayor prioridad en el sistema. Buscar su propósito
```bash
ps -eo pid,ni,pri,rtprio,comm --sort=-rtprio,-pri 2>/dev/null | head -n 15
```
- **Respuesta y propósito:**
  En Linux existen dos escalas de prioridades:
  1. **Procesos en Tiempo Real (RT):** Planificados con las políticas `SCHED_FIFO` o `SCHED_RR`. Su prioridad interna se sitúa entre 0 y 99 (en `top` aparecen como `PR: rt` o números negativos).
  2. **Procesos normales:** Planificados con el planificador CFS (*Completely Fair Scheduler*), gobernados por el valor de `nice` (-20 a +19).

  Los procesos con mayor prioridad son hilos internos del núcleo (*kthreads*) en tiempo real, tales como:
  - **`migration/N`:** Encargado de balancear la carga entre los diferentes núcleos de CPU migrando tareas de forma inmediata cuando un núcleo se satura.
  - **`watchdog/N`:** Temporizador de alta prioridad por software/hardware que comprueba que ningún hilo bloquee el procesador en bucles infinitos no interrumpibles.
  - **`ksoftirqd/N`:** Procesa las interrupciones por software del sistema (tarjeta de red, disco, etc.).

  **Propósito:** Garantizar que las funciones vitales del sistema operativo y la atención a eventos hardware se atiendan antes que cualquier proceso de espacio de usuario.

---

### 6) Limitar el máximo tiempo de uso de CPU a 5 minutos para todos los usuarios

- **A nivel de sesión interactiva (temporal):**
  ```bash
  ulimit -t 300
  ```
  *(5 minutos $\times$ 60 segundos = 300 segundos).*

- **A nivel de sistema global y persistente (para todos los usuarios):**
  Editar el archivo de configuración del módulo PAM `/etc/security/limits.conf`:
  ```bash
  sudo nano /etc/security/limits.conf
  ```
  Añadir las siguientes líneas al final:
  ```text
  *    soft    cpu    5
  *    hard    cpu    5
  ```
  > **Nota:** En `/etc/security/limits.conf`, el parámetro `cpu` se especifica en **minutos**. El asterisco `*` aplica la regla a todos los usuarios del sistema.

---

### 7) Crear un fichero crontab para el usuario root con tareas periódicas

Abrir el crontab de root:
```bash
sudo crontab -e
```
Añadir las siguientes líneas:
```cron
# a. Ejecutar date cada minuto y añadir su salida a /tmp/date.log
* * * * * date >> /tmp/date.log 2>&1

# b. Borrar el directorio /tmp los primeros 5 días de cada mes a las 17:00
0 17 1-5 * * rm -rf /tmp/*
```
- **Explicación de sintaxis cron:**
  - `* * * * *`: minuto, hora, día del mes, mes, día de la semana. Al tener todos asteriscos, se ejecuta al inicio de cada minuto.
  - `0 17 1-5 * *`: minuto 0, hora 17 (17:00), días del 1 al 5 (`1-5`), cualquier mes (`*`), cualquier día de la semana (`*`).
  - `>>`: redirige añadiendo al final (*append*), evitando sobrescribir el fichero.

---

### 8) Comprobar que las tareas de cron funcionan correctamente
Tras esperar al menos 1 o 2 minutos:
```bash
cat /tmp/date.log
```
Debe mostrar una nueva marca de fecha y hora generada cada minuto:
```text
Tue Oct  6 15:35:01 CEST 2026
Tue Oct  6 15:36:01 CEST 2026
```
También se pueden verificar las ejecuciones en el log del sistema:
```bash
sudo grep CRON /var/log/syslog
```

---

### Tareas 9, 10 y 11: Conexiones de red (Netcat, Nethogs y SCP)

*(Recordatorio de examen: El examen se realiza en 1 sola máquina virtual. A continuación se detalla cómo ejecutar y comprobar estos comandos tanto en 1 sola máquina mediante loopback `127.0.0.1` como entre 2 máquinas).*

#### 9) Comunicación interactiva con Netcat en puerto 3000
- **En la máquina/terminal receptor (A):**
  ```bash
  nc -l -p 3000
  ```
- **En la máquina/terminal emisor (B):**
  ```bash
  nc 127.0.0.1 3000   # (o nc <IP_DE_A> 3000 si fuesen dos máquinas)
  ```
  B escribe: `Hola A` y pulsa Enter. En la terminal de A se recibe el mensaje. A responde `Hola B` y cualquiera de los dos pulsa `Ctrl+C` o `Ctrl+D` para cerrar la conexión.

#### 10) Flujo con `dd if=/dev/urandom` y monitorización con `nethogs`
- **Receptor (A):**
  ```bash
  nc -l -p 3000 > /dev/null
  ```
- **Emisor (B):**
  ```bash
  dd if=/dev/urandom | nc 127.0.0.1 3000   # (o IP remota)
  ```
- **Monitorización con `nethogs`:**
  En otra terminal (tanto en A como en B):
  ```bash
  sudo apt install -y nethogs
  sudo nethogs lo    # (o nethogs eth0 si es interfaz de red física)
  ```
- **¿Los valores coinciden?**
  **Sí, coinciden**. Los bytes enviados por segundo por el proceso `nc` de B coinciden con los bytes por segundo recibidos por el proceso `nc` de A (con una diferencia mínima y despreciable debida al *overhead* de cabeceras de paquetes TCP/IP).

#### 11) Enviar fichero con Netcat vs SCP
- **Envío con Netcat:**
  - Receptor: `nc -l -p 3000 > fichero_recibido.txt`
  - Emisor: `nc <IP> 3000 < fichero_original.txt`
- **Envío con SCP:**
  ```bash
  scp fichero_original.txt usuario@<IP>:/ruta/destino/fichero_recibido.txt
  ```
- **¿Qué diferencia hay entre utilizar netcat y scp para enviar ficheros?**
  | Característica | Netcat (`nc`) | SCP (`scp`) |
  |---|---|---|
  | **Seguridad y cifrado** | Texto plano, sin cifrar, vulnerable a intercepción (*sniffing*). | Cifrado punto a punto mediante SSH (TLS/AES). |
  | **Autenticación** | Ninguna. Cualquiera conectado al puerto puede leer/escribir. | Requiere autenticación de usuario (claves SSH o contraseña). |
  | **Metadatos** | Solo transmite el flujo binario bruto. No transfiere nombres, permisos ni fechas. | Preserva nombre, permisos, propietarios y atributos del fichero (`-p`). |
  | **Integridad** | No incluye validación criptográfica de integridad. | Comprobación de integridad de bloques mediante HMAC/SSH. |
  | **Rendimiento** | Ligeramente más rápido por carecer de sobrecarga criptográfica. | Mínimo impacto por cálculo del cifrado. |

---

## 2. Análisis y mejora de rendimiento

Código base proporcionado en `https://github.com/ulopeznovoa/AS-profiling` (`analisis.py`):
```python
import random
import sys

def generar_datos(numero_elementos):
    random.seed(33)
    return [
        random.randint(1, numero_elementos // 5)
        for _ in range(numero_elementos)
    ]

def obtener_elementos_unicos(datos):
    unicos = []
    for elemento in datos:
        if elemento not in unicos:
            unicos.append(elemento)
    return unicos

def contar_elementos(datos, unicos):
    frecuencias = {}
    for elemento in unicos:
        frecuencias[elemento] = datos.count(elemento)
    return frecuencias

def analizar(numero_elementos):
    datos = generar_datos(numero_elementos)
    unicos = obtener_elementos_unicos(datos)
    frecuencias = contar_elementos(datos, unicos)
    print(f"Elementos procesados: {len(datos)}")
    print(f"Elementos diferentes: {len(unicos)}")
    print(f"Frecuencia total: {sum(frecuencias.values())}")

if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 30000
    analizar(n)
```

### 1) ¿Cuál es el objetivo del programa? ¿Qué realiza cada función?
- **Objetivo global:** Procesar una muestra de números pseudoaleatorios, identificar los valores únicos existentes y calcular la frecuencia de repetición de cada número, mostrando un resumen de elementos procesados, diferentes y el acumulado.
- **`generar_datos(numero_elementos)`:** Crea una lista de enteros en el rango $[1, \lfloor N/5 \rfloor]$ mediante una semilla estática.
- **`obtener_elementos_unicos(datos)`:** Elimina duplicados recorriendo la lista elemento a elemento y añadiéndolos a una nueva lista si no se encuentran en ella.
- **`contar_elementos(datos, unicos)`:** Construye un diccionario calculando cuántas veces aparece cada valor único en la lista completa mediante `datos.count(elemento)`.
- **`analizar(numero_elementos)`:** Orquesta el flujo de ejecución e imprime los resultados por pantalla.

---

### 2) En la línea 6, ¿por qué se establece explícitamente la semilla mediante `random.seed(33)`?
- **Respuesta:** Para garantizar el **determinismo y reproducibilidad** del benchmark. Al fijar la semilla, cualquier ejecución futura del programa con el mismo argumento generará de forma idéntica la misma secuencia pseudoaleatoria, permitiendo comparar los tiempos de ejecución de diferentes algoritmos sobre el mismo conjunto de datos sin que la aleatoriedad distorsione las métricas.

---

### 3) Tiempo de ejecución real, de CPU en modo usuario y en modo sistema
Ejecutando con `/usr/bin/time -v python3 analisis.py 8000`:
- **Tiempo real (wall clock time):** `0.38 s`
- **Tiempo de CPU en modo usuario:** `0.36 s`
- **Tiempo de CPU en modo sistema:** `0.01 s`

---

### 4) ¿Cómo varía el tiempo de ejecución en función del parámetro? ¿Hay relación lineal?
- **Respuesta:** **NO hay relación lineal, la relación es CUADRÁTICA $O(N^2)$**.
- **Justificación matemática y empírica:**
  - Para $N = 8.000$, tarda `~0.38 s`.
  - Para $N = 30.000$ ($3.75\times$ elementos), tarda `~4.30 s` ($11.3\times$ tiempo).
  - En `obtener_elementos_unicos`: Para cada elemento de la lista ($N$), la instrucción `if elemento not in unicos` realiza una búsqueda lineal en una lista que crece hasta $U \approx N/5$ elementos. Complejidad: $O(N \cdot U) = O(N^2)$.
  - En `contar_elementos`: Para cada elemento de los $U \approx N/5$ únicos, invoca `datos.count(elemento)`, el cual recorre los $N$ elementos de la lista original. Complejidad: $O(U \cdot N) = O(\frac{N^2}{5}) = O(N^2)$.
  - Al duplicar $N$, el tiempo se multiplica por cuatro ($2^2 = 4$).

---

### 5) ¿Cuál es el máximo de memoria utilizada?
Medido mediante la clave `Maximum resident set size (kbytes)` de `/usr/bin/time -v`:
- Para $N = 8.000$: **`10.964 KB`** ($\approx 10.9 \text{ MB}$).
- Para $N = 30.000$: **`11.540 KB`** ($\approx 11.5 \text{ MB}$).

---

### 6) Análisis con `cProfile`: Funciones que ocupan la mayoría del tiempo
Comando:
```bash
python3 -m cProfile -s tottime analisis.py 8000
```
- **Resultados:**
  1. `{method 'count' of 'list' objects}`: Se llama **1.592 veces** (una por cada elemento único) y consume **0.262 s** (más del **71%** del tiempo total del programa).
  2. `obtener_elementos_unicos`: Se llama 1 vez y consume **0.072 s** (casi el **20%** del tiempo) por la comprobación lineal `in`.
  Entre ambas operaciones acaparan más del **91% del tiempo de ejecución total**.

---

### 7 y 8) Profiling con `pyinstrument` y Optimización del Código

#### Instalación y uso de `pyinstrument`:
```bash
pip install pyinstrument
pyinstrument analisis.py 8000
```
- **Diferencias respecto a `cProfile`:** `cProfile` genera una tabla estática plana listando funciones por número de llamadas y tiempo acumulado, mientras que `pyinstrument` utiliza un muestreador estadístico (*sampling profiler*) que muestra un **árbol jerárquico de llamadas coloreado**, destacando visualmente la ruta crítica de llamadas (*hot paths*) y ocultando llamadas internas irrelevantes del runtime de Python.

#### Código Optimizado (`analisis_optimizado.py`):
Se sustituyen las listas lineales por tablas hash de Python con complejidad temporal $O(1)$:
- `obtener_elementos_unicos`: `list(dict.fromkeys(datos))` -> $O(N)$.
- `contar_elementos`: `Counter(datos)` -> $O(N)$.

```python
#!/usr/bin/env python3
import random
import sys
from collections import Counter

def generar_datos(numero_elementos):
    random.seed(33)
    return [
        random.randint(1, numero_elementos // 5)
        for _ in range(numero_elementos)
    ]

def obtener_elementos_unicos(datos):
    return list(dict.fromkeys(datos))

def contar_elementos(datos, unicos):
    return Counter(datos)

def analizar(numero_elementos):
    datos = generar_datos(numero_elementos)
    unicos = obtener_elementos_unicos(datos)
    frecuencias = contar_elementos(datos, unicos)

    print(f"Elementos procesados: {len(datos)}")
    print(f"Elementos diferentes: {len(unicos)}")
    print(f"Frecuencia total: {sum(frecuencias.values())}")

if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 30000
    analizar(n)
```

#### Tabla comparativa de resultados ($N = 30.000$):
| Métrica | Versión Original | Versión Optimizada |
|---|---|---|
| **Tiempo real** | 4.30 s | 0.08 s |
| **Tiempo de usuario** | 4.28 s | 0.06 s |
| **Memoria residente máxima** | 11.540 KB | 12.504 KB |

- **Factor de Aceleración conseguido:**
  $$\text{Speedup} = \frac{4.30\text{ s}}{0.08\text{ s}} \approx \mathbf{53.75\times}$$

#### Reflexiones finales:
- **¿Qué modificación ha producido la mayor mejora? ¿Por qué?**
  Sustituir el bucle de `datos.count(elemento)` y `if elemento not in unicos` por estructuras basadas en tablas hash (`Counter` y `dict.fromkeys`). Esto reduce la complejidad algorítmica de **$O(N^2)$ a $O(N)$ lineal**.
- **¿Cuál es la función que consume más tiempo ahora?**
  `generar_datos()` (específicamente las llamadas a `random.randint`), ya que la generación de números pseudoaleatorios pasa a ser el único cuello de botella una vez resuelta la ineficiencia de procesado.
- **¿Ha aumentado o disminuido el consumo máximo de memoria?**
  El consumo de memoria se mantiene prácticamente inalterado (aumento insignificante de menos de 1 MB para almacenar las claves de la tabla hash de `Counter`).

---

## 3. Gestión de los registros del sistema

### 1) Página de manual de logger: ¿Con qué parámetro se indica la prioridad?
```bash
man logger
```
- **Respuesta:** Se indica con el parámetro **`-p`** (o `--priority`). Su formato es `facility.level`, por ejemplo `-p user.info` o `-p local0.err`.

---

### 2) Enviar el mensaje “Hola Mundo de Logs” al fichero `/var/log/syslog`
```bash
logger -t MiPrueba "Hola Mundo de Logs"
```
- **Comprobación:**
  ```bash
  sudo grep "Hola Mundo de Logs" /var/log/syslog
  ```

---

### 3) Enviar todos los mensajes “debug” de `sshd` a `/var/log/ssh.log`

#### 1. Crear el fichero vacío con los permisos adecuados:
```bash
sudo touch /var/log/ssh.log
sudo chmod 640 /var/log/ssh.log
sudo chown syslog:adm /var/log/ssh.log
```

#### 2. Configurar la redirección en `rsyslog`:
Crear el archivo de configuración `/etc/rsyslog.d/20-sshd-debug.conf`:
```bash
sudo tee /etc/rsyslog.d/20-sshd-debug.conf << 'EOF'
if $programname == 'sshd' and $syslogseverity-text == 'debug' then /var/log/ssh.log
EOF
```

#### 3. Configurar el servicio `sshd` para emitir en modo DEBUG:
Editar `/etc/ssh/sshd_config`:
```bash
sudo nano /etc/ssh/sshd_config
```
Añadir o modificar la directiva:
```text
LogLevel DEBUG
```

#### 4. Reiniciar los servicios:
```bash
sudo systemctl restart rsyslog
sudo systemctl restart ssh
```

#### 5. Comprobación:
Generar una conexión o intento de conexión SSH:
```bash
ssh localhost
```
Verificar los registros generados en el nuevo fichero:
```bash
cat /var/log/ssh.log
```

---

### 4) Configurar rotación de logs de `/var/log/syslog` mensual, comprimida, para 1 año en `/var/log/syslog.old`

#### 1. Crear el directorio de destino:
```bash
sudo mkdir -p /var/log/syslog.old
```

#### 2. Crear la configuración en `/etc/logrotate.d/syslog_mensual`:
```bash
sudo tee /etc/logrotate.d/syslog_mensual << 'EOF'
/var/log/syslog {
    monthly
    rotate 12
    compress
    missingok
    notifempty
    olddir /var/log/syslog.old
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF
```
- **Explicación de las directivas:**
  - `monthly`: rota una vez al mes.
  - `rotate 12`: mantiene 12 rotaciones históricas (1 año completo).
  - `compress`: comprime los ficheros rotados con gzip (`.gz`).
  - `missingok`: no emite error si el fichero no existe en un momento dado.
  - `notifempty`: no rota el fichero si está vacío.
  - `olddir /var/log/syslog.old`: almacena los ficheros rotados en dicha carpeta.
  - `postrotate`: envía señal a rsyslog para reabrir el descriptor del fichero nuevo.

#### 3. Probar la configuración con ejecución de prueba (*dry-run*):
```bash
sudo logrotate -d /etc/logrotate.d/syslog_mensual
```
*(El modificador `-d` simula la ejecución sin realizar modificaciones en los archivos reales).*

---

## 4. Monitorización en Google Cloud Platform

> **[!NOTE]**
> **ESTE APARTADO NO ENTRA EN EL EXAMEN.**
> Tal y como figura en las instrucciones oficiales de `Preparación examen.pdf` (Diapositiva 3):
> *"Contenido excluido del examen: Funciones de monitorización de Google Cloud. Vistas en Laboratorio 3 (Monitorización), apartado 4."*
> El examen se enfoca estrictamente en la resolución de problemas mediante la consola y terminal de Linux.
