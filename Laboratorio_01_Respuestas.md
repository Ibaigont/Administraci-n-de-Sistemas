# Soluciones y Respuestas: Laboratorio 1 - Administración Linux y Shell Scripting

**Asignatura:** Administración de Sistemas  
**Temario:** Tema 1 - Administración Linux y Línea de Comandos  
**Estado para el examen:** **TODO EL LABORATORIO ENTRA EN EL EXAMEN**. Todos los ejercicios se realizan de manera local en una única máquina virtual con Bash y herramientas estándar de administración del sistema.

---

## 1. Línea de comandos

### 1.1 Utilizando el manual del sistema

El manual de Linux (`man`) utiliza internamente un visor de texto paginado (habitualmente `less`).

#### 1) Entrar en la consola de la máquina virtual de Linux
- Se inicia sesión en la máquina por SSH o consola local:
  ```bash
  ssh usuario@ip-servidor
  ```

#### 2) Usar `man man` para ver la ayuda del manual
- Comando:
  ```bash
  man man
  ```
- Abre la página del manual que documenta el propio comando `man`.

#### 3) Pulsar ‘h’ para mostrar las teclas y comandos para moverse por las páginas de man
- Mientras estamos dentro de `man`, pulsar la tecla:
  ```text
  h
  ```
- Esto muestra la pantalla de ayuda del paginador `less` con el listado de teclas de navegación y búsqueda. Para salir de la ayuda y volver al manual, pulsar `q`.

#### 4) Salir del manual
- Pulsar la tecla:
  ```text
  q
  ```
- Sale del manual y regresa a la línea de comandos de la shell.

#### 5) Entrar de nuevo en el manual y realizar navegaciones:
- Ejecutar nuevamente: `man man`.
  - **a. Moverse al comienzo y al final de la página:**
    - Al comienzo: pulsar `g` (o `1G` o `Home`).
    - Al final: pulsar `G` (o `End`).
  - **b. Moverse línea a línea arriba y abajo por el documento:**
    - Una línea abajo: pulsar `j` (o la flecha abajo `↓`, o `Enter`).
    - Una línea arriba: pulsar `k` (o la flecha arriba `↑`).
    - Para avanzar una página entera hacia abajo: `Espacio` o `Ctrl+F`. Para retroceder una página entera: `b` o `Ctrl+B`.
  - **c. Buscar la palabra “word” en el documento y navegar por sus ocurrencias:**
    - Escribir `/word` y pulsar `Enter` (busca hacia adelante).
    - Para saltar a la **siguiente ocurrencia**: pulsar `n`.
    - Para saltar a la **ocurrencia anterior**: pulsar `N`.
    - *(Nota: para buscar hacia atrás se usa `?word`)*.
  - **d. Saltar al final del manual y después al comienzo de nuevo:**
    - Saltar al final: pulsar `G`.
    - Saltar al comienzo: pulsar `g` (o `1G`).

---

### 1.2 Gestión y manipulación de archivos

#### 1) Crear una carpeta llamada `AS` en vuestro directorio raíz de usuario
```bash
mkdir -p ~/AS
```
- Explicación: `~` equivale a `$HOME`. El modificador `-p` evita errores si la carpeta ya existe.

#### 2) Entrar dentro de la carpeta y comprobar que el directorio coincide con el contenido de la variable de entorno `PWD`
```bash
cd ~/AS
pwd
echo "$PWD"
# Comprobación automática:
[ "$PWD" = "$(pwd)" ] && echo "Coinciden: $PWD"
```
- Explicación: `pwd` imprime la ruta física/lógica actual y `$PWD` almacena la ruta de trabajo actual en Bash.

#### 3) Instalar `cal` con el comando `apt install ncal`. Utilizar `cal` para mostrar un calendario y redirigir la salida a un fichero de texto. Comprobar que se crea y su contenido
```bash
sudo apt update && sudo apt install -y ncal
cal > calendario.txt
cat calendario.txt
```
- Explicación: El operador `>` redirige la salida estándar (`stdout`) al fichero `calendario.txt`. Con `cat` o `less` se verifica el contenido.

#### 4) Copiar el fichero recién creado al directorio raíz del usuario
```bash
cp calendario.txt ~/
# o de forma explícita:
cp ~/AS/calendario.txt "$HOME/"
```
- Explicación: `cp origen destino`. Al indicar `~/` se copia directamente en el directorio home del usuario.

#### 5) Moverse al directorio raíz del usuario y listar en formato extendido (`-l`) los directorios y archivos presentes. Redirigir esa información a un fichero
```bash
cd ~
ls -l > listado.txt
```
- Explicación: `ls -l` genera el listado detallado (permisos, enlaces, propietario, grupo, tamaño, fecha de modificación y nombre). Se guarda en `listado.txt`.

#### 6) Listar los 5 ficheros más nuevos de la carpeta `/etc` (que no sean carpetas)
```bash
find /etc -maxdepth 1 -type f -printf '%T+ %p\n' 2>/dev/null | sort -r | head -n 5
```
- Alternativa con `ls`:
  ```bash
  ls -lt --time=mtime /etc | grep '^-' | head -n 5
  ```
- Explicación:
  - `-type f` filtra exclusivamente ficheros regulares (excluye directorios, enlaces, sockets).
  - `-printf '%T+ %p\n'` imprime la fecha de modificación en formato ISO seguido de la ruta.
  - `sort -r` ordena de más reciente a más antiguo.
  - `head -n 5` selecciona los 5 primeros.
  - `2>/dev/null` silencia mensajes de advertencia por permisos.

#### 7) Cambiar los permisos del fichero del calendario para que sólo el usuario propietario tenga capacidad de leer y escribir
```bash
chmod 600 ~/calendario.txt
# Notación simbólica equivalente:
chmod u=rw,go= ~/calendario.txt
```
- Verificación:
  ```bash
  ls -l ~/calendario.txt
  # Resultado: -rw------- 1 usuario usuario ... calendario.txt
  ```
- Explicación: `600` otorga `4` (lectura) + `2` (escritura) = `6` al propietario (`u`), y `0` al grupo (`g`) y al resto (`o`).

#### 8) Cambiar permisos para evitar que ningún otro usuario pueda acceder a nuestro directorio raíz
```bash
chmod 700 ~
# Notación simbólica equivalente:
chmod go-rwx ~
```
- Verificación:
  ```bash
  ls -ld ~
  # Resultado: drwx------ ... /home/usuario
  ```
- Explicación: Quitar el bit de ejecución (`x`) en un directorio a un usuario o grupo le impide entrar (`cd`) o acceder a sus inodos. `700` restringe el acceso al 100% únicamente al dueño (y a `root`).

#### 9) Comprobar cuántos usuarios hay en el sistema y cuál es nuestro Shell de inicio
- **Número de usuarios en el sistema:**
  ```bash
  wc -l < /etc/passwd
  # o contando los nombres de usuario únicos:
  cut -d: -f1 /etc/passwd | wc -l
  ```
- **Shell de inicio de nuestro usuario:**
  ```bash
  echo "$SHELL"
  # O consultando directamente la base de datos de usuarios del sistema:
  grep "^$USER:" /etc/passwd | cut -d: -f7
  ```
- Explicación: Cada línea de `/etc/passwd` representa una cuenta. El 7º campo delimitado por `:` indica el shell por defecto.

#### 10) Comprobar cuándo y desde dónde accediste la última vez al sistema
```bash
last -n 2 "$USER"
# O bien:
lastlog -u "$USER"
```
- Explicación: `last` consulta `/var/log/wtmp` y muestra las sesiones anteriores, indicando la IP de origen, terminal (`pts/X`) y fecha/hora. `lastlog` consulta `/var/log/lastlog` con el último acceso registrado.

#### 11) Comprimir en un archivo `.tar.gz` los contenidos del directorio `$HOME`. Descomprimirlos en `/tmp` y comprobar que se ha hecho correctamente
```bash
# 1. Comprimir (excluyendo el propio tar para no generar recursividad si se guardara en el mismo directorio):
tar -czvf /tmp/home_backup.tar.gz -C "$HOME" .

# 2. Descomprimir en una carpeta dentro de /tmp:
mkdir -p /tmp/recuperado
tar -xzvf /tmp/home_backup.tar.gz -C /tmp/recuperado

# 3. Comprobar:
ls -la /tmp/recuperado
```
- Explicación:
  - `-c`: create, `-z`: gzip, `-v`: verbose, `-f`: archivo de destino.
  - `-x`: extract, `-C`: cambiar al directorio destino antes de extraer.

#### 12) Como usuario “root”, buscar todos los archivos que sean propiedad de tu usuario en el sistema (desde `/`) y listarlos en forma extendida
```bash
sudo find / -user "$USER" -ls 2>/dev/null
# Alternativa:
sudo find / -user "$USER" -exec ls -ld {} + 2>/dev/null
```
- Explicación: `sudo` ejecuta como root; `-user "$USER"` busca por nombre o UID del usuario; `-ls` lista los metadatos completos tipo `ls -dils`. `2>/dev/null` redirige accesos denegados a sistemas virtuales como `/proc` o `/sys`.

#### 13) Como usuario “root”, mostrar las últimas 30 líneas de `/var/log/syslog`
```bash
sudo tail -n 30 /var/log/syslog
```
- Explicación: `tail -n 30` muestra las 30 líneas finales del fichero.

#### 14) En `/tmp`, crear una carpeta `AS` y tres subdirectorios llamados `docs`, `scripts` y `copias`. Comprobar la estructura creada utilizando un único comando
```bash
mkdir -p /tmp/AS/{docs,scripts,copias} && tree /tmp/AS
# Si no está instalado tree:
mkdir -p /tmp/AS/{docs,scripts,copias} && ls -lR /tmp/AS
```
- Explicación: La expansión de llaves en Bash `{docs,scripts,copias}` genera los tres directorios en una sola orden atómica. `&&` enlaza la comprobación en una única línea de comando.

#### 15) Buscar dentro del directorio `/etc` todos los ficheros cuyo nombre termine en `.conf` y guardar la lista completa en un fichero de texto
```bash
find /etc -type f -name "*.conf" 2>/dev/null > ficheros_conf.txt
```
- Verificación:
  ```bash
  head -n 10 ficheros_conf.txt
  wc -l ficheros_conf.txt
  ```

#### 16) Crear un fichero de texto con 20 líneas numeradas del 1 al 20. Mostrar únicamente las líneas 5 a 10 utilizando herramientas de filtrado de texto
- Creación:
  ```bash
  seq 1 20 > numeros.txt
  ```
- Filtrado (con `sed`):
  ```bash
  sed -n '5,10p' numeros.txt
  ```
- Alternativa con `head` y `tail`:
  ```bash
  head -n 10 numeros.txt | tail -n 6
  ```
- Alternativa con `awk`:
  ```bash
  awk 'NR>=5 && NR<=10' numeros.txt
  ```

#### 17) Crear mediante un comando un fichero llamado `usuarios.txt` que contenga únicamente los nombres de usuario definidos en el sistema. Verificar cuántas líneas contiene
```bash
cut -d: -f1 /etc/passwd > usuarios.txt && wc -l usuarios.txt
```
- Explicación: `cut -d: -f1` extrae el primer campo (delimitado por dos puntos), correspondiente al login name de cada cuenta. `wc -l` cuenta las líneas.

#### 18) Crear un usuario llamado `prueba_as` con directorio personal y shell `/bin/bash`. Comprobar que la cuenta se ha creado correctamente y que aparece en el fichero del sistema
```bash
sudo useradd -m -s /bin/bash prueba_as
```
- Comprobación:
  ```bash
  grep "^prueba_as:" /etc/passwd
  ls -ld /home/prueba_as
  ```
- Explicación: `-m` fuerza la creación de la carpeta de inicio (`/home/prueba_as`) y copia el esqueleto `/etc/skel`. `-s /bin/bash` asigna Bash como shell.

#### 19) Mostrar los cinco directorios que más espacio ocupan dentro del directorio `/var` y ordenarlos de mayor a menor tamaño
```bash
sudo du -d 1 -h /var 2>/dev/null | sort -hr | grep -v '^.*/var$' | head -n 5
# Alternativa puramente numérica:
sudo du -d 1 /var 2>/dev/null | sort -nr | grep -v '/var$' | head -n 5
```
- Explicación:
  - `du -d 1 -h /var`: mide el uso de disco con profundidad máxima 1 en formato legible (K, M, G).
  - `sort -hr`: ordena numéricamente en orden descendente teniendo en cuenta las unidades de sufijo (Human-readable).
  - `grep -v '^.*/var$'`: descarta el propio directorio `/var` (que es la suma de todos).
  - `head -n 5`: toma los 5 mayores.

#### 20) En el directorio `/home`, localizar los archivos que tengan permisos de escritura para "otros usuarios" (`other`). Guardar el resultado en un fichero
```bash
find /home -type f -perm -o=w 2>/dev/null > /tmp/otros_escritura.txt
# Notación octal equivalente:
find /home -type f -perm -002 2>/dev/null > /tmp/otros_escritura.txt
```
- Explicación: `-perm -o=w` comprueba que el bit de escritura para el colectivo "otros" esté activado (sin importar los permisos de usuario o grupo).

---

## 2. Shell Scripting

Todos los scripts han sido implementados y probados, y se encuentran disponibles de forma ejecutable en la carpeta `scripts_lab01/`.

### Ejercicio 1: `lsdirs.sh`
Muestra los directorios contenidos en el directorio actual.
- **Fichero:** `scripts_lab01/lsdirs.sh`
```bash
#!/bin/bash
# Muestra los directorios contenidos en el directorio actual

for item in */; do
    if [ -d "$item" ]; then
        echo "${item%/}"
    fi
done
```
- **Modo de ejecución:**
  ```bash
  ./lsdirs.sh
  ```

---

### Ejercicio 2: `see.sh`
Recibe un nombre de fichero/directorio como parámetro. Si es fichero muestra con `more`; si es directorio muestra con `ls`.
- **Fichero:** `scripts_lab01/see.sh`
```bash
#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Uso: $0 <nombre_fichero_o_directorio>"
    exit 1
fi

ruta="$1"

if [ -f "$ruta" ]; then
    more "$ruta"
elif [ -d "$ruta" ]; then
    ls "$ruta"
else
    echo "Error: '$ruta' no existe o no es un fichero regular ni un directorio."
    exit 2
fi
```
- **Modo de ejecución:**
  ```bash
  ./see.sh /etc/passwd
  ./see.sh /var
  ```

---

### Ejercicio 3: `longitud_palabra.sh`
Pide al usuario que teclee una palabra y escribe por pantalla el número de caracteres.
- **Fichero:** `scripts_lab01/longitud_palabra.sh`
```bash
#!/bin/bash
read -p "Introduce una palabra: " palabra
echo "La palabra '${palabra}' tiene ${#palabra} caracteres."
```
- **Modo de ejecución:**
  ```bash
  ./longitud_palabra.sh
  ```

---

### Ejercicio 4: `es_comando.sh`
Pide al usuario una palabra y comprueba si es un comando del sistema.
- **Fichero:** `scripts_lab01/es_comando.sh`
```bash
#!/bin/bash
read -p "Introduce una palabra: " palabra

if [ -z "$palabra" ]; then
    echo "No has introducido ninguna palabra."
    exit 1
fi

if command -v "$palabra" > /dev/null 2>&1; then
    tipo=$(type -t "$palabra")
    ubicacion=$(type -p "$palabra")
    echo "'$palabra' SÍ es un comando del sistema (tipo: $tipo, ruta: ${ubicacion:-integrado/alias})."
else
    echo "'$palabra' NO es un comando del sistema."
fi
```
- **Modo de ejecución:**
  ```bash
  ./es_comando.sh
  ```

---

### Ejercicio 5: `crear_cosas.sh`
Crea una carpeta `cosas` y 100 ficheros vacíos `fich<numero>.txt` (de 0 a 99).
- **Fichero:** `scripts_lab01/crear_cosas.sh`
```bash
#!/bin/bash
mkdir -p cosas

for i in $(seq 0 99); do
    touch "cosas/fich${i}.txt"
done

echo "Se han creado 100 ficheros en el directorio cosas/ (fich0.txt a fich99.txt)."
```
- **Modo de ejecución:**
  ```bash
  ./crear_cosas.sh
  ```

---

### Ejercicio 6: `llenar_cosas_man.sh`
Extiende el script anterior para que cada fichero contenga la N-ésima línea del manual de `ls`.
- **Fichero:** `scripts_lab01/llenar_cosas_man.sh`
```bash
#!/bin/bash
mkdir -p cosas

man_tmp=$(mktemp)
man ls | col -b > "$man_tmp"

for i in $(seq 0 99); do
    linea_num=$((i + 1))
    sed -n "${linea_num}p" "$man_tmp" > "cosas/fich${i}.txt"
done

rm -f "$man_tmp"
echo "Ficheros rellenados con las líneas del manual de ls en cosas/."
```
- **Modo de ejecución:**
  ```bash
  ./llenar_cosas_man.sh
  ```

---

### Ejercicio 7: `cambiar_extension.sh`
Modifica la extensión de todos los ficheros `.txt` de un directorio a `.t`.
- **Fichero:** `scripts_lab01/cambiar_extension.sh`
```bash
#!/bin/bash
directorio="${1:-.}"

if [ ! -d "$directorio" ]; then
    echo "Error: El directorio '$directorio' no existe."
    exit 1
fi

shopt -s nullglob
ficheros=("$directorio"/*.txt)

if [ ${#ficheros[@]} -eq 0 ]; then
    echo "No se encontraron ficheros .txt en '$directorio'."
    exit 0
fi

for f in "${ficheros[@]}"; do
    destino="${f%.txt}.t"
    mv "$f" "$destino"
done

echo "Se cambiaron ${#ficheros[@]} ficheros de extensión .txt a .t en '$directorio'."
```
- **Modo de ejecución:**
  ```bash
  ./cambiar_extension.sh cosas
  ```

---

### Ejercicio 8: `borra.sh`
Recibe un número indefinido de parámetros (de 0 a 9) y borra el fichero correspondiente a la suma de dichos parámetros.
- **Fichero:** `scripts_lab01/borra.sh`
```bash
#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Uso: $0 <num1> <num2> ... <numN>"
    echo "Ejemplo: $0 1 4 5 9  (borrará el fichero con sufijo 19)"
    exit 1
fi

suma=0
for arg in "$@"; do
    if ! [[ "$arg" =~ ^[0-9]+$ ]]; then
        echo "Error: El parámetro '$arg' no es un número válido."
        exit 2
    fi
    suma=$((suma + arg))
done

posibles=(
    "cosas/fich${suma}.txt"
    "cosas/fich${suma}.t"
    "fich${suma}.txt"
    "fich${suma}.t"
)

borrado=0
for f in "${posibles[@]}"; do
    if [ -f "$f" ]; then
        rm "$f"
        echo "Fichero '$f' borrado exitosamente (suma total = $suma)."
        borrado=1
        break
    fi
done

if [ $borrado -eq 0 ]; then
    echo "No se encontró ningún fichero correspondiente a la suma $suma (fich${suma}.txt o fich${suma}.t)."
fi
```
- **Modo de ejecución:**
  ```bash
  ./borra.sh 1 4 5 9
  ```

---

### Ejercicio 9: `orden.sh`
Muestra el contenido de `/etc/passwd` ordenado por nombre de usuario, UID o GID según el argumento recibido.
- **Fichero:** `scripts_lab01/orden.sh`
```bash
#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Uso: $0 {usuario|uid|gid}"
    exit 1
fi

case "$1" in
    usuario|user|-u)
        echo "=== Ordenado por NOMBRE DE USUARIO (campo 1 alfabético) ==="
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
```
- **Modo de ejecución:**
  ```bash
  ./orden.sh usuario
  ./orden.sh uid
  ./orden.sh gid
  ```

---

### Ejercicio 10: `personalizar_email.sh`
A partir de `cuerpo.txt` (con el texto y el marcador `NOMBRE`) y `nombres.txt` (con varios nombres), genera un fichero personalizado para cada destinatario.
- **Fichero:** `scripts_lab01/personalizar_email.sh`
```bash
#!/bin/bash
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
    nombre=$(echo "$linea" | tr -d '\r' | xargs)
    [ -z "$nombre" ] && continue

    fichero_salida="emails_generados/email_${nombre}.txt"
    sed "s/NOMBRE/${nombre}/g" "$fichero_cuerpo" > "$fichero_salida"
    echo "Generado email para '${nombre}' -> $fichero_salida"
    contador=$((contador + 1))
done < "$fichero_nombres"

echo "Proceso finalizado. Total emails generados: $contador en el directorio emails_generados/."
```
- **Ejemplo de prueba rápida:**
  ```bash
  cat << 'EOF' > cuerpo.txt
  Estimado/a NOMBRE,
  Le confirmamos que su solicitud para NOMBRE ha sido procesada con éxito.
  Atentamente,
  El Departamento de Sistemas.
  EOF

  cat << 'EOF' > nombres.txt
  Ane
  Mikel
  Jon
  EOF

  ./personalizar_email.sh
  ```
