/**
 * Vercel Serverless Function Proxy
 * ======================================================================
 * Redirige de forma transparente las peticiones desde el frontend de Vercel
 * hacia el Servidor Central (VPS) leyendo la variable de entorno privada VPS_URL.
 *
 * Cero IPs expuestas en GitHub — 100% Privado y Seguro.
 * ======================================================================
 */

module.exports = async (req, res) => {
  // Configuración de cabeceras CORS
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Key');

  // Responder a preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Leer la variable privada desde Vercel
  const vpsUrl = (process.env.VPS_URL || 'http://localhost:3505').replace(/\/$/, '');

  // Limpiar la subruta recibida (ej: /api/agents -> /agents)
  let subpath = req.url || '';
  if (subpath.startsWith('/api')) {
    subpath = subpath.substring(4);
  }
  if (!subpath.startsWith('/')) {
    subpath = '/' + subpath;
  }

  const targetUrl = `${vpsUrl}${subpath}`;

  try {
    const fetchOptions = {
      method: req.method,
      headers: {
        'Content-Type': 'application/json',
        'X-Api-Key': req.headers['x-api-key'] || 'demo-api-key-tesis-2026',
      },
    };

    if (req.method !== 'GET' && req.method !== 'HEAD' && req.body) {
      fetchOptions.body = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
    }

    const response = await fetch(targetUrl, fetchOptions);
    const data = await response.json();
    return res.status(response.status).json(data);
  } catch (err) {
    return res.status(500).json({
      ok: false,
      error: `Error de Proxy Serverless Vercel: ${err.message}`,
      targetUrl,
    });
  }
};
