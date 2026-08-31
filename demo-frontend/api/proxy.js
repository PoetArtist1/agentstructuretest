const http = require('http');
const https = require('https');

module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,POST');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Api-Key');

  if (req.method === 'OPTIONS') return res.status(200).end();

  const vpsUrl = (process.env.VPS_URL || 'http://localhost:3505').replace(/\/$/, '');

  // /api/proxy?path=agents          → /agents
  // /api/proxy?path=query/tesis_demo → /query/tesis_demo
  const subpath = req.query.path || '';
  const targetUrl = `${vpsUrl}/${subpath}`;

  let bodyStr = '';
  if (req.method === 'POST' && req.body) {
    bodyStr = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);
  }

  const parsed = new URL(targetUrl);
  const transport = parsed.protocol === 'https:' ? https : http;

  const options = {
    hostname: parsed.hostname,
    port: parsed.port,
    path: parsed.pathname,
    method: req.method,
    headers: {
      'Content-Type': 'application/json',
      'X-Api-Key': req.headers['x-api-key'] || 'demo-api-key-tesis-2026',
    },
    timeout: 30000,
  };

  if (bodyStr) options.headers['Content-Length'] = Buffer.byteLength(bodyStr);

  return new Promise((resolve) => {
    const proxyReq = transport.request(options, (proxyRes) => {
      let data = '';
      proxyRes.on('data', (c) => { data += c; });
      proxyRes.on('end', () => {
        try { res.status(proxyRes.statusCode).json(JSON.parse(data)); }
        catch { res.status(proxyRes.statusCode).send(data); }
        resolve();
      });
    });

    proxyReq.on('error', (err) => {
      res.status(502).json({ ok: false, error: err.message });
      resolve();
    });

    proxyReq.on('timeout', () => {
      proxyReq.destroy();
      res.status(504).json({ ok: false, error: 'Timeout' });
      resolve();
    });

    if (bodyStr) proxyReq.write(bodyStr);
    proxyReq.end();
  });
};
