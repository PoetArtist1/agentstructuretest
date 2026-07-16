# 🛡️ Guía de Auditoría de Seguridad Perimetral y Lista de Cotejo

Esta guía contiene los procedimientos técnicos y comandos necesarios para validar y certificar cualitativamente que el **Agente Local** opera bajo una arquitectura de **túnel inverso de puertos cerrados (zero inbound ports)**, garantizando que el contenedor del agente no reciba conexiones entrantes desde el exterior.

---

## 📋 Lista de Cotejo (Checklist) de Auditoría

| Ítem | Criterio de Aceptación | Método de Verificación | Estado (Cumple / No) | Observaciones |
| :--- | :--- | :--- | :---: | :--- |
| **1** | **Aislamiento de Redes Virtuales** | El Servidor Central y la Base de Datos están en redes distintas y no se comunican directamente. | | `sim-central-server` en `cloud_net`<br>`sim-database` en `on_premise_net` |
| **2** | **Cero Puertos Entrantes en el Agente** | El contenedor `sim-local-agent` no expone ningún puerto mapeado hacia el exterior. | | Inspección con `docker ps` y `docker inspect`. |
| **3** | **Conexión Saliente Exclusiva (Outbound)** | La conexión WebSocket es iniciada por el Agente (`SYN` saliente) hacia el Servidor Central. | | Captura de paquetes `.pcap` con `tcpdump`/Wireshark. |
| **4** | **Bloqueo de Tránsito Directo** | Intentos de escaneo de puertos (ej. `nmap`) desde el Servidor Central hacia el Agente son bloqueados o fallan. | | Ejecución de `nmap` o `nc` desde el contenedor del Servidor. |
| **5** | **Ausencia de Exposición de la Base de Datos** | La Base de Datos no tiene puertos expuestos al host ni a la red Cloud. | | Comprobación de puertos de `sim-database`. |

---

## 🛠️ Procedimientos Técnicos y Comandos CLI

Siga estos pasos en el equipo de laboratorio para recolectar la evidencia empírica (incluyendo los archivos `.pcap` de captura de red) solicitada por su tesis.

### Paso 1: Verificar el Aislamiento de Puertos (Docker CLI)

1. **Listar contenedores activos y puertos expuestos:**
   ```bash
   docker ps --filter "name=sim-"
   ```
   * **Resultado esperado:**
     - El contenedor `sim-central-server` debe mostrar `"0.0.0.0:3500->3500/tcp"`.
     - El contenedor `sim-local-agent` **no debe tener ningún mapeo de puertos** en la columna `PORTS` (debe estar vacía).
     - El contenedor `sim-database` **no debe tener mapeo de puertos** (solo listará `5432/tcp` internamente, sin mapeo al host).

2. **Inspeccionar la configuración de red y puertos del Agente:**
   ```bash
   docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}} {{$p}} -> {{$conf}} {{end}}' sim-local-agent
   ```
   * **Resultado esperado:** La salida debe ser completamente vacía (no hay redirección de puertos `HostPort` configurada).

---

### Paso 2: Captura de Tráfico de Red (.pcap) con Wireshark o tcpdump

Para certificar que la conexión WebSocket es de tipo inversa (saliente), se captura la secuencia de inicialización del sistema.

#### Opción A: Capturar desde el Host usando Wireshark (Gráfico)
1. Ejecute en su consola del host para conocer el ID del bridge de red correspondiente a `cloud_net`:
   ```bash
   docker network inspect simulation-lab_cloud_net --format='{{.Id}}'
   ```
2. La interfaz de red virtual en su sistema operativo host se llamará algo similar a `br-<ID_red>` (en Linux) o `vEthernet` (en Windows con WSL2/Hyper-V).
3. Abra **Wireshark** con privilegios de administrador.
4. Seleccione e inicie la captura en la interfaz virtual correspondiente a `cloud_net`.
5. Filtre el tráfico aplicando el filtro: `tcp.port == 3500` (o el puerto del WebSocket).
6. Reinicie el contenedor del agente para forzar la reconexión:
   ```bash
   docker restart sim-local-agent
   ```
7. En Wireshark, detenga la captura y observe el handshake de TCP:
   - Verifique que el primer paquete `SYN` se origina en la IP del Agente (`10.10.0.X`) y tiene como destino la IP del Servidor Central (`10.10.0.Y`).
   - Guarde el archivo de captura como `captura_aislamiento_perimetral.pcap` para sus entregables.

#### Opción B: Capturar usando tcpdump en un contenedor temporal (CLI)
Si prefiere automatizar la captura directo en el entorno Docker sin instalar herramientas en el host:
1. Inicie un contenedor con privilegios de red sobre la red `cloud_net`:
   ```bash
   docker run --rm --net=container:sim-local-agent nicolaka/netshoot tcpdump -i any -w /tmp/capture.pcap tcp port 3500
   ```
   *(Nota: `nicolaka/netshoot` es una navaja suiza de redes que se asocia a la pila de red del agente).*
2. En otra terminal, reinicie el agente para capturar el tráfico:
   ```bash
   docker restart sim-local-agent
   ```
3. Detenga el comando `tcpdump` (Ctrl+C). El archivo `.pcap` se guardará. Puede copiarlo a su host con:
   ```bash
   docker cp sim-local-agent:/tmp/capture.pcap ./captura_aislamiento_perimetral.pcap
   ```

---

### Paso 3: Prueba de Penetración de Puertos Entrantes (Escaneo)

Demuestre empíricamente que el Agente es invisible a escaneos desde la red `cloud_net` (simulando internet).

1. Obtenga la IP interna del Agente en la red `cloud_net`:
   ```bash
   docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' sim-local-agent
   ```
2. Ejecute un escaneo de puertos (nmap) desde el contenedor del Servidor Central (que está en la misma red `cloud_net`) hacia la IP del Agente:
   ```bash
   docker exec -it sim-central-server sh -c "apk add --no-cache nmap && nmap -sS -p- <IP_DEL_AGENTE>"
   ```
   * **Resultado esperado:**
     - `nmap` reportará que todos los puertos están cerrados o filtrados (no hay ningún puerto escuchando en el agente).
     - Esto certifica la ausencia de conexiones entrantes hacia el contenedor del Agente Local.
