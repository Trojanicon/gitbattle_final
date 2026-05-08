const cron = require('node-cron');
const User = require('../models/User');
const { syncUserData } = require('../services/githubService');
const { checkAchievements } = require('../services/gamificationService');

const startSyncJob = () => {
  const interval = process.env.SYNC_INTERVAL_MINUTES || 15;
  console.log(`📡 GitHub sync job starting — every ${interval} minutes`);

  cron.schedule(`*/${interval} * * * *`, async () => {
    console.log(`🔄 [${new Date().toISOString()}] Syncing GitHub data...`);
    try {
      const users = await User.find({ isActive: true }).select('+accessToken').limit(200);
      const batchSize = 10;

      for (let i = 0; i < users.length; i += batchSize) {
        await Promise.allSettled(
          users.slice(i, i + batchSize).map(async (user) => {
            try {
              const updated = await syncUserData(user);
              checkAchievements(updated);
              await updated.save();
            } catch (err) {
              console.error(`Sync failed for ${user.githubUsername}:`, err.message);
            }
          })
        );
        if (i + batchSize < users.length) await new Promise((r) => setTimeout(r, 2000));
      }
      console.log(`✅ Sync complete — ${users.length} users`);
    } catch (err) {
      console.error('Sync job error:', err.message);
    }
  });
};

const startWeeklyReset = () => {
  console.log('📅 Weekly reset job starting — Sundays at midnight UTC');
  cron.schedule('0 0 * * 0', async () => {
    try {
      await User.updateMany({}, { $set: { weeklyPoints: 0 } });
      console.log('✅ Weekly points reset');
    } catch (err) {
      console.error('Weekly reset error:', err.message);
    }
  });
};

const startChallengeStatusJob = () => {
  cron.schedule('0 * * * *', async () => {
    try {
      const Challenge = require('../models/Challenge');
      const now = new Date();
      await Challenge.updateMany({ startDate: { $lte: now }, endDate: { $gte: now }, status: 'upcoming' }, { $set: { status: 'active' } });
      await Challenge.updateMany({ endDate: { $lt: now }, status: { $ne: 'completed' } }, { $set: { status: 'completed' } });
    } catch (err) {
      console.error('Challenge status job error:', err.message);
    }
  });
};

module.exports = { startSyncJob, startWeeklyReset, startChallengeStatusJob };
