#!/bin/bash
set -e

echo ""
echo "⚔️  GitBattle Backend Setup"
echo "══════════════════════════════"

# Check Node.js
if ! command -v node &> /dev/null; then
  echo "❌ Node.js not found. Install from https://nodejs.org"; exit 1
fi
NODE_VER=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VER" -lt 18 ]; then
  echo "❌ Node.js 18+ required (you have $(node -v))"; exit 1
fi
echo "✅ Node.js $(node -v)"

# Check MongoDB
if ! command -v mongod &> /dev/null && ! command -v mongosh &> /dev/null; then
  echo "⚠️  mongod not found locally — make sure MongoDB is running or use Atlas"
else
  echo "✅ MongoDB found"
fi

# Install dependencies
echo ""
echo "📦 Installing npm packages..."
npm install

# Create .env if not exists
if [ ! -f .env ]; then
  cp .env.example .env
  echo ""
  echo "📝 Created .env from .env.example"
  echo "   ⚠️  Open .env and fill in:"
  echo "      GITHUB_CLIENT_ID"
  echo "      GITHUB_CLIENT_SECRET"
  echo "      JWT_SECRET (any long random string)"
  echo "      MONGODB_URI (if using Atlas)"
else
  echo "✅ .env already exists"
fi

echo ""
echo "══════════════════════════════"
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Edit .env with your GitHub OAuth credentials"
echo "  2. Run: npm run dev"
echo "  3. Test: curl http://localhost:3000/health"
echo ""
