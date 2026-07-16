# 🛠️ Guía de Instalación de Requisitos en Windows (Java, JMeter y Wireshark)

Para poder ejecutar el laboratorio de simulación en tu equipo, necesitas instalar y configurar las siguientes herramientas en tu sistema operativo Windows.

---

## 1. Instalar Java (Requisito indispensable para JMeter)
Apache JMeter está construido sobre Java, por lo que requiere el **Java Development Kit (JDK)** o el **Java Runtime Environment (JRE)** versión 8 o superior instalado.

### Paso a paso:
1. **Descargar OpenJDK:**
   - Ve a la página de descargas de [Adoptium (Eclipse Temurin)](https://adoptium.net/es/).
   - Descarga el instalador `.msi` recomendado para Windows (por ejemplo, **Temurin LTS de Java 17 o 21**).
2. **Ejecutar el Instalador:**
   - Abre el archivo `.msi` descargado.
   - **IMPORTANTE:** Durante la instalación, asegúrate de activar las opciones:
     - **Add to PATH** (Agregar al PATH).
     - **Set JAVA_HOME runtime image** (Establecer variable de entorno JAVA_HOME).
3. **Verificar la instalación:**
   - Abre una consola de PowerShell o CMD y escribe:
     ```powershell
     java -version
     ```
   - Si se muestra la versión de Java, está instalado correctamente.

---

## 2. Instalar Apache JMeter
JMeter no tiene un instalador tradicional (`.exe` o `.msi`). Se descarga como un archivo comprimido que debes descomprimir.

### Paso a paso:
1. **Descargar JMeter:**
   - Ve a la página oficial de descargas de [Apache JMeter](https://jmeter.apache.org/download_jmeter.cgi).
   - En la sección **Binaries**, descarga el archivo comprimido `.zip` (ej. `apache-jmeter-X.Y.zip`).
2. **Descomprimir:**
   - Extrae el archivo `.zip` en una ruta permanente y limpia (ej. `C:\apache-jmeter` o en tu carpeta de usuario).
3. **Agregar JMeter al PATH del sistema (Para que el script de PowerShell funcione automáticamente):**
   - Presiona la tecla `Windows` y busca **"Editar las variables de entorno del sistema"**.
   - Haz clic en el botón **"Variables de entorno..."**.
   - En **"Variables del sistema"** (la sección inferior), busca la variable llamada `Path` y haz clic en **"Editar..."**.
   - Haz clic en **"Nuevo"** y escribe la ruta absoluta hacia la carpeta `bin` de tu instalación de JMeter.
     - *Ejemplo:* `C:\apache-jmeter\bin`
   - Haz clic en **Aceptar** en todas las ventanas para guardar los cambios.
4. **Verificar la instalación:**
   - Cierra tu consola de PowerShell actual y abre una **nueva** terminal.
   - Ejecuta:
     ```powershell
     jmeter -v
     ```
   - Debe aparecer el banner de Apache JMeter confirmando que el comando está disponible.

---

## 3. Instalar Wireshark
Wireshark es un analizador de protocolos de red gráfico. Requiere instalar el analizador y un driver de captura de paquetes para Windows (`Npcap`).

### Paso a paso:
1. **Descargar Wireshark:**
   - Ve a la página oficial de [Wireshark Downloads](https://www.wireshark.org/download.html).
   - Descarga el instalador de Windows (ej. `Wireshark Windows Installer 64-bit`).
2. **Ejecutar el Instalador:**
   - Sigue los pasos del asistente de instalación.
   - **IMPORTANTE:** Durante el proceso, el asistente te preguntará si deseas instalar **Npcap** (el driver de red). **Selecciona que sí** e instálalo (es el componente que le permite a Wireshark escuchar las interfaces de red de Windows y de Docker).
3. **Reiniciar el sistema (Opcional pero Recomendado):**
   - Al finalizar las instalaciones, es sumamente recomendable reiniciar el equipo para asegurar que los drivers de red de `Npcap` y el `PATH` de sistema se carguen correctamente.

---

## 🚀 4. Probar y Ejecutar el Laboratorio

Una vez que tengas todo instalado y configurado en el `PATH`:

1. **Levanta Docker:**
   - Abre una terminal en tu carpeta `simulation-lab` y ejecuta:
     ```powershell
     docker compose up --build -d
     ```
2. **Ejecuta las pruebas de carga:**
   - En una terminal de PowerShell dentro de `simulation-lab/jmeter/`, corre:
     ```powershell
     .\run_benchmarks.ps1
     ```
   - El script detectará automáticamente el comando `jmeter` y guardará los reportes en la carpeta `resultados-benchmark` en la raíz del laboratorio.
