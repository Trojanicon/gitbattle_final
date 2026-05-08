const axios = require('axios');
const NodeCache = require('node-cache');

const cache = new NodeCache({ stdTTL: parseInt(process.env.CACHE_TTL) || 300 });
const GITHUB_API = 'https://api.github.com';

const githubRequest = async (url, token, params = {}) => {
  const cacheKey = `${url}?${JSON.stringify(params)}`;
  const cached = cache.get(cacheKey);
  if (cached) return cached;

  const response = await axios.get(url, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github.v3+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
    params,
  });

  cache.set(cacheKey, response.data);
  return response.data;
};

const getAuthenticatedUser = async (token) =>
  githubRequest(`${GITHUB_API}/user`, token);

const getUserRepos = async (username, token) =>
  githubRequest(`${GITHUB_API}/users/${username}/repos`, token, {
    sort: 'updated',
    per_page: 100,
    type: 'owner',
  });

const getRepoCommits = async (username, repo, token, since) => {
  try {
    return await githubRequest(
      `${GITHUB_API}/repos/${username}/${repo}/commits`,
      token,
      {
        author: username,
        since: since || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
        per_page: 100,
      }
    );
  } catch (err) {
    return [];
  }
};

const getAllCommits = async (username, token, days = 30) => {
  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();
  const repos = await getUserRepos(username, token);
  if (!repos || repos.length === 0) return [];

  const commitArrays = await Promise.allSettled(
    repos.map((repo) => getRepoCommits(username, repo.name, token, since))
  );

  const allCommits = [];
  commitArrays.forEach((result, index) => {
    if (result.status === 'fulfilled' && Array.isArray(result.value)) {
      result.value.forEach((commit) => {
        allCommits.push({ ...commit, repoName: repos[index].name });
      });
    }
  });

  return allCommits;
};

const calculateStreak = (dailyStats) => {
  if (!dailyStats || dailyStats.length === 0) return 0;

  const sorted = [...dailyStats].sort((a, b) => new Date(b.date) - new Date(a.date));
  let streak = 0;
  let currentDate = new Date();
  currentDate.setHours(0, 0, 0, 0);

  for (const stat of sorted) {
    const statDate = new Date(stat.date);
    statDate.setHours(0, 0, 0, 0);
    const diffDays = Math.floor((currentDate - statDate) / (1000 * 60 * 60 * 24));

    if ((diffDays === 0 || diffDays === 1) && stat.commits > 0) {
      streak++;
      currentDate = statDate;
    } else {
      break;
    }
  }

  return streak;
};

const syncUserData = async (user) => {
  const token = user.accessToken;
  const username = user.githubUsername;

  const profile = await getAuthenticatedUser(token);
  const repos = await getUserRepos(username, token);
  const allCommits = await getAllCommits(username, token, 30);

  const dailyMap = {};
  const seenHashes = new Set(user.lastCommitHashes || []);
  let totalNewCommits = 0;
  let totalPointsEarned = 0;

  for (const commit of allCommits) {
    const sha = commit.sha;
    if (seenHashes.has(sha)) continue;
    seenHashes.add(sha);

    const commitDate = new Date(commit.commit.author.date);
    const dateKey = commitDate.toISOString().split('T')[0];

    if (!dailyMap[dateKey]) {
      dailyMap[dateKey] = { date: new Date(dateKey), commits: 0, pointsEarned: 0, repositories: [] };
    }

    dailyMap[dateKey].commits++;
    totalNewCommits++;

    let points = 5;
    const msg = commit.commit.message || '';
    if (msg.length > 50) points += 3;
    if (dailyMap[dateKey].commits === 1) points += 20;

    dailyMap[dateKey].pointsEarned += points;
    totalPointsEarned += points;

    if (!dailyMap[dateKey].repositories.includes(commit.repoName)) {
      dailyMap[dateKey].repositories.push(commit.repoName);
    }
  }

  // New repo bonus
  const existingRepoCount = user.publicRepos || 0;
  if (profile.public_repos > existingRepoCount) {
    totalPointsEarned += (profile.public_repos - existingRepoCount) * 100;
  }

  // Merge daily stats
  const existingDailyMap = {};
  (user.dailyStats || []).forEach((s) => {
    const k = new Date(s.date).toISOString().split('T')[0];
    existingDailyMap[k] = s;
  });

  for (const [key, val] of Object.entries(dailyMap)) {
    if (existingDailyMap[key]) {
      existingDailyMap[key].commits += val.commits;
      existingDailyMap[key].pointsEarned += val.pointsEarned;
    } else {
      existingDailyMap[key] = val;
    }
  }

  const mergedDailyStats = Object.values(existingDailyMap)
    .sort((a, b) => new Date(a.date) - new Date(b.date))
    .slice(-30);

  const streak = calculateStreak(mergedDailyStats);
  if (streak > 0 && streak > (user.streak || 0)) totalPointsEarned += 50;

  const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  const commitsThisWeek = mergedDailyStats
    .filter((s) => new Date(s.date) >= oneWeekAgo)
    .reduce((sum, s) => sum + s.commits, 0);
  const commitsThisMonth = mergedDailyStats.reduce((sum, s) => sum + s.commits, 0);

  user.displayName = profile.name || username;
  user.avatarUrl = profile.avatar_url;
  user.email = profile.email || user.email;
  user.bio = profile.bio || '';
  user.location = profile.location || '';
  user.publicRepos = profile.public_repos;
  user.followers = profile.followers;
  user.following = profile.following;
  user.totalCommits = (user.totalCommits || 0) + totalNewCommits;
  user.commitsThisWeek = commitsThisWeek;
  user.commitsThisMonth = commitsThisMonth;
  user.dailyStats = mergedDailyStats;
  user.streak = streak;
  user.longestStreak = Math.max(streak, user.longestStreak || 0);
  user.points = (user.points || 0) + totalPointsEarned;
  user.totalPoints = (user.totalPoints || 0) + totalPointsEarned;
  user.weeklyPoints = (user.weeklyPoints || 0) + totalPointsEarned;
  user.level = user.computeLevel();
  user.lastSyncedAt = new Date();
  user.lastCommitHashes = Array.from(seenHashes).slice(-500);

  return user;
};

module.exports = { getAuthenticatedUser, getUserRepos, getAllCommits, calculateStreak, syncUserData };
