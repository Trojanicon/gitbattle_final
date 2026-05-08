⚔️** GitBattle — Commit Clash**
GitBattle is a mobile app I’m building to make GitHub activity a bit more competitive. The idea is simple: you earn XP for commits, climb leaderboards against your friends, and unlock badges for being consistent.

I built this because seeing a green square on a contribution graph is cool, but seeing yourself beat your classmates on a leaderboard is better.

🛠** Project Status: Work in Progress** ⚠️
I'll be honest—this is a heavy WIP. i was kinda busy at the begining of the yaer, but in the comming month, it will be live

**Backend:**
Mostly functional (Node.js/Express). OAuth and point calculations are logic-ready.

**Frontend:**
Flutter-based. UI is mostly there, but deep linking and the actual data sync are currently buggy. * Known Issues: The GitHub OAuth callback sometimes hangs on mobile, and I'm still tuning the "Commit Monster" logic.

🏗️ **How it works (The magic)**
Frontend: Flutter + Provider (for state). I wanted something that felt snappy on both Android and iOS.

Backend: Node.js & Express.

**Database: **
MongoDB. It stores user stats, friend lists, and active "Battle" challenges.

The Secret Sauce: A background job (syncJob.js) that pings GitHub to see if you’ve actually been working or just talking about it.


🎮** The Gamification Logic (elewa venye iko)**
I’m trying to keep the points fair so people don't just spam "typo" commits:

Daily First: +20 XP

Standard Commit: +5 XP

The "Long Message" Bonus: +3 XP (to encourage actually writing READMEs)

Streaks: Extra XP if you commit 3+ days in a row
