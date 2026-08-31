/**
 * Vercel Serverless Proxy — Catch-All Route
 * ======================================================================
 * Archivo: api/[...path].js
 *
 * Captura TODAS las peticiones a /api/* y las reenvía al Servidor Central
 * (VPS) usando la variable de entorno privada VPS_URL de Vercel.
 *
 * Ejemplos de ruteo:
 *   GET  /api/agents             → GET  http://VPS:3505/agents
 *   POST /api/query/tesis_demo   → POST http://VPS:3505/query/tesis_demo
 *   GET  /api/status             → GET  http://VPS:3505/status
 *
 * Cero IPs expuestas en GitHub — 100% Privado y Seguro.
 * ======================================================================
 */

const http = require('http');
const https = require('https');

module.exports = async (req, res) => {
  // ─── CORS ───
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,POST,PUT,DELETE');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Api-Key');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // ─── Construir URL destino ───
  const vpsUrl = (process.env.VPS_URL || 'http://localhost:3505').replace(/\/$/, '');

  // req.query.path es un array con los segmentos de ruta después de /api/
  // Ej: /api/query/tesis_demo → req.query.path = ["query", "tesis_demo"]
  // Ej: /api/agents           → req.query.path = ["agents"]
  const pathParts = req.query && req.query.path
    ? (Array.isArray(req.query.path) ? req.query.path : [req.query.path])
    : [];
  const targetPath = '/' + pathParts.join('/');
  const targetUrl = `${vpsUrl}${targetPath}`;

  // ─── Preparar body para POST ───
  let bodyStr = '';
  if (req.method !== 'GET' && req.method !== 'HEAD' && req.body) {
    bodyStr = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
  }

  // ─── Hacer la petición al VPS usando http/https nativo ───
  return new Promise((resolve) => {
    const parsedUrl = new URL(targetUrl);
    const transport = parsedUrl.protocol === 'https:' ? https : http;

    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port,
      path: parsedUrl.pathname + parsedUrl.search,
      method: req.method,
      headers: {
        'Content-Type': 'application/json',
        'X-Api-Key': req.headers['x-api-key'] || 'demo-api-key-tesis-2026',
      },
      timeout: 30000,
    };

    if (bodyStr) {
      options.headers['Content-Length'] = Buffer.byteLength(bodyStr);
    }

    const proxyReq = transport.request(options, (proxyRes) => {
      let data = '';
      proxyRes.on('data', (chunk) => { data += chunk; });
      proxyRes.on('end', () => {
        try {
          const json = JSON.parse(data);
          res.status(proxyRes.statusCode).json(json);
        } catch {
          res.status(proxyRes.statusCode).send(data);
        }
        resolve();
      });
    });

    proxyReq.on('error', (err) => {
      res.status(502).json({
        ok: false,
        error: `Proxy error: ${err.message}`,
        target: targetUrl,
      });
      resolve();
    });

    proxyReq.on('timeout', () => {
      proxyReq.destroy();
      res.status(504).json({ ok: false, error: 'Gateway Timeout (30s)' });
      resolve();
    });

    if (bodyStr) {
      proxyReq.write(bodyStr);
    }
    proxyReq.end();
  });
};
