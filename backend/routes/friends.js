const express = require('express');
const User = require('../models/User');
const FriendRequest = require('../models/FriendRequest');
const authMiddleware = require('../middleware/auth');
const router = express.Router();

router.get('/', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('friends', 'githubUsername displayName avatarUrl points level streak weeklyPoints');
    res.json({ friends: user.friends });
  } catch { res.status(500).json({ error: 'Failed to fetch friends' }); }
});

router.post('/request', authMiddleware, async (req, res) => {
  try {
    const { githubUsername } = req.body;
    if (!githubUsername) return res.status(400).json({ error: 'githubUsername required' });
    if (githubUsername === req.user.githubUsername) return res.status(400).json({ error: 'Cannot add yourself' });

    const target = await User.findOne({ githubUsername });
    if (!target) return res.status(404).json({ error: 'User not found' });
    if (req.user.friends.includes(target._id)) return res.status(400).json({ error: 'Already friends' });

    const existing = await FriendRequest.findOne({
      $or: [{ sender: req.user._id, receiver: target._id }, { sender: target._id, receiver: req.user._id }],
      status: 'pending',
    });
    if (existing) return res.status(400).json({ error: 'Friend request already exists' });

    const request = await FriendRequest.create({ sender: req.user._id, receiver: target._id });
    res.status(201).json({ message: 'Friend request sent', request });
  } catch (err) {
    res.status(500).json({ error: 'Failed to send request' });
  }
});

router.get('/requests', authMiddleware, async (req, res) => {
  try {
    const requests = await FriendRequest.find({ receiver: req.user._id, status: 'pending' })
      .populate('sender', 'githubUsername displayName avatarUrl points level');
    res.json({ requests });
  } catch { res.status(500).json({ error: 'Failed to fetch requests' }); }
});

router.patch('/request/:requestId', authMiddleware, async (req, res) => {
  try {
    const { action } = req.body;
    if (!['accept', 'decline'].includes(action)) return res.status(400).json({ error: 'Invalid action' });

    const request = await FriendRequest.findById(req.params.requestId);
    if (!request) return res.status(404).json({ error: 'Request not found' });
    if (!request.receiver.equals(req.user._id)) return res.status(403).json({ error: 'Not authorized' });
    if (request.status !== 'pending') return res.status(400).json({ error: 'Request already handled' });

    request.status = action === 'accept' ? 'accepted' : 'declined';
    request.respondedAt = new Date();
    await request.save();

    if (action === 'accept') {
      await User.findByIdAndUpdate(req.user._id, { $addToSet: { friends: request.sender } });
      await User.findByIdAndUpdate(request.sender, { $addToSet: { friends: req.user._id } });
    }

    res.json({ message: `Friend request ${action}ed` });
  } catch { res.status(500).json({ error: 'Failed to handle request' }); }
});

router.delete('/:friendId', authMiddleware, async (req, res) => {
  try {
    await User.findByIdAndUpdate(req.user._id, { $pull: { friends: req.params.friendId } });
    await User.findByIdAndUpdate(req.params.friendId, { $pull: { friends: req.user._id } });
    res.json({ message: 'Friend removed' });
  } catch { res.status(500).json({ error: 'Failed to remove friend' }); }
});

router.get('/leaderboard', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .populate('friends', 'githubUsername displayName avatarUrl points totalPoints weeklyPoints level streak');

    const all = [
      { githubUsername: req.user.githubUsername, displayName: req.user.displayName, avatarUrl: req.user.avatarUrl,
        points: req.user.points, totalPoints: req.user.totalPoints, weeklyPoints: req.user.weeklyPoints,
        level: req.user.level, streak: req.user.streak, isCurrentUser: true },
      ...user.friends.map((f) => ({ ...f.toObject(), isCurrentUser: false })),
    ];

    const ranked = all.sort((a, b) => b.weeklyPoints - a.weeklyPoints).map((u, i) => ({ ...u, rank: i + 1 }));
    res.json({ leaderboard: ranked });
  } catch { res.status(500).json({ error: 'Failed to fetch leaderboard' }); }
});

module.exports = router;
