const express = require('express');
const cors = require('cors');
require('dotenv').config();

const db = require('./db');
const authRoutes = require('./routes/auth');
const listingsRoutes = require('./routes/listings');
const claimsRoutes = require('./routes/claims');
const safetyRoutes = require('./routes/safety');
const notificationsRoutes = require('./routes/notifications');
const ngoRoutes = require('./routes/ngos');

const app = express();
const PORT = process.env.PORT || 5000;

// ----------------------------------------------------------------------------
// 1. CORE MIDDLEWARE
// ----------------------------------------------------------------------------

const corsOptions = {
  origin: process.env.CLIENT_URL || '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
};
app.use(cors(corsOptions));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging (development)
if (process.env.NODE_ENV !== 'test') {
  app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
      const duration = Date.now() - start;
      console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl} ${res.statusCode} (${duration}ms)`);
    });
    next();
  });
}

// ----------------------------------------------------------------------------
// 2. ROOT & HEALTH CHECK ROUTES
// ----------------------------------------------------------------------------

app.get('/', (req, res) => {
  res.json({
    name: 'FoodShare API (MySQL)',
    version: '1.0.0',
    description: 'Surplus food redistribution platform API with MySQL database',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      listings: '/api/listings',
      claims: '/api/claims',
      safety: '/api/safety',
      notifications: '/api/notifications',
      ngo: '/api/ngo',
    },
  });
});

app.get('/api/health', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT 1 AS alive');
    return res.json({
      status: 'UP',
      timestamp: new Date().toISOString(),
      database: rows[0]?.alive === 1 ? 'connected' : 'unknown',
    });
  } catch (err) {
    return res.status(503).json({
      status: 'DEGRADED',
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      error: err.message,
    });
  }
});

// ----------------------------------------------------------------------------
// 3. MODULAR API ROUTES
// ----------------------------------------------------------------------------

app.use('/api/auth', authRoutes);
app.use('/api/listings', listingsRoutes);
app.use('/api/claims', claimsRoutes);
app.use('/api/safety', safetyRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/ngo', ngoRoutes);
app.use('/api/ngos', ngoRoutes);

// ----------------------------------------------------------------------------
// 4. 404 NOT FOUND HANDLER
// ----------------------------------------------------------------------------

app.use((req, res) => {
  res.status(404).json({
    error: `Endpoint '${req.method} ${req.originalUrl}' does not exist on this server.`,
  });
});

// ----------------------------------------------------------------------------
// 5. CENTRALIZED ERROR HANDLING MIDDLEWARE
// ----------------------------------------------------------------------------

app.use((err, req, res, next) => {
  console.error(`💥 [Error] ${err.message}`, err.code || '');

  // MySQL specific error handling
  if (err.code === 'ER_DUP_ENTRY' || err.errno === 1062) {
    return res.status(409).json({
      error: 'Conflict: A record with this unique value already exists.',
      detail: err.sqlMessage || err.message,
    });
  }

  if (err.code === 'ER_NO_REFERENCED_ROW_2' || err.code === 'ER_ROW_IS_REFERENCED_2' || err.errno === 1452 || err.errno === 1451) {
    return res.status(400).json({
      error: 'Foreign key violation: referenced record does not exist or is constrained.',
      detail: err.sqlMessage || err.message,
    });
  }

  if (err.code === 'ER_CHECK_CONSTRAINT_VIOLATED' || err.errno === 3819) {
    return res.status(400).json({
      error: 'Validation failed: record violates database integrity check constraints.',
      detail: err.sqlMessage || err.message,
    });
  }

  if (err.code === 'WARN_DATA_TRUNCATED' || err.code === 'ER_DATA_TRUNCATED' || err.errno === 1265) {
    return res.status(400).json({
      error: 'Invalid enum value or truncated data provided.',
      detail: err.sqlMessage || err.message,
    });
  }

  const statusCode = err.statusCode || err.status || 500;
  res.status(statusCode).json({
    error: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// ----------------------------------------------------------------------------
// 6. SERVER INITIALIZATION & GRACEFUL SHUTDOWN
// ----------------------------------------------------------------------------

const server = app.listen(PORT, () => {
  console.log(`=========================================`);
  console.log(`🍽️  FoodShare API Server running on port ${PORT} (MySQL)`);
  console.log(`📡 URL: http://localhost:${PORT}`);
  console.log(`🏥 Health check: http://localhost:${PORT}/api/health`);
  console.log(`=========================================`);
});

process.on('SIGINT', async () => {
  console.log('\n🛑 SIGINT received. Shutting down gracefully...');
  server.close(async () => {
    await db.pool.end();
    console.log('✅ MySQL pool connections closed.');
    process.exit(0);
  });
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 SIGTERM received. Shutting down gracefully...');
  server.close(async () => {
    await db.pool.end();
    console.log('✅ MySQL pool connections closed.');
    process.exit(0);
  });
});

module.exports = app;
