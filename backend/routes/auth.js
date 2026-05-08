const express = require('express');
const axios = require('axios');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { syncUserData } = require('../services/githubService');
const { checkAchievements } = require('../services/gamificationService');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// GET /auth/github — redirect to GitHub OAuth
router.get('/github', (req, res) => {
  const params = new URLSearchParams({
    client_id: process.env.GITHUB_CLIENT_ID,
    redirect_uri: process.env.GITHUB_REDIRECT_URI,
    scope: 'read:user user:email repo',
    state: Math.random().toString(36).substring(7),
  });
  res.redirect(`https://github.com/login/oauth/authorize?${params}`);
});

// GET /auth/github/callback
router.get('/github/callback', async (req, res) => {
  const { code } = req.query;
  if (!code) return res.redirect(`${process.env.FRONTEND_URL}?error=no_code`);

  try {
    const tokenRes = await axios.post(
      'https://github.com/login/oauth/access_token',
      { client_id: process.env.GITHUB_CLIENT_ID, client_secret: process.env.GITHUB_CLIENT_SECRET, code, redirect_uri: process.env.GITHUB_REDIRECT_URI },
      { headers: { Accept: 'application/json' } }
    );
    const { access_token, error } = tokenRes.data;
    if (error || !access_token) return res.redirect(`${process.env.FRONTEND_URL}?error=token_exchange_failed`);

    const profileRes = await axios.get('https://api.github.com/user', {
      headers: { Authorization: `Bearer ${access_token}`, Accept: 'application/vnd.github.v3+json' },
    });
    const profile = profileRes.data;

    let user = await User.findOne({ githubId: String(profile.id) }).select('+accessToken');
    if (!user) {
      user = new User({
        githubId: String(profile.id), githubUsername: profile.login,
        displayName: profile.name || profile.login, avatarUrl: profile.avatar_url,
        email: profile.email || '', accessToken: access_token, achievements: [], dailyStats: [], friends: [],
      });
    } else {
      user.accessToken = access_token;
      user.githubUsername = profile.login;
    }
    user = await syncUserData(user);
    checkAchievements(user);
    await user.save();

    const jwtToken = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '30d' });
    res.redirect(`${process.env.FRONTEND_URL}?token=${jwtToken}&username=${user.githubUsername}`);
  } catch (err) {
    console.error('OAuth callback error:', err.message);
    res.redirect(`${process.env.FRONTEND_URL}?error=server_error`);
  }
});

// POST /auth/mobile — exchange code for JWT (mobile app flow)
router.post('/mobile', async (req, res) => {
  const { code } = req.body;
  if (!code) return res.status(400).json({ error: 'Code is required' });

  try {
    const tokenRes = await axios.post(
      'https://github.com/login/oauth/access_token',
      { client_id: process.env.GITHUB_CLIENT_ID, client_secret: process.env.GITHUB_CLIENT_SECRET, code },
      { headers: { Accept: 'application/json' } }
    );
    const { access_token, error } = tokenRes.data;
    if (error || !access_token) return res.status(400).json({ error: 'Token exchange failed', details: error });

    const profileRes = await axios.get('https://api.github.com/user', {
      headers: { Authorization: `Bearer ${access_token}`, Accept: 'application/vnd.github.v3+json' },
    });
    const profile = profileRes.data;

    let user = await User.findOne({ githubId: String(profile.id) }).select('+accessToken');
    if (!user) {
      user = new User({
        githubId: String(profile.id), githubUsername: profile.login,
        displayName: profile.name || profile.login, avatarUrl: profile.avatar_url,
        email: profile.email || '', accessToken: access_token, achievements: [], dailyStats: [], friends: [],
      });
    } else {
      user.accessToken = access_token;
    }

    user = await syncUserData(user);
    checkAchievements(user);
    await user.save();

    const jwtToken = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '30d' });
    res.json({ token: jwtToken, user: user.toPublicProfile() });
  } catch (err) {
    console.error('Mobile auth error:', err.message);
    res.status(500).json({ error: 'Authentication failed' });
  }
});

// GET /auth/me
router.get('/me', authMiddleware, (req, res) => {
  res.json({ user: req.user.toPublicProfile() });
});

// POST /auth/sync
router.post('/sync', authMiddleware, async (req, res) => {
  try {
    let user = req.user;
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    if (user.lastSyncedAt && user.lastSyncedAt > fiveMinutesAgo) {
      return res.json({ message: 'Already synced recently', user: user.toPublicProfile() });
    }
    user = await syncUserData(user);
    const newAchievements = checkAchievements(user);
    await user.save();
    res.json({ user: user.toPublicProfile(), newAchievements });
  } catch (err) {
    console.error('Sync error:', err.message);
    res.status(500).json({ error: 'Sync failed' });
  }
});

// DELETE /auth/logout
router.delete('/logout', authMiddleware, (req, res) => {
  res.json({ message: 'Logged out successfully' });
});

module.exports = router;
