const ACHIEVEMENTS = [
  { id: 'first_commit',       name: 'First Blood',        description: 'Made your first commit',       icon: '🎯', condition: (u) => u.totalCommits >= 1 },
  { id: 'ten_commits',        name: 'Getting Started',    description: 'Reached 10 commits',           icon: '🚀', condition: (u) => u.totalCommits >= 10 },
  { id: 'fifty_commits',      name: 'Code Machine',       description: 'Reached 50 commits',           icon: '⚡', condition: (u) => u.totalCommits >= 50 },
  { id: 'hundred_commits',    name: 'Century Club',       description: 'Reached 100 commits',          icon: '💯', condition: (u) => u.totalCommits >= 100 },
  { id: 'five_hundred',       name: 'Commit Monster',     description: 'Reached 500 commits',          icon: '👾', condition: (u) => u.totalCommits >= 500 },
  { id: 'streak_3',           name: 'Hot Start',          description: '3-day commit streak',          icon: '🔥', condition: (u) => u.streak >= 3 },
  { id: 'streak_7',           name: 'Week Warrior',       description: '7-day commit streak',          icon: '🏆', condition: (u) => u.streak >= 7 },
  { id: 'streak_30',          name: 'Month of Code',      description: '30-day commit streak',         icon: '💎', condition: (u) => u.streak >= 30 },
  { id: 'level_5',            name: 'Rising Dev',         description: 'Reached Level 5',              icon: '⭐', condition: (u) => u.level >= 5 },
  { id: 'level_10',           name: 'Elite Coder',        description: 'Reached Level 10',             icon: '🌟', condition: (u) => u.level >= 10 },
  { id: 'five_repos',         name: 'Project Hoarder',    description: 'Created 5 repositories',       icon: '📁', condition: (u) => u.publicRepos >= 5 },
  { id: 'social_butterfly',   name: 'Social Butterfly',   description: 'Added 5 friends',              icon: '🦋', condition: (u) => (u.friends || []).length >= 5 },
  { id: 'thousand_points',    name: 'Point Millionaire',  description: 'Earned 1,000 total points',    icon: '💰', condition: (u) => u.totalPoints >= 1000 },
];

const checkAchievements = (user) => {
  const existingIds = new Set((user.achievements || []).map((a) => a.id));
  const newlyUnlocked = [];

  for (const achievement of ACHIEVEMENTS) {
    if (!existingIds.has(achievement.id) && achievement.condition(user)) {
      const unlocked = {
        id: achievement.id,
        name: achievement.name,
        description: achievement.description,
        icon: achievement.icon,
        unlockedAt: new Date(),
      };
      user.achievements.push(unlocked);
      newlyUnlocked.push(unlocked);
    }
  }

  return newlyUnlocked;
};

const getLevelInfo = (level) => {
  const levels = [
    { level: 1,  title: 'Newbie',       minPoints: 0 },
    { level: 2,  title: 'Apprentice',   minPoints: 100 },
    { level: 3,  title: 'Developer',    minPoints: 300 },
    { level: 4,  title: 'Coder',        minPoints: 600 },
    { level: 5,  title: 'Hacker',       minPoints: 1000 },
    { level: 6,  title: 'Engineer',     minPoints: 1500 },
    { level: 7,  title: 'Architect',    minPoints: 2500 },
    { level: 8,  title: 'Wizard',       minPoints: 4000 },
    { level: 9,  title: 'Grandmaster',  minPoints: 6000 },
    { level: 10, title: 'Legend',       minPoints: 10000 },
  ];
  return levels.find((l) => l.level === level) || levels[0];
};

module.exports = { checkAchievements, ACHIEVEMENTS, getLevelInfo };
