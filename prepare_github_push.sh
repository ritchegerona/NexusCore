#!/usr/bin/env bash
set -e

echo "🚀 Preparing NexusCore for GitHub Push..."

# 1. Update all documentation with actual GitHub username
GITHUB_USERNAME="ritchelinuxlab"
REPO_URL="https://github.com/${GITHUB_USERNAME}/NexusCore.git"

echo "📝 Updating documentation with GitHub username..."

# Update README.md
sed -i '' "s|<your-private-repo-url>|${REPO_URL}|g" README.md

# Update ARCHITECTURE.md
sed -i '' "s|YOUR_USERNAME|${GITHUB_USERNAME}|g" ARCHITECTURE.md

# 2. Create a .github/FUNDING.yml (optional, for future)
mkdir -p .github
cat > .github/FUNDING.yml <<EOF
# Support NexusCore development
github: ${GITHUB_USERNAME}
EOF

# 3. Commit all updates
git add .
git commit -m "chore: prepare for GitHub push to ${GITHUB_USERNAME}/NexusCore"

echo ""
echo "========================================="
echo " ✅ Preparation Complete!"
echo "========================================="
echo ""
echo " 📋 Next Steps:"
echo ""
echo " 1. Go to GitHub and create a PRIVATE repository:"
echo "    https://github.com/new"
echo ""
echo " 2. Fill in the details:"
echo "    - Repository name: NexusCore"
echo "    - ⚠️  IMPORTANT: Select 'Private' (NOT Public)"
echo "    - Description: A modular Rust workspace framework"
echo "    - DO NOT initialize with README"
echo ""
echo " 3. After creating the repo, run these commands:"
echo ""
echo "    git remote add origin ${REPO_URL}"
echo "    git branch -M main"
echo "    git push -u origin main"
echo ""
echo " 🔒 Your repository will be PRIVATE and secure!"
echo ""
echo " 📚 Your GitHub Profile: https://github.com/${GITHUB_USERNAME}"