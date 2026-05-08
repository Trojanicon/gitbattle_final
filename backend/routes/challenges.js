const express = require('express');
const Challenge = require('../models/Challenge');
const authMiddleware = require('../middleware/auth');
const router = express.Router();

const computeStatus = (c) => {
  const now = new Date();
  if (now < new Date(c.startDate)) return 'upcoming';
  if (now > new Date(c.endDate)) return 'completed';
  return 'active';
};

router.get('/', authMiddleware, async (req, res) => {
  try {
    const challenges = await Challenge.find({
      $or: [{ isPublic: true, endDate: { $gte: new Date() } }, { 'participants.user': req.user._id }],
    })
      .populate('creator', 'githubUsername avatarUrl')
      .populate('participants.user', 'githubUsername avatarUrl displayName')
      .sort({ startDate: -1 }).limit(50).lean();

    res.json({
      challenges: challenges.map((c) => ({
        ...c,
        status: computeStatus(c),
        isParticipant: c.participants.some((p) => p.user?._id?.toString() === req.user._id.toString()),
      })),
    });
  } catch { res.status(500).json({ error: 'Failed to fetch challenges' }); }
});

router.post('/', authMiddleware, async (req, res) => {
  try {
    const { name, description, type, goal, duration, isPublic, startDate } = req.body;
    if (!name || !type || !goal || !duration) return res.status(400).json({ error: 'name, type, goal, duration required' });
    if (!['commit_count', 'streak', 'points', 'repo_count'].includes(type)) return res.status(400).json({ error: 'Invalid type' });

    const start = startDate ? new Date(startDate) : new Date();
    const end = new Date(start);
    end.setDate(end.getDate() + duration);

    const challenge = await Challenge.create({
      name, description: description || '', creator: req.user._id, type, goal, duration,
      isPublic: isPublic !== false, startDate: start, endDate: end,
      participants: [{ user: req.user._id, progress: 0 }],
    });

    await challenge.populate('creator', 'githubUsername avatarUrl');
    res.status(201).json({ challenge });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create challenge' });
  }
});

router.post('/:id/join', authMiddleware, async (req, res) => {
  try {
    const challenge = await Challenge.findById(req.params.id);
    if (!challenge) return res.status(404).json({ error: 'Challenge not found' });
    if (challenge.endDate < new Date()) return res.status(400).json({ error: 'Challenge has ended' });
    if (challenge.participants.some((p) => p.user.equals(req.user._id))) return res.status(400).json({ error: 'Already participating' });
    if (challenge.participants.length >= challenge.maxParticipants) return res.status(400).json({ error: 'Challenge is full' });

    challenge.participants.push({ user: req.user._id, progress: 0 });
    await challenge.save();
    res.json({ message: 'Joined challenge', challenge });
  } catch { res.status(500).json({ error: 'Failed to join' }); }
});

router.post('/join-code/:code', authMiddleware, async (req, res) => {
  try {
    const challenge = await Challenge.findOne({ inviteCode: req.params.code.toUpperCase() });
    if (!challenge) return res.status(404).json({ error: 'Invalid invite code' });
    if (challenge.participants.some((p) => p.user.equals(req.user._id))) return res.status(400).json({ error: 'Already participating' });

    challenge.participants.push({ user: req.user._id, progress: 0 });
    await challenge.save();
    res.json({ message: 'Joined challenge', challenge });
  } catch { res.status(500).json({ error: 'Failed to join by code' }); }
});

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const challenge = await Challenge.findById(req.params.id)
      .populate('creator', 'githubUsername avatarUrl displayName')
      .populate('participants.user', 'githubUsername avatarUrl displayName points totalCommits streak weeklyPoints publicRepos');

    if (!challenge) return res.status(404).json({ error: 'Challenge not found' });

    const updatedParticipants = challenge.participants.map((p) => {
      if (!p.user) return p;
      let progress = 0;
      switch (challenge.type) {
        case 'commit_count': progress = p.user.commitsThisMonth || 0; break;
        case 'streak': progress = p.user.streak || 0; break;
        case 'points': progress = p.user.weeklyPoints || 0; break;
        case 'repo_count': progress = p.user.publicRepos || 0; break;
      }
      return { ...p.toObject(), progress, progressPercentage: Math.min(100, (progress / challenge.goal) * 100) };
    }).sort((a, b) => b.progress - a.progress);

    res.json({ challenge: { ...challenge.toObject(), participants: updatedParticipants, status: computeStatus(challenge) } });
  } catch { res.status(500).json({ error: 'Failed to fetch challenge' }); }
});

router.delete('/:id/leave', authMiddleware, async (req, res) => {
  try {
    const challenge = await Challenge.findById(req.params.id);
    if (!challenge) return res.status(404).json({ error: 'Not found' });
    if (challenge.creator.equals(req.user._id)) return res.status(400).json({ error: 'Creator cannot leave' });
    challenge.participants = challenge.participants.filter((p) => !p.user.equals(req.user._id));
    await challenge.save();
    res.json({ message: 'Left challenge' });
  } catch { res.status(500).json({ error: 'Failed to leave' }); }
});

module.exports = router;
