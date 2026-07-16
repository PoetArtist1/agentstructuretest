# 🔬 Laboratorio de Simulación y Entorno de Pruebas de Tesis

Este directorio contiene la instrumentación técnica completa requerida para recrear el **Laboratorio de Simulación** planteado en tu tesis de grado para la arquitectura **AgentStructure**.

Aquí encontrarás las herramientas y configuraciones necesarias para desplegar la infraestructura aislada, realizar las pruebas de rendimiento (benchmarking) y auditar la seguridad perimetral del sistema.

---

## 📐 Diseño de la Arquitectura de Simulación

El laboratorio utiliza **Docker Networks** para simular de forma lógica el aislamiento físico que existiría en un despliegue real:

```mermaid
graph TD
    subgraph Red Cloud (Internet / 10.10.0.0/24)
        jmeter[Apache JMeter / Cliente Externo]
        server[sim-central-server / API Gateway]
    end

    subgraph Red On-Premise (LAN Corporativa / 192.168.100.0/24)
        db[sim-database / PostgreSQL de Prueba]
    end

    agent[sim-local-agent / Agente Local]

    %% Conexiones
    jmeter -- "POST /query (HTTP/443)" --> server
    agent -- "WS Outbound (Túnel WS)" --> server
    agent -- "SQL queries" --> db

    %% Redes
    server -.-> cloud_net[cloud_net]
    jmeter -.-> cloud_net
    agent -.-> cloud_net
    
    agent -.-> LAN[on_premise_net]
    db -.-> LAN

    style server fill:#f9f,stroke:#333,stroke-width:2px
    style agent fill:#bbf,stroke:#333,stroke-width:2px
    style db fill:#bfb,stroke:#333,stroke-width:2px
    style jmeter fill:#ffb,stroke:#333,stroke-width:2px
```

* **Red Cloud (`cloud_net`)**: Simula internet. En esta red se aloja el servidor central expuesto al host en el puerto `3500` (el puerto default simulado para las peticiones de JMeter).
* **Red On-Premise (`on_premise_net`)**: Simula la red privada corporativa. Aloja la base de datos de prueba (`sim-database`), la cual **no tiene acceso a internet** ni puertos expuestos al host.
* **Agente Puente (`sim-local-agent`)**: Es el único miembro de ambas redes. Inicia la conexión de manera *saliente (outbound)* hacia el Servidor Central por WebSockets y resuelve las queries consultando a la Base de Datos. El agente **no expone ningún puerto**.

---

## 📂 Estructura de Carpetas

* [`/db-init`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab/db-init): Contiene el script SQL [`init.sql`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab/db-init/init.sql) para crear las tablas y sembrar datos de prueba en la base de datos PostgreSQL.
* [`/agent-config`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab/agent-config): Contiene la configuración [`config.docker.json`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab/agent-config/config.docker.json) y el catálogo de consultas en dialecto PostgreSQL [`queries.pg.json`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab/agent-config/queries.pg.json).
* [`/server-config`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab/server-config): Contiene el archivo de credenciales de agentes [`agents.docker.json`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab/server-config/agents.docker.json) y el archivo de entorno del servidor central [`env.docker`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab/server-config/env.docker).
* [`/jmeter`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab/jmeter): Contiene el plan de pruebas parametrizado [`agentstructure_benchmark.jmx`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab/jmeter/agentstructure_benchmark.jmx) y los scripts de ejecución automática (`.ps1` para Windows y `.sh` para macOS/Linux).
* [`/wireshark`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab/wireshark): Contiene la lista de cotejo (checklist) y comandos detallados para documentar la auditoría perimetral.

---

## 🚀 Guía de Ejecución Paso a Paso

### 1. Levantar el Entorno de Simulación (Docker Compose)
Desde la terminal en este directorio (`simulation-lab`), ejecuta:
```bash
docker compose up --build -d
```
Esto construirá las imágenes del servidor central y del agente basándose en los Dockerfiles correspondientes de tu código, configurará la red aislada y sembrará la base de datos de prueba.

Verifica que los 3 contenedores estén corriendo:
```bash
docker compose ps
```

### 2. Ejecutar las Pruebas de Rendimiento (Benchmarking)
El plan de pruebas está diseñado para enviar ráfagas concurrentes de peticiones HTTP POST al Servidor Central. El Servidor delega estas peticiones al Agente Local, que a su vez consulta a la BD aislada y retorna los datos por el túnel WebSocket.

1. Asegúrate de tener **Apache JMeter** instalado y configurado en tu `PATH`.
2. En Windows (PowerShell), corre el script automatizado:
   ```powershell
   cd jmeter
   .\run_benchmarks.ps1
   ```
   *(O en Linux/macOS: `chmod +x run_benchmarks.sh && ./run_benchmarks.sh`)*

3. El script ejecutará automáticamente las 3 ráfagas solicitadas:
   - **Ráfaga 1**: 10 peticiones simultáneas.
   - **Ráfaga 2**: 50 peticiones simultáneas.
   - **Ráfaga 3**: 100 peticiones simultáneas.
4. Los resultados se guardarán en una nueva carpeta en la raíz del laboratorio llamada `/resultados-benchmark`. Contendrá:
   - Archivos `.csv` con la latencia individual de cada petición.
   - Carpetas de reportes HTML interactivos con gráficos de latencia, rendimiento, y tasa de éxito/error.

### 3. Realizar la Auditoría de Seguridad Perimetral
Sigue los pasos documentados en la **[Guía de Auditoría y Lista de Cotejo](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab/wireshark/checklist.md)**.
Allí aprenderás cómo:
1. Comprobar que no hay redirecciones de puertos entrantes al Agente.
2. Capturar y exportar las trazas `.pcap` en Wireshark / tcpdump para verificar que la conexión WebSocket es de tipo inversa (outbound).
3. Simular un escaneo de puertos con `nmap` para certificar la inaccesibilidad perimetral del agente local.

---

## 📊 Formato de Datos para Entregables de la Tesis

### A. Estructura de la Matriz de Registro de Pruebas (JMeter CSV)
Los archivos CSV generados por JMeter tendrán las siguientes columnas críticas que debes reportar:
- `timeStamp`: Marca de tiempo de la petición.
- `elapsed`: Latencia de extremo a extremo en milisegundos (ms).
- `label`: El endpoint consultado (ej: `POST get_clientes` o `POST get_cuentas_cobrar`).
- `responseCode`: Código HTTP devuelto (`200` para éxito, `500`/`504` para error).
- `success`: Indica si la petición fue exitosa (`true`/`false`).
- `Latency`: Latencia de red.

### B. Análisis del Aislamiento Perimetral (.pcap)
En tu reporte escrito de tesis, puedes incluir capturas de pantalla de Wireshark que demuestren que:
- El primer paquete transmitido entre el host del Agente Local y el Servidor tiene la bandera `SYN` activa y es enviado **por el Agente**.
- Los puertos del Agente permanecen en estado `CLOSED` o `FILTERED` ante escaneos, mostrando la efectividad del aislamiento de redes Docker.
