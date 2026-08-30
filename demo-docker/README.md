# 🎓 Demo de Tesis — AgentStructure en Vivo

Demo interactiva para la defensa de tesis donde el jurado puede consultar una base de datos real a través de AgentStructure desde sus teléfonos o laptops.

---

## 📋 Contenido de la Demo

La página web tiene **3 botones de consulta** que traen datos reales de una base de datos PostgreSQL a través del túnel inverso WebSocket:

| Botón | Datos | Registros |
|-------|-------|-----------|
| 👥 Clientes | Datos comerciales (razón social, RIF, crédito, contacto) | 3,000 |
| 📦 Productos | Catálogo de inventario (precios, marcas, IVA) | 2,000 |
| 👔 Trabajadores | Nómina de personal (cargo, departamento, salario) | 300 |

Además incluye:
- 🧹 **Botón Limpiar** para resetear toda la interfaz
- 📊 **Métricas en tiempo real** (latencia, filas, origen, estado del túnel)
- 📋 **Tabla paginada** (20 registros por página)
- 💻 **Terminales visuales** simulando los logs del servidor y del agente

---

## 🏗️ Arquitectura

### Escenario A: Producción (VPS + Vercel)

```
[Jurado: Teléfono/Laptop]
        │
        ▼ HTTPS
[Vercel: demo-frontend/]
        │
        ▼ POST /query/tesis_demo (X-Api-Key)
[VPS: Servidor Central] ◄──── WSS saliente ──── [Tu Laptop: Agente + DB]
    (docker-compose.vps.yml)                    (docker-compose.agent.yml)
```

### Escenario B: Fallback Local (Todo en tu Laptop)

```
[Jurado: Mismo WiFi] ──► http://TU_LAPTOP_IP:8080 ──► [Tu Laptop: Todo Docker]
                                                       (docker-compose.local.yml)
```

---

## 🚀 Guía de Despliegue

### Escenario A: Producción (VPS + Vercel)

#### Paso 1: Configurar URLs

1. Editar `agent-config/config.vps.json` — cambiar `TU_VPS_IP` por la IP real del VPS
2. Editar `../demo-frontend/app.js` — cambiar `TU_VPS_IP` en `API_CONFIG.vpsUrl`
3. Editar `../demo-frontend/vercel.json` — cambiar `TU_VPS_IP` en el rewrite

#### Paso 2: Desplegar Servidor Central en el VPS

```bash
# En el VPS (SSH)
cd agentstructuretest/demo-docker
docker compose -f docker-compose.vps.yml up -d --build
```

Verificar que esté corriendo:
```bash
curl http://localhost:3500/status
```

#### Paso 3: Levantar Agente + DB en tu Laptop

```bash
# En tu laptop
cd agentstructuretest/demo-docker
docker compose -f docker-compose.agent.yml up -d --build
```

Esperar ~15 segundos para que la DB se inicialice, luego verificar:
```bash
curl http://TU_VPS_IP:3500/agents
```

Deberías ver: `"agents": [{ "id": "tesis_demo", "actions": [...] }]`

#### Paso 4: Desplegar Frontend en Vercel

```bash
cd agentstructuretest/demo-frontend
npx -y vercel --prod
```

---

### Escenario B: Fallback Local (Plan B)

Si la red de la universidad falla, levanta todo en tu laptop:

```bash
cd agentstructuretest/demo-docker
docker compose -f docker-compose.local.yml up -d --build
```

Esperar ~15 segundos, luego verificar:
```bash
# Verificar que el agente se conectó
curl http://localhost:3500/agents

# Probar una consulta
curl -X POST http://localhost:3500/query/tesis_demo ^
  -H "Content-Type: application/json" ^
  -H "X-Api-Key: demo-api-key-tesis-2026" ^
  -d "{\"action\":\"get_trabajadores_demo\"}"
```

El jurado accede a: `http://TU_LAPTOP_IP:8080`

Para obtener la IP de tu laptop en la red WiFi:
```bash
ipconfig    # Windows — buscar "IPv4 Address" en el adaptador WiFi
```

---

## ✅ Checklist Pre-Defensa

- [ ] Docker Desktop instalado y funcionando en tu laptop
- [ ] VPS accesible por SSH (si usas Escenario A)
- [ ] `config.vps.json` tiene la IP correcta del VPS
- [ ] `app.js` tiene la URL correcta del VPS en `vpsUrl`
- [ ] `vercel.json` tiene la URL correcta del VPS en `destination`
- [ ] Levantar los contenedores Docker y esperar 15 segundos
- [ ] Verificar `/agents` muestra `tesis_demo` conectado
- [ ] Probar los 3 botones desde el teléfono
- [ ] Probar el botón Limpiar
- [ ] Tener docker-compose.local.yml listo como Plan B

---

## 🔑 Credenciales de la Demo

| Componente | Valor |
|------------|-------|
| **clienteId** | `tesis_demo` |
| **API Key** | `demo-api-key-tesis-2026` |
| **Agent Secret** | `demo-tesis-secret-2026` |
| **DB Name** | `tesis_demo_db` |
| **DB User** | `postgres` |
| **DB Password** | `demo-tesis-db-2026` |

---

## 📁 Estructura de Archivos

```
demo-docker/
├── docker-compose.vps.yml         # Solo Servidor Central (para VPS)
├── docker-compose.agent.yml       # Agente + DB (para laptop con VPS)
├── docker-compose.local.yml       # TODO local (Plan B)
├── db-init/
│   └── init_demo.sql              # 3000 clientes, 2000 productos, 300 trabajadores
├── agent-config/
│   ├── config.vps.json            # Agente → VPS
│   ├── config.local.json          # Agente → servidor local
│   └── queries.demo.json          # 3 queries de demo + empresa
├── server-config/
│   ├── agents.demo.json           # Registro del agente tesis_demo
│   └── env.demo                   # Variables de entorno del servidor
├── nginx/
│   ├── default.conf               # Configuración Nginx con proxy reverso
│   ├── Dockerfile                 # Para build independiente
│   └── Dockerfile.local           # Para docker-compose.local.yml
└── README.md                      # Este archivo
```
