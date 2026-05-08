const mongoose = require('mongoose');

const AchievementSchema = new mongoose.Schema({
  id: { type: String, required: true },
  name: { type: String, required: true },
  description: { type: String, required: true },
  icon: { type: String, required: true },
  unlockedAt: { type: Date, default: Date.now },
});

const DailyStatSchema = new mongoose.Schema({
  date: { type: Date, required: true },
  commits: { type: Number, default: 0 },
  pointsEarned: { type: Number, default: 0 },
  repositories: [String],
});

const UserSchema = new mongoose.Schema(
  {
    githubId: { type: String, required: true, unique: true, index: true },
    githubUsername: { type: String, required: true, unique: true, index: true },
    displayName: { type: String, default: '' },
    avatarUrl: { type: String, default: '' },
    email: { type: String, default: '' },
    bio: { type: String, default: '' },
    location: { type: String, default: '' },
    publicRepos: { type: Number, default: 0 },
    followers: { type: Number, default: 0 },
    following: { type: Number, default: 0 },
    accessToken: { type: String, required: true, select: false },
    points: { type: Number, default: 0, index: true },
    totalPoints: { type: Number, default: 0 },
    level: { type: Number, default: 1 },
    streak: { type: Number, default: 0 },
    longestStreak: { type: Number, default: 0 },
    lastCommitDate: { type: Date, default: null },
    lastSyncedAt: { type: Date, default: null },
    totalCommits: { type: Number, default: 0 },
    commitsThisWeek: { type: Number, default: 0 },
    commitsThisMonth: { type: Number, default: 0 },
    repositoriesCreated: { type: Number, default: 0 },
    dailyStats: [DailyStatSchema],
    friends: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    achievements: [AchievementSchema],
    weeklyPoints: { type: Number, default: 0 },
    weeklyResetAt: { type: Date, default: Date.now },
    lastCommitHashes: [String],
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

UserSchema.methods.computeLevel = function () {
  const thresholds = [0, 100, 300, 600, 1000, 1500, 2500, 4000, 6000, 10000];
  let level = 1;
  for (let i = 0; i < thresholds.length; i++) {
    if (this.totalPoints >= thresholds[i]) level = i + 1;
    else break;
  }
  return level;
};

UserSchema.methods.toPublicProfile = function () {
  return {
    id: this._id,
    githubUsername: this.githubUsername,
    displayName: this.displayName,
    avatarUrl: this.avatarUrl,
    bio: this.bio,
    points: this.points,
    totalPoints: this.totalPoints,
    level: this.level,
    streak: this.streak,
    longestStreak: this.longestStreak,
    totalCommits: this.totalCommits,
    commitsThisWeek: this.commitsThisWeek,
    commitsThisMonth: this.commitsThisMonth,
    achievements: this.achievements,
    publicRepos: this.publicRepos,
    followers: this.followers,
    weeklyPoints: this.weeklyPoints,
    dailyStats: this.dailyStats.slice(-30),
    lastSyncedAt: this.lastSyncedAt,
  };
};

const User = mongoose.model('User', UserSchema);
module.exports = User;
