# Git Upload Instructions

This guide will help you upload your e-commerce project to a Git repository (GitHub, GitLab, etc.).

## Prerequisites

### 1. Install Git
```bash
# For RHEL/CentOS/Fedora
sudo yum install git-core

# Or download from: https://git-scm.com/downloads
```

### 2. Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Upload to GitHub

### Step 1: Create a GitHub Repository
1. Go to https://github.com/new
2. Repository name: `ecommerce-symfony` (or your preferred name)
3. Description: "Symfony e-commerce platform with 2FA and enhanced security"
4. Choose: **Private** (recommended for production code)
5. Do NOT initialize with README (we already have files)
6. Click "Create repository"

### Step 2: Initialize Local Repository
```bash
cd /home/salem/ecommerce_web_site_with_sym-master

# Initialize git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Symfony e-commerce with enhanced security"
```

### Step 3: Connect to GitHub
```bash
# Replace YOUR_USERNAME and REPO_NAME with your actual values
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 4: Authenticate
When prompted, use:
- **Username**: Your GitHub username
- **Password**: Use a Personal Access Token (not your GitHub password)

To create a token:
1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Select scopes: `repo` (full control)
4. Copy the token and use it as your password

## Upload to GitLab

### Step 1: Create GitLab Project
1. Go to https://gitlab.com/projects/new
2. Project name: `ecommerce-symfony`
3. Visibility: **Private**
4. Click "Create project"

### Step 2: Initialize and Push
```bash
cd /home/salem/ecommerce_web_site_with_sym-master

git init
git add .
git commit -m "Initial commit: Symfony e-commerce with enhanced security"

# Replace YOUR_USERNAME and PROJECT_NAME
git remote add origin https://gitlab.com/YOUR_USERNAME/PROJECT_NAME.git
git branch -M main
git push -u origin main
```

## Important: Security Before Upload

### ⚠️ CRITICAL: Remove Sensitive Data

Before pushing, ensure no sensitive data is committed:

#### 1. Check `.env` file
```bash
# Make sure .env is ignored
cat .gitignore | grep ".env"
```

#### 2. Remove sensitive files from git tracking (if already tracked)
```bash
git rm --cached .env
git rm --cached k8s/secrets.yaml  # If it contains real passwords
```

#### 3. Create `.env.example` file
```bash
cp .env .env.example
```

Edit `.env.example` and replace all real values with placeholders:
```
DATABASE_URL="mysql://username:password@localhost:3306/db_name?serverVersion=5.7"
MAILER_DSN=smtp://user:pass@smtp.example.com:587
# Add other variables with placeholder values
```

Then commit:
```bash
git add .env.example
git commit -m "Add environment variables template"
```

#### 4. Update K8s Secrets
If `k8s/secrets.yaml` contains real passwords, create a template:
```bash
cp k8s/secrets.yaml k8s/secrets.yaml.example
```

Edit `k8s/secrets.yaml.example` with placeholder values:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secrets
  namespace: ecommerce
type: Opaque
stringData:
  MYSQL_ROOT_PASSWORD: CHANGE_ME_ROOT_PASSWORD
  MYSQL_DATABASE: ecommerce_db
  MYSQL_USER: ecommerce_user
  MYSQL_PASSWORD: CHANGE_ME_USER_PASSWORD
```

Add to `.gitignore`:
```bash
echo "k8s/secrets.yaml" >> .gitignore
```

Commit the template:
```bash
git add k8s/secrets.yaml.example
git add .gitignore
git commit -m "Add secrets template and ignore real secrets"
```

## After First Push

### Regular Git Workflow

#### Check Status
```bash
git status
```

#### Add Changes
```bash
# Add specific files
git add filename.php

# Or add all changes
git add .
```

#### Commit Changes
```bash
git commit -m "Description of your changes"
```

#### Push to Remote
```bash
git push
```

### Branch Management

#### Create a new branch
```bash
git checkout -b feature/new-feature
```

#### Switch branches
```bash
git checkout main
```

#### Merge branch
```bash
git checkout main
git merge feature/new-feature
```

## Common Git Commands

### View History
```bash
git log --oneline
```

### View Changes
```bash
git diff
```

### Undo Changes
```bash
# Discard changes in working directory
git checkout -- filename.php

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
```

### Pull Latest Changes
```bash
git pull origin main
```

## Repository Structure

Your repository will include:
- ✅ Source code (`src/`)
- ✅ Configuration files (`config/`)
- ✅ Kubernetes manifests (`k8s/`)
- ✅ Docker configuration
- ✅ Documentation (README, guides)
- ✅ `.env.example` (template)
- ❌ `.env` (ignored - contains secrets)
- ❌ `vendor/` (ignored - dependencies)
- ❌ `var/` (ignored - cache/logs)
- ❌ Real secrets files

## Collaborating

### Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/REPO_NAME.git
cd REPO_NAME
```

### Setup After Clone
```bash
# Copy environment template
cp .env.example .env

# Edit .env with real values
nano .env

# Install dependencies
composer install

# Run migrations
php bin/console doctrine:migrations:migrate
```

## Best Practices

1. **Commit Often**: Make small, focused commits
2. **Write Clear Messages**: Describe what and why, not how
3. **Use Branches**: Create feature branches for new work
4. **Review Before Commit**: Check `git status` and `git diff`
5. **Keep Secrets Safe**: Never commit passwords or API keys
6. **Update .gitignore**: Add new files that shouldn't be tracked
7. **Pull Before Push**: Always pull latest changes first
8. **Write Documentation**: Keep README.md updated

## Useful .gitignore Patterns

Already configured in your `.gitignore`:
- Environment files (`.env`, `.env.local`)
- Dependencies (`/vendor/`)
- Cache and logs (`/var/`)
- Database files (`*.sql`, `*.sqlite`)
- IDE files (`.idea/`, `.vscode/`)
- Uploaded files (`/public/uploads/`)

## Troubleshooting

### Git is not recognized
```bash
# Check if git is installed
git --version

# Install if missing
sudo yum install git-core
```

### Permission denied (publickey)
Use HTTPS instead of SSH, or set up SSH keys:
https://docs.github.com/en/authentication/connecting-to-github-with-ssh

### Merge Conflicts
```bash
# View conflicted files
git status

# Edit files to resolve conflicts
# Look for <<<<<<< HEAD markers

# Mark as resolved
git add filename.php

# Complete merge
git commit
```

## Resources

- **Git Documentation**: https://git-scm.com/doc
- **GitHub Guides**: https://guides.github.com
- **GitLab Docs**: https://docs.gitlab.com
- **Learn Git Branching**: https://learngitbranching.js.org

---

**Next Steps:**
1. Install Git on your system
2. Follow the steps above to upload your project
3. Share the repository URL with your team (if applicable)
