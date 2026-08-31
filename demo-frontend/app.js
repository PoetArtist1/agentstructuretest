/**
 * AgentStructure — Demo Tesis | Lógica del Frontend
 * ==================================================
 * Controla las peticiones al servidor central, la paginación,
 * las métricas en tiempo real y los logs de terminal visual.
 */

// ─── Configuración ───────────────────────────────────────────────────
// Detección automática del entorno:
// - En Vercel o producción -> usa el proxy relativo '/api' (configurado con $VPS_URL en Vercel)
// - En Docker local -> usa '/api'
// - En localhost directo -> usa 'http://localhost:3500'
const API_CONFIG = {
  localUrl: 'http://localhost:3505',
  proxyUrl: '/api',
  clienteId: 'tesis_demo',
  apiKey: 'demo-api-key-tesis-2026',
};

function getBaseUrl() {
  const host = window.location.hostname;
  const port = window.location.port;

  // Desarrollo local directo sin proxy (ej. node server/index.js)
  if ((host === 'localhost' || host === '127.0.0.1') && port === '3000') {
    return API_CONFIG.localUrl;
  }
  // Para Vercel y Docker Nginx local, usa la ruta relativa '/api'
  return API_CONFIG.proxyUrl;
}

const BASE_URL = getBaseUrl();
const ITEMS_PER_PAGE = 20;

// ─── Estado Global ───────────────────────────────────────────────────
let currentData = [];         // Datos completos de la última consulta
let currentPage = 1;          // Página actual
let totalPages = 0;           // Total de páginas
let currentAction = '';       // Acción activa ('get_clientes_demo', etc.)
let isLoading = false;        // Flag para evitar doble-click

// ─── Mapeo de columnas por acción ────────────────────────────────────
const COLUMN_MAPS = {
  get_clientes_demo: {
    label: 'Clientes',
    columns: [
      { key: 'idcliente', label: 'ID' },
      { key: 'razon_social', label: 'Razón Social' },
      { key: 'rif', label: 'RIF' },
      { key: 'telefono', label: 'Teléfono' },
      { key: 'contacto', label: 'Contacto' },
      { key: 'email', label: 'Email' },
      { key: 'direccion', label: 'Dirección' },
      { key: 'tiene_credito', label: 'Crédito' },
      { key: 'limite_credito', label: 'Límite' },
    ],
  },
  get_productos_demo: {
    label: 'Productos',
    columns: [
      { key: 'idproducto', label: 'ID' },
      { key: 'descripcion', label: 'Descripción' },
      { key: 'departamento', label: 'Depto' },
      { key: 'marca', label: 'Marca' },
      { key: 'modelo', label: 'Modelo' },
      { key: 'precio_maximo', label: 'P. Máximo' },
      { key: 'precio_detal', label: 'P. Detal' },
      { key: 'tasa_iva', label: 'IVA %' },
      { key: 'moneda', label: 'Moneda' },
    ],
  },
  get_trabajadores_demo: {
    label: 'Trabajadores',
    columns: [
      { key: 'idtrabajador', label: 'ID' },
      { key: 'nombre', label: 'Nombre' },
      { key: 'apellido', label: 'Apellido' },
      { key: 'cedula', label: 'Cédula' },
      { key: 'cargo', label: 'Cargo' },
      { key: 'departamento', label: 'Departamento' },
      { key: 'salario', label: 'Salario' },
      { key: 'estatus', label: 'Estatus' },
      { key: 'fecha_ingreso', label: 'Ingreso' },
    ],
  },
};

// ─── Inicialización ──────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  checkAgentStatus();
  // Verificar estado cada 15 segundos
  setInterval(checkAgentStatus, 15000);
});

// ─── Verificar Estado del Agente ─────────────────────────────────────
async function checkAgentStatus() {
  const badge = document.getElementById('statusBadge');
  const text = document.getElementById('statusText');
  const metricTunnel = document.getElementById('metricTunnel');

  try {
    const res = await fetch(`${BASE_URL}/agents`, {
      headers: { 'X-Api-Key': API_CONFIG.apiKey },
    });
    const data = await res.json();

    if (data.ok && data.agents && data.agents.length > 0) {
      const agent = data.agents.find(a => a.id === API_CONFIG.clienteId);
      if (agent) {
        badge.className = 'status-badge';
        text.textContent = `${agent.id} conectado`;
        metricTunnel.textContent = '🟢 Conectado';
        metricTunnel.style.color = 'var(--accent-green)';
        addTerminalLog('server', 'ws', `Agente "${agent.id}" conectado | Acciones: ${agent.actions.join(', ')}`);
        return;
      }
    }

    badge.className = 'status-badge disconnected';
    text.textContent = 'Sin agente';
    metricTunnel.textContent = '🔴 Sin agente';
    metricTunnel.style.color = 'var(--accent-red)';
  } catch {
    badge.className = 'status-badge disconnected';
    text.textContent = 'Sin conexión';
    metricTunnel.textContent = '🔴 Sin servidor';
    metricTunnel.style.color = 'var(--accent-red)';
  }
}

// ─── Petición de Datos ───────────────────────────────────────────────
async function fetchData(action) {
  if (isLoading) return;
  isLoading = true;

  const btnMap = {
    get_clientes_demo: 'btnClientes',
    get_productos_demo: 'btnProductos',
    get_trabajadores_demo: 'btnTrabajadores',
  };

  // Desactivar botones y mostrar spinner
  const activeBtn = document.getElementById(btnMap[action]);
  Object.values(btnMap).forEach(id => {
    document.getElementById(id).disabled = true;
  });
  document.getElementById('btnClear').disabled = true;

  const originalHTML = activeBtn.innerHTML;
  activeBtn.innerHTML += '<span class="spinner"></span>';

  // Log en terminal del servidor
  const actionLabel = COLUMN_MAPS[action]?.label || action;
  addTerminalLog('server', 'http', `POST /query/${API_CONFIG.clienteId} → action: "${action}"`);

  const startTime = performance.now();

  try {
    const res = await fetch(`${BASE_URL}/query/${API_CONFIG.clienteId}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Api-Key': API_CONFIG.apiKey,
      },
      body: JSON.stringify({ action }),
    });

    const endTime = performance.now();
    const latency = Math.round(endTime - startTime);
    const result = await res.json();

    if (!result.ok) {
      throw new Error(result.error || 'Error desconocido');
    }

    // Extraer datos (el servidor devuelve data.recordset o data directamente)
    const rows = result.data?.recordset || result.data || [];
    currentData = rows;
    currentAction = action;
    currentPage = 1;
    totalPages = Math.ceil(rows.length / ITEMS_PER_PAGE);

    // Actualizar métricas
    updateMetric('metricLatency', `${latency} ms`);
    updateMetric('metricRows', rows.length.toLocaleString('es'));
    updateMetric('metricSource', result.fromCache ? '💾 Caché' : '🗄️ Base de Datos');

    if (result.fromCache) {
      document.getElementById('metricSource').style.color = 'var(--accent-amber)';
    } else {
      document.getElementById('metricSource').style.color = 'var(--accent-purple)';
    }

    // Logs de terminal
    if (result.fromCache) {
      addTerminalLog('server', 'cache', `Cache HIT → ${API_CONFIG.clienteId}::${action} (${latency}ms)`);
    } else {
      addTerminalLog('server', 'ok', `Respuesta del agente → ${rows.length} filas (${latency}ms)`);
      addTerminalLog('server', 'cache', `Cache SET → ${API_CONFIG.clienteId}::${action} (TTL: 60s)`);
    }

    addTerminalLog('agent', 'agent', `Query recibida → acción: "${action}"`);
    addTerminalLog('agent', 'db', `Ejecutando SQL contra PostgreSQL...`);
    addTerminalLog('agent', 'ok', `Query OK → ${rows.length} filas (${Math.max(1, latency - 15)}ms)`);

    // Renderizar tabla
    renderTable();

  } catch (err) {
    addTerminalLog('server', 'error', `Error: ${err.message}`);
    updateMetric('metricLatency', 'Error');
    document.getElementById('metricLatency').style.color = 'var(--accent-red)';
    updateMetric('metricRows', '0');
    updateMetric('metricSource', '❌ Error');
  } finally {
    // Restaurar botones
    activeBtn.innerHTML = originalHTML;
    Object.values(btnMap).forEach(id => {
      document.getElementById(id).disabled = false;
    });
    document.getElementById('btnClear').disabled = false;
    isLoading = false;
  }
}

// ─── Limpiar Todo ────────────────────────────────────────────────────
function clearAll() {
  currentData = [];
  currentAction = '';
  currentPage = 1;
  totalPages = 0;

  // Resetear métricas
  updateMetric('metricLatency', '— ms');
  document.getElementById('metricLatency').style.color = 'var(--accent-green)';
  updateMetric('metricRows', '—');
  updateMetric('metricSource', '—');
  document.getElementById('metricSource').style.color = 'var(--accent-purple)';

  // Resetear tabla
  document.getElementById('tableHead').innerHTML = '';
  document.getElementById('tableBody').innerHTML = `
    <tr>
      <td colspan="100">
        <div class="table-empty">
          <div class="table-empty-icon">📋</div>
          <div class="table-empty-text">Sin datos cargados</div>
          <div class="table-empty-sub">Presiona un botón de consulta para comenzar</div>
        </div>
      </td>
    </tr>
  `;
  document.getElementById('pagination').style.display = 'none';
  document.getElementById('tableInfo').textContent = '';

  // Log
  addTerminalLog('server', 'http', 'Datos limpiados por el usuario');

  // Limpiar terminales
  document.getElementById('termServer').innerHTML = '<div class="terminal-line"><span class="timestamp">[' + getTimestamp() + ']</span> Datos limpiados. Esperando nueva consulta...</div>';
  document.getElementById('termAgent').innerHTML = '<div class="terminal-line"><span class="timestamp">[' + getTimestamp() + ']</span> Esperando actividad...</div>';
}

// ─── Renderizar Tabla ────────────────────────────────────────────────
function renderTable() {
  if (!currentData.length || !currentAction) return;

  const config = COLUMN_MAPS[currentAction];
  if (!config) return;

  // Header
  const thead = document.getElementById('tableHead');
  thead.innerHTML = '<tr>' + config.columns.map(col =>
    `<th>${col.label}</th>`
  ).join('') + '</tr>';

  // Body (paginado)
  const start = (currentPage - 1) * ITEMS_PER_PAGE;
  const end = start + ITEMS_PER_PAGE;
  const pageData = currentData.slice(start, end);

  const tbody = document.getElementById('tableBody');
  tbody.innerHTML = pageData.map((row, idx) => {
    const cells = config.columns.map(col => {
      let val = row[col.key];
      // Formatear valores especiales
      if (val === true) val = '✅ Sí';
      else if (val === false) val = '❌ No';
      else if (val === null || val === undefined) val = '—';
      else if (typeof val === 'number' && col.key.includes('precio') || col.key === 'limite_credito' || col.key === 'salario') {
        val = '$' + parseFloat(val).toLocaleString('es', { minimumFractionDigits: 2 });
      }
      return `<td>${val}</td>`;
    }).join('');
    return `<tr style="animation-delay: ${idx * 20}ms">${cells}</tr>`;
  }).join('');

  // Table info
  const totalRows = currentData.length;
  document.getElementById('tableInfo').innerHTML =
    `Mostrando <strong>${start + 1}-${Math.min(end, totalRows)}</strong> de <strong>${totalRows.toLocaleString('es')}</strong> ${config.label.toLowerCase()}`;

  // Pagination
  renderPagination();
}

// ─── Renderizar Paginación ───────────────────────────────────────────
function renderPagination() {
  const container = document.getElementById('pagination');

  if (totalPages <= 1) {
    container.style.display = 'none';
    return;
  }

  container.style.display = 'flex';
  let html = '';

  // Botón Anterior
  html += `<button class="page-btn" onclick="goToPage(${currentPage - 1})" ${currentPage === 1 ? 'disabled' : ''}>◀</button>`;

  // Generar números de página con elipsis
  const pages = generatePageNumbers(currentPage, totalPages);
  pages.forEach(p => {
    if (p === '...') {
      html += '<span class="page-ellipsis">…</span>';
    } else {
      html += `<button class="page-btn ${p === currentPage ? 'active' : ''}" onclick="goToPage(${p})">${p}</button>`;
    }
  });

  // Botón Siguiente
  html += `<button class="page-btn" onclick="goToPage(${currentPage + 1})" ${currentPage === totalPages ? 'disabled' : ''}>▶</button>`;

  container.innerHTML = html;
}

function generatePageNumbers(current, total) {
  if (total <= 7) {
    return Array.from({ length: total }, (_, i) => i + 1);
  }

  const pages = [];
  pages.push(1);

  if (current > 3) pages.push('...');

  const start = Math.max(2, current - 1);
  const end = Math.min(total - 1, current + 1);

  for (let i = start; i <= end; i++) {
    pages.push(i);
  }

  if (current < total - 2) pages.push('...');

  pages.push(total);
  return pages;
}

function goToPage(page) {
  if (page < 1 || page > totalPages) return;
  currentPage = page;
  renderTable();
  // Scroll suave al inicio de la tabla
  document.querySelector('.table-panel').scrollIntoView({ behavior: 'smooth', block: 'start' });
}

// ─── Actualizar Métricas con Animación ───────────────────────────────
function updateMetric(id, value) {
  const el = document.getElementById(id);
  el.textContent = value;
  el.classList.remove('updated');
  // Force reflow
  void el.offsetWidth;
  el.classList.add('updated');
}

// ─── Terminal Logs ───────────────────────────────────────────────────
function addTerminalLog(terminal, type, message) {
  const container = document.getElementById(terminal === 'server' ? 'termServer' : 'termAgent');
  const timestamp = getTimestamp();

  const labelClass = {
    http: 'label-http',
    ws: 'label-ws',
    cache: 'label-cache',
    agent: 'label-agent',
    db: 'label-db',
    error: 'label-error',
    ok: 'label-ok',
  }[type] || '';

  const labelText = {
    http: '[HTTP]',
    ws: '[WS]',
    cache: '[CACHE]',
    agent: '[AGENT]',
    db: '[DB]',
    error: '[ERROR]',
    ok: '[OK]',
  }[type] || `[${type.toUpperCase()}]`;

  const line = document.createElement('div');
  line.className = 'terminal-line';
  line.innerHTML = `<span class="timestamp">[${timestamp}]</span> <span class="${labelClass}">${labelText}</span> ${escapeHtml(message)}`;
  container.appendChild(line);

  // Auto-scroll al fondo
  container.scrollTop = container.scrollHeight;

  // Limitar a 50 líneas
  while (container.children.length > 50) {
    container.removeChild(container.firstChild);
  }
}

// ─── Utilidades ──────────────────────────────────────────────────────
function getTimestamp() {
  const now = new Date();
  return now.toLocaleTimeString('es', { hour12: false });
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}
