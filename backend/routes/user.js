const express = require('express');
const User = require('../models/User');
const authMiddleware = require('../middleware/auth');
const { getLevelInfo } = require('../services/gamificationService');

const router = express.Router();

router.get('/profile', authMiddleware, (req, res) => {
  const profile = req.user.toPublicProfile();
  profile.levelInfo = getLevelInfo(req.user.level);
  res.json({ user: profile });
});

router.get('/insights/personal', authMiddleware, async (req, res) => {
  try {
    const user = req.user;
    const stats = user.dailyStats || [];
    const insights = [];

    if (stats.length > 0) {
      const avg = stats.reduce((s, d) => s + d.commits, 0) / stats.length;
      insights.push(`📊 You average ${avg.toFixed(1)} commits per day`);
    }
    if (user.streak >= 3) insights.push(`🔥 Your ${user.streak}-day streak is on fire! Keep it up!`);
    if ((user.commitsThisWeek || 0) > 10) insights.push(`⚡ Great week! You've made ${user.commitsThisWeek} commits this week`);

    const bestDay = [...stats].sort((a, b) => b.commits - a.commits)[0];
    if (bestDay) insights.push(`🏆 Best day: ${new Date(bestDay.date).toDateString()} with ${bestDay.commits} commits`);
    if (user.totalPoints >= 1000) insights.push(`💰 You've crossed 1,000 total points — you're in the top tier!`);

    res.json({ insights });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch insights' });
  }
});

router.get('/:username', authMiddleware, async (req, res) => {
  try {
    const user = await User.findOne({ githubUsername: req.params.username });
    if (!user) return res.status(404).json({ error: 'User not found' });
    const isFriend = req.user.friends.some((f) => f.equals(user._id));
    const profile = user.toPublicProfile();
    profile.isFriend = isFriend;
    profile.levelInfo = getLevelInfo(user.level);
    res.json({ user: profile });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

module.exports = router;
