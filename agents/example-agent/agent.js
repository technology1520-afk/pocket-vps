// example-agent: minimal always-on agent template
// Copy this folder to /root/vps/agents/my-agent/ and adapt.
// Start with: pm2 start ~/vps/agents/my-agent/agent.js --name my-agent && pm2 save

const http = require('http');

const PORT = process.env.AGENT_PORT || 3000;
const NAME = process.env.AGENT_NAME || 'example-agent';

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    agent: NAME,
    status: 'alive',
    uptime_s: Math.floor(process.uptime()),
    pid: process.pid,
    time: new Date().toISOString()
  }));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[${NAME}] listening on 0.0.0.0:${PORT}`);
});

// graceful shutdown so PM2 restarts are clean
process.on('SIGINT', () => { console.log(`[${NAME}] bye`); process.exit(0); });
process.on('SIGTERM', () => { console.log(`[${NAME}] bye`); process.exit(0); });
