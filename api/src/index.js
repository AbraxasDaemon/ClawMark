/**
 * ClawMark API Server
 * 
 * REST API for DID management, credential operations, and reputation queries
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const didRoutes = require('./routes/did');
const credentialRoutes = require('./routes/credentials');
const reputationRoutes = require('./routes/reputation');
const healthRoutes = require('./routes/health');
const moltbookRoutes = require('./routes/moltbook');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: { error: 'Too many requests, please try again later' }
});
app.use(limiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Compression
app.use(compression());

// Logging
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// Routes
app.use('/v1/did', didRoutes);
app.use('/v1/credentials', credentialRoutes);
app.use('/v1/reputation', reputationRoutes);
app.use('/v1/moltbook', moltbookRoutes);
app.use('/health', healthRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'ClawMark API',
    version: '0.1.0',
    status: 'operational',
    documentation: '/v1/docs',
    endpoints: {
      did: '/v1/did',
      credentials: '/v1/credentials',
      reputation: '/v1/reputation',
      moltbook: '/v1/moltbook',
      health: '/health'
    }
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

app.listen(PORT, () => {
  console.log(`🦞 ClawMark API running on port ${PORT}`);
  console.log(`   Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`   Docs: http://localhost:${PORT}/`);
});

module.exports = app;
