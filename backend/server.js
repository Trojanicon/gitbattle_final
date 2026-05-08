require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const connectDB = require('./config/database');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const friendsRoutes = require('./routes/friends');
const leaderboardRoutes = require('./routes/leaderboard');
const challengesRoutes = require('./routes/challenges');
const { startSyncJob, startWeeklyReset, startChallengeStatusJob } = require('./jobs/syncJob');

const app = express();
const PORT = process.env.PORT || 3000;

// ── Security & Middleware ─────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({ origin: '*', methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'] }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
if (process.env.NODE_ENV !== 'test') app.use(morgan('combined'));

// ── Rate Limiting ─────────────────────────────────────────────────────────────
app.use('/api/', rateLimit({ windowMs: 15 * 60 * 1000, max: 200 }));
app.use('/auth', rateLimit({ windowMs: 60 * 60 * 1000, max: 30 }));

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/auth', authRoutes);
app.use('/user', userRoutes);
app.use('/friends', friendsRoutes);
app.use('/leaderboard', leaderboardRoutes);
app.use('/challenges', challengesRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString(), version: '1.0.0' });
});

app.use((req, res) => res.status(404).json({ error: 'Route not found' }));
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message });
});

// ── Start ─────────────────────────────────────────────────────────────────────
const start = async () => {
  await connectDB();
  app.listen(PORT, () => {
    console.log(`
╔═══════════════════════════════════════╗
║          GitBattle API Server         ║
║                                       ║
║  🚀 Running on http://localhost:${PORT}  ║
║  🌍 Environment: ${(process.env.NODE_ENV || 'development').padEnd(12)} ║
╚═══════════════════════════════════════╝
    `);
  });

  if (process.env.NODE_ENV !== 'test') {
    startSyncJob();
    startWeeklyReset();
    startChallengeStatusJob();
  }
};

start().catch((err) => { console.error('Failed to start server:', err); process.exit(1); });
module.exports = app;
