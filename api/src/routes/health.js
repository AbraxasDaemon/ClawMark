/**
 * Health Check Routes
 */

const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'ClawMark API',
    version: '0.1.0',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

router.get('/ready', (req, res) => {
  // Check if service is ready to accept traffic
  res.json({ ready: true });
});

router.get('/live', (req, res) => {
  // Liveness probe
  res.json({ alive: true });
});

module.exports = router;
