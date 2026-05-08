const mongoose = require('mongoose');

const ParticipantSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  progress: { type: Number, default: 0 },
  joinedAt: { type: Date, default: Date.now },
  completed: { type: Boolean, default: false },
  completedAt: { type: Date, default: null },
  rank: { type: Number, default: null },
});

const ChallengeSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
    creator: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: {
      type: String,
      enum: ['commit_count', 'streak', 'points', 'repo_count'],
      required: true,
    },
    goal: { type: Number, required: true },
    duration: { type: Number, required: true },
    isPublic: { type: Boolean, default: true },
    inviteCode: { type: String, unique: true, sparse: true },
    participants: [ParticipantSchema],
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    status: {
      type: String,
      enum: ['upcoming', 'active', 'completed'],
      default: 'upcoming',
    },
    winner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    maxParticipants: { type: Number, default: 50 },
  },
  { timestamps: true }
);

ChallengeSchema.pre('save', function (next) {
  if (!this.inviteCode) {
    this.inviteCode = Math.random().toString(36).substring(2, 8).toUpperCase();
  }
  next();
});

const Challenge = mongoose.model('Challenge', ChallengeSchema);
module.exports = Challenge;
