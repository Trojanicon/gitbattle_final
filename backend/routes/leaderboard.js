const express = require('express');
const User = require('../models/User');
const authMiddleware = require('../middleware/auth');
const router = express.Router();

router.get('/global', authMiddleware, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 50, 100);
    const skip = (page - 1) * limit;

    const users = await User.find({ isActive: true })
      .select('githubUsername displayName avatarUrl totalPoints level streak achievements publicRepos')
      .sort({ totalPoints: -1 }).skip(skip).limit(limit).lean();

    const ranked = users.map((u, i) => ({ ...u, rank: skip + i + 1 }));
    const myRank = await User.countDocuments({ isActive: true, totalPoints: { $gt: req.user.totalPoints } }) + 1;
    const total = await User.countDocuments({ isActive: true });

    res.json({ leaderboard: ranked, pagination: { page, limit, total, pages: Math.ceil(total / limit) }, myRank });
  } catch { res.status(500).json({ error: 'Failed to fetch leaderboard' }); }
});

router.get('/weekly', authMiddleware, async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 50, 100);
    const users = await User.find({ isActive: true })
      .select('githubUsername displayName avatarUrl weeklyPoints totalPoints level streak')
      .sort({ weeklyPoints: -1 }).limit(limit).lean();

    const ranked = users.map((u, i) => ({ ...u, rank: i + 1 }));
    const myRank = await User.countDocuments({ isActive: true, weeklyPoints: { $gt: req.user.weeklyPoints } }) + 1;

    const now = new Date();
    const nextSunday = new Date();
    nextSunday.setUTCDate(now.getUTCDate() + ((7 - now.getUTCDay()) % 7 || 7));
    nextSunday.setUTCHours(0, 0, 0, 0);

    res.json({ leaderboard: ranked, myRank, myWeeklyPoints: req.user.weeklyPoints, nextResetAt: nextSunday });
  } catch { res.status(500).json({ error: 'Failed to fetch weekly leaderboard' }); }
});

router.get('/streak', authMiddleware, async (req, res) => {
  try {
    const users = await User.find({ isActive: true, streak: { $gt: 0 } })
      .select('githubUsername displayName avatarUrl streak longestStreak level')
      .sort({ streak: -1 }).limit(50).lean();
    res.json({ leaderboard: users.map((u, i) => ({ ...u, rank: i + 1 })) });
  } catch { res.status(500).json({ error: 'Failed to fetch streak leaderboard' }); }
});

module.exports = router;
