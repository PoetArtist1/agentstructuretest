# 🛡️ AgentStructure

[![Node.js Version](https://img.shields.io/badge/Node.js-v18+-green?style=flat-for-the-badge&logo=node.js)](https://nodejs.org)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue?style=flat-for-the-badge&logo=docker)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-Academic-purple?style=flat-for-the-badge)](DOCUMENTACION_TESIS_AGENTSTRUCTURE.md)

**Soberanía de Datos, Conectividad Segura y Alto Rendimiento para Entornos On-Premise.**

**AgentStructure** es una arquitectura híbrida de **Agente-Servidor** con **túnel inverso por WebSockets** diseñada para resolver un problema crítico de integración: permitir que aplicaciones externas o en la nube consuman datos específicos de bases de datos locales (On-Premise) de forma segura, **sin abrir puertos entrantes en el firewall, sin exponer credenciales y manteniendo total control local sobre las sentencias SQL.**

Este proyecto ha sido desarrollado como propuesta de **Tesis de Grado** para la integración segura de datos corporativos en redes locales cerradas.

---

## 💡 El Problema y la Solución

### El Desafío Común
Las organizaciones suelen ser reticentes (y por normativa de ciberseguridad, no deben) exponer sus credenciales de base de datos o abrir puertos de entrada en sus firewalls (`3306`, `5432`, `1433`) para conectar aplicaciones externas.

### La Propuesta de AgentStructure
En lugar de que el servidor en la nube guarde las queries SQL y posea acceso directo a la base de datos:

1. **Las queries residen localmente en el Agente**, dentro de la red corporativa privada (`queries.json`).
2. El Servidor Central actúa como un **Broker Broker-Mediator transparente**: solo conoce **nombres de acciones** (por ejemplo: `get_clientes_paginados`) y sus parámetros.
3. El Agente inicia la conexión al Servidor mediante un túnel seguro bidireccional de salida (**WebSockets Outbound**), evitando abrir puertos de entrada.
4. Cuando el Servidor recibe una petición HTTP, retransmite la acción al Agente, quien resuelve la consulta localmente, valida tipos de datos, aplica el modo solo-lectura, audita el acceso y retorna únicamente los resultados sanitizados.

---

## 🎨 Diagramas del Sistema

### 1. Diagrama de Conexión y Arquitectura General
El siguiente diagrama detalla la topología de red, el perímetro de seguridad y el flujo bidireccional de peticiones desde la aplicación cliente hasta la base de datos local:

```mermaid
graph TD
    subgraph CloudZone ["Zona Nube / Public Internet"]
        App["Aplicación Cliente (Móvil, Web, Dashboard)"]
        
        subgraph CentralServer ["Servidor Central (API Gateway)"]
            ExpressREST["Express REST API (/query/:clienteId)"]
            APIAuth["Middleware Auth (Header X-Api-Key)"]
            CompressionGZIP["Compresión GZIP (HTTP REST)"]
            Singleflight["Patrón Singleflight (In-Flight JOIN)"]
            NodeCache["Caché en Memoria (maxKeys: 1000, Limite 1MB)"]
            WSServer["Servidor WebSocket (perMessageDeflate: true)"]
        end
    end

    subgraph PerimetralBoundary ["Perímetro de Seguridad (Firewall)"]
        OutboundTunnel["Túnel Inverso WebSocket Saliente (Puertos 80 / 443) - Cero Puertos Entrantes Abiertos"]
    end

    subgraph OnPremiseZone ["Zona On-Premise (Red Privada Corporativa)"]
        subgraph AgentClient ["Agente On-Premise (AgentStructure)"]
            WSClient["Cliente WebSocket (perMessageDeflate: true)"]
            AuthHandshake["Autenticación por Secret y Action Manifest"]
            QueryResolver["Resolvedor de Queries (queries.json Whitelist)"]
            TypeValidator["Validación de Tipos y Sanitización Anti-SQLi"]
            ReadOnlyCheck["Enforcement de Modo Solo-Lectura"]
            DBFactory["Factory Multi-Motor (connector.js)"]
            AuditLogger["Módulo de Auditoría (Log Diario)"]
        end
        
        subgraph LocalDatabase ["Base de Datos Local"]
            Engine["SQL Server / PostgreSQL / MySQL"]
        end
    end

    App -->|"1. HTTP POST /query/:clienteId"| ExpressREST
    ExpressREST --> APIAuth
    APIAuth --> CompressionGZIP
    CompressionGZIP --> Singleflight
    Singleflight --> NodeCache
    NodeCache -->|"Cache Hit: Responde al instante"| ExpressREST
    NodeCache -->|"Cache Miss"| WSServer
    
    WSClient -->|"0. Conexión WebSocket Saliente (Outbound)"| OutboundTunnel
    OutboundTunnel --> WSServer
    
    WSServer -->|"2. Transmite Acción y Parámetros (Sin SQL)"| WSClient
    WSClient --> AuthHandshake
    AuthHandshake --> QueryResolver
    QueryResolver --> TypeValidator
    TypeValidator --> ReadOnlyCheck
    ReadOnlyCheck --> DBFactory
    DBFactory -->|"3. Ejecuta Query SQL Parametrizada"| Engine
    Engine -->|"4. Retorna filas"| DBFactory
    DBFactory --> AuditLogger
    DBFactory -->|"5. Respuesta JSON"| WSClient
    WSClient -->|"6. Frame WebSocket Comprimido"| WSServer
    WSServer --> ExpressREST
    ExpressREST -->|"7. 200 OK (Respuesta GZIP)"| App
```

---

### 2. Diagrama de Casos de Uso
Especificación formal de los casos de uso y las interacciones entre los diferentes actores del sistema:

```mermaid
graph LR
    subgraph Actores ["Actores del Sistema"]
        AppActor["📱 Aplicación Cliente (App Móvil / Web / Third-Party)"]
        AdminActor["👨‍💻 Administrador de TI / Empresa"]
        AgentActor["🤖 Agente On-Premise (Servicio Autónomo)"]
        ServerActor["☁️ Servidor Central (Broker API Gateway)"]
    end

    subgraph CasosDeUso ["Casos de Uso del Sistema"]
        UC1["UC-01: Solicitar Consulta de Datos (POST /query/:clienteId)"]
        UC2["UC-02: Autenticar Petición HTTP mediante API Key"]
        UC3["UC-03: Establecer Túnel Inverso WebSocket Saliente"]
        UC4["UC-04: Registrar Action Manifest de Acciones Disponibles"]
        UC5["UC-05: Deduplicar Peticiones Concurrentes en Vuelo (Singleflight)"]
        UC6["UC-06: Servir / Guardar Respuestas en Caché (node-cache)"]
        UC7["UC-07: Validar Acción en Lista Blanca Local (queries.json)"]
        UC8["UC-08: Sanitizar y Validar Tipos de Parámetros (int, string, date)"]
        UC9["UC-09: Validar Restricción de Solo-Lectura (readOnly)"]
        UC10["UC-10: Ejecutar Consulta SQL Parametrizada en BD Local"]
        UC11["UC-11: Registrar Trazabilidad en Log de Auditoría Diario"]
        UC12["UC-12: Paginación de Grandes Volúmenes (@limit y @offset)"]
        UC13["UC-13: Configurar Lista Blanca de Consultas Locales"]
        UC14["UC-14: Monitorear Agentes Conectados (/agents, /status)"]
    end

    AppActor --> UC1
    UC1 --> UC2
    UC2 --> UC5
    UC5 --> UC6
    UC6 --> ServerActor

    AgentActor --> UC3
    UC3 --> UC4
    UC4 --> ServerActor

    ServerActor --> UC7
    UC7 --> UC8
    UC8 --> UC9
    UC9 --> UC12
    UC12 --> UC10
    UC10 --> UC11

    AdminActor --> UC13
    AdminActor --> UC14
    UC14 --> ServerActor
```

---

### 3. Diagrama Completo del Laboratorio de Simulación y Benchmarking
Arquitectura del laboratorio experimental en Docker (`simulation-lab`) y la suite automatizada de pruebas de carga con Apache JMeter:

```mermaid
graph TD
    subgraph HostSystem ["Host System (Equipo de Pruebas / Benchmark Runner)"]
        JMeter["Apache JMeter 5.5 (Inyector de Carga Concurrente)"]
        BenchmarkScripts["Scripts de Automatización (run_benchmarks.ps1 / run_benchmarks.sh)"]
        TestMatrix["Matriz de Ráfagas: 10, 50, 100, 1000 y 2000 Hilos Concurrentes"]
    end

    subgraph DockerLab ["Entorno de Simulación Docker (simulation-lab)"]
        subgraph CloudNet ["Red Virtual Cloud (cloud_net: 10.10.0.0/24)"]
            SimServer["Contenedor: sim-central-server (Puerto 3500)"]
            ServerGZIP["Compresión GZIP + perMessageDeflate"]
            ServerSingleflight["Mapeo Singleflight (Inflight Join)"]
            ServerCache["node-cache (TTL 60s, maxKeys 1000, Limite 1MB)"]
        end

        subgraph DualNetBridge ["Conexión de Túnel Inverso WebSocket Saliente"]
            SimAgent["Contenedor: sim-local-agent (gdata-tunnel-agent)"]
            AgentResolver["Resolvedor queries.pg.json (Paginación limit/offset)"]
            AgentAudit["Auditoría de Logs"]
        end

        subgraph OnPremiseNet ["Red Virtual On-Premise Aislada (on_premise_net: 192.168.100.0/24)"]
            SimDB[("Contenedor: sim-database (PostgreSQL 15 Alpine)")]
            DBData["Datos Sintéticos Masivos: 25,000 Clientes y 5,000 Productos (init.sql)"]
        end
    end

    subgraph MetricsOutput ["Resultados Empíricos y Reportes"]
        CSVResults["Archivos de Resultados CSV (resultados_100_hilos.csv)"]
        HTMLDashboard["Dashboard HTML de JMeter (Response Times Over Time)"]
        PerformanceData["Resultados: Latencia Promedio 2.48 ms | Mediana 2.0 ms | 0.00% Error Rate"]
    end

    BenchmarkScripts --> JMeter
    JMeter --> TestMatrix
    TestMatrix -->|"Peticiones HTTP REST Simultáneas (Puerto 3500)"| SimServer

    SimServer --> ServerGZIP
    ServerGZIP --> ServerSingleflight
    ServerSingleflight --> ServerCache
    
    SimAgent -->|"Conexión Outbound WS (cloud_net)"| SimServer
    SimServer -->|"Mensajes Query"| SimAgent
    
    SimAgent --> AgentResolver
    AgentResolver -->|"Consultas SQL por red aislada (on_premise_net)"| SimDB
    SimDB --- DBData
    SimDB -->|"Filas devueltas"| AgentResolver
    AgentResolver --> AgentAudit
    AgentResolver -->|"QueryResult Comprimido"| SimServer

    SimServer -->|"Respuesta HTTP 200 OK"| JMeter
    JMeter --> CSVResults
    CSVResults --> HTMLDashboard
    HTMLDashboard --> PerformanceData
```

---

## ✨ Características Destacadas

- 🔒 **Soberanía Absoluta del Dato:** Las sentencias SQL residen en el cliente/empresa. La lógica de base de datos nunca sale de la red local.
- 🔌 **Conexión Inversa (WebSockets):** El Agente se conecta al Servidor. Cero configuraciones de Firewall o NAT en la infraestructura corporativa.
- 🚀 **Patrón Singleflight (Anti Thundering Herd):** Deduplica peticiones concurrentes idénticas en vuelo para compartir una sola consulta activa, reduciendo la carga en la base de datos.
- 📦 **Compresión de Doble Capa:**
  - **GZIP (`compression`)** para respuestas HTTP REST (~70% reducción de tamaño).
  - **`perMessageDeflate`** para la compresión binaria nativa de tramas WebSocket.
- 📑 **Paginación Nativa Parametrizada (`get_clientes_paginados`):** Soporte de `@limit` y `@offset` como enteros para transferir volúmenes masivos de datos en lotes seguros.
- 🛡️ **Seguridad Multi-Nivel:**
  - **API Key** (`X-Api-Key`) para aplicaciones externas.
  - **Secretos criptográficos individuales** por cada Agente registrado en `agents.json`.
  - **Action Manifest:** El Agente registra sus acciones disponibles al conectarse para validación anticipada en el servidor.
  - **Modo Solo-Lectura (`readOnly`):** Bloqueo por contrato de sentencias `INSERT`, `UPDATE`, `DELETE`, `DROP`.
- 📊 **Auditoría e Historial:** Logs diarios persistentes en el agente local que detallan acción, parámetros, estado, tiempo de respuesta y filas devueltas.
- 🗄️ **Multi-Motor de Base de Datos:** Soporte nativo mediante patrón Factory (`connector.js`) para:
  - **PostgreSQL**
  - **MySQL / MariaDB**
  - **Microsoft SQL Server (MSSQL)**

---

## 📂 Estructura del Repositorio

- [`/agent`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/agent): Código fuente del Agente local, resolvedor de queries, auditoría y drivers.
- [`/server`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/server): Código del Servidor Central (API Gateway, WebSocket Hub, Singleflight, GZIP, Caché).
- [`/simulation-lab`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/simulation-lab): Entorno experimental en Docker, base de datos sintética (25k clientes), plan de pruebas Apache JMeter y scripts de benchmarking.
- [`/landing`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/landing): Landing page interactiva construida en **React 19 + Vite**.
- [`/windows-installer`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/windows-installer): Aplicación de escritorio en **Electron + WinSW** para instalar componentes como servicios de Windows.
- [`DOCUMENTACION_TESIS_AGENTSTRUCTURE.md`](file:///c:/Users/carlo/OneDrive/Escritorio/TRABAJO/agentstructuretest/DOCUMENTACION_TESIS_AGENTSTRUCTURE.md): Documento técnico completo y académico para la Tesis de Grado.

---

## 🛠️ Instalación y Configuración

### Paso 1: Clonar el Repositorio e Instalar Dependencias

```bash
git clone https://github.com/PoetArtist1/agentstructuretest.git
cd agentstructuretest
node install.js
```

El script interactivo `install.js` te guiará para configurar los componentes.

---

### Paso 2: Configuración del Servidor Central (Cloud)

#### 1. Archivo `server/.env`
```env
PORT=3500
API_KEY=mi-clave-de-api-super-segura
QUERY_TIMEOUT_MS=30000
CACHE_DEFAULT_TTL=60
```

#### 2. Archivo `server/agents.json`
```json
{
  "empresa_ejemplo": {
    "secret": "generar-un-secret-unico-aqui",
    "description": "Cliente principal - Base de Datos Local"
  }
}
```

---

### Paso 3: Configuración del Agente On-Premise

#### 1. Archivo `agent/config.json`
```json
{
  "serverUrl": "ws://localhost:3500/ws",
  "clienteId": "empresa_ejemplo",
  "secret": "generar-un-secret-unico-aqui",
  "readOnly": true,
  "reconnect": {
    "initialDelayMs": 1000,
    "maxDelayMs": 30000,
    "backoffMultiplier": 2
  },
  "dbEngine": "mssql",
  "db": {
    "server": "localhost",
    "port": 1433,
    "database": "MiBaseDeDatos",
    "user": "sa",
    "password": "MiPasswordSeguro123"
  }
}
```

#### 2. Archivo `agent/queries.json` (Lista Blanca)
```json
{
  "get_clientes_paginados": {
    "description": "Obtiene clientes paginados de forma segura",
    "sql": "SELECT Codigo as IDCliente, Descripcion as razon_social FROM Clientes ORDER BY Codigo OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY",
    "params": {
      "limit": { "type": "int", "required": true },
      "offset": { "type": "int", "required": true }
    }
  }
}
```

---

## 🧪 Pruebas de Rendimiento (Simulation Lab & Docker)

Para ejecutar las pruebas automatizadas de rendimiento y benchmarking con **Apache JMeter** y **Docker Compose**:

```powershell
# 1. Levantar la infraestructura de prueba en Docker
cd simulation-lab
docker compose up --build -d

# 2. Ejecutar la suite de benchmarking (10, 50, 100, 1000 y 2000 hilos)
cd jmeter
.\run_benchmarks.ps1
```

Los reportes HTML interactivos y archivos CSV se generarán automáticamente en `simulation-lab/resultados-benchmark/`.
