#!/bin/bash

# ============================================================================
# Project Cleanup Script
# ============================================================================
# This script removes unnecessary files and organizes the project structure
# Usage: ./cleanup-project.sh
# ============================================================================

set -e

PROJECT_ROOT="/home/salem/ecommerce_web_site_with_sym-master"
cd "$PROJECT_ROOT"

echo "🧹 Starting project cleanup..."
echo "================================"

# Create backup directory for removed files
BACKUP_DIR="./cleanup_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# ============================================================================
# 1. Move redundant documentation to docs folder
# ============================================================================
echo ""
echo "📁 Organizing documentation..."
mkdir -p docs/guides
mkdir -p docs/security
mkdir -p docs/deployment
mkdir -p docs/archived

# Move setup guides to docs/guides
mv -f CLIENT_DEVICE_SETUP.md docs/guides/ 2>/dev/null || true
mv -f AUTO_2FA_README.md docs/guides/ 2>/dev/null || true
mv -f BACKUP_README.md docs/guides/ 2>/dev/null || true
mv -f GIT_UPLOAD_GUIDE.md docs/guides/ 2>/dev/null || true

# Move security docs to docs/security
mv -f 2FA_SETUP_GUIDE.md docs/security/ 2>/dev/null || true
mv -f PASSWORD_POLICY.md docs/security/ 2>/dev/null || true
mv -f PASSWORD_POLICY_IMPLEMENTATION.md docs/security/ 2>/dev/null || true
mv -f SECURITY_HARDENING.md docs/security/ 2>/dev/null || true
mv -f SECURITY_HARDENING_COMPLETE.md docs/security/ 2>/dev/null || true
mv -f FIREWALL_QUICK_REFERENCE.md docs/security/ 2>/dev/null || true

# Move deployment docs to docs/deployment
mv -f CLOUDFLARE_TUNNEL_GUIDE.md docs/deployment/ 2>/dev/null || true
mv -f DNS_SSL_GUIDE.md docs/deployment/ 2>/dev/null || true
mv -f EXTERNAL_ACCESS_GUIDE.md docs/deployment/ 2>/dev/null || true
mv -f NETWORK_ACCESS.md docs/deployment/ 2>/dev/null || true
mv -f NGINX_SSL_SETUP_COMPLETE.md docs/deployment/ 2>/dev/null || true
mv -f SSL_CERTIFICATE_SUMMARY.md docs/deployment/ 2>/dev/null || true
mv -f VMWARE_PORT_FORWARDING.md docs/deployment/ 2>/dev/null || true
mv -f README_k8s.md docs/deployment/ 2>/dev/null || true

# Move archived/redundant docs
mv -f QUICK_FIX_EXTERNAL_ACCESS.md docs/archived/ 2>/dev/null || true
mv -f QR_CODE_PERSISTENCE.md docs/archived/ 2>/dev/null || true

# Move architecture and presentation
mv -f ARCHITECTURE_DIAGRAMS.md docs/ 2>/dev/null || true
mv -f PRESENTATION.md docs/ 2>/dev/null || true

echo "✅ Documentation organized into docs/ folder"

# ============================================================================
# 2. Organize scripts into scripts folder
# ============================================================================
echo ""
echo "📜 Organizing scripts..."
mkdir -p scripts/security
mkdir -p scripts/deployment
mkdir -p scripts/backup

# Move security scripts
mv -f harden-firewall.sh scripts/security/ 2>/dev/null || true
mv -f verify-security.sh scripts/security/ 2>/dev/null || true
mv -f additional-hardening.sh scripts/security/ 2>/dev/null || true

# Move deployment scripts
mv -f rebuild-and-deploy.sh scripts/deployment/ 2>/dev/null || true
mv -f setup-dns-ssl.sh scripts/deployment/ 2>/dev/null || true
mv -f setup-local-dns.sh scripts/deployment/ 2>/dev/null || true
mv -f setup-nginx-selfsigned-ssl.sh scripts/deployment/ 2>/dev/null || true
mv -f install-cloudflare-tunnel.sh scripts/deployment/ 2>/dev/null || true
mv -f cloudflare-tunnel-setup-interactive.sh scripts/deployment/ 2>/dev/null || true
mv -f install-git.sh scripts/deployment/ 2>/dev/null || true
mv -f install-letsencrypt.sh scripts/deployment/ 2>/dev/null || true
mv -f update-after-bridge.sh scripts/deployment/ 2>/dev/null || true
mv -f check-external-access.sh scripts/deployment/ 2>/dev/null || true

# Move backup scripts
mv -f backup-restore.sh scripts/backup/ 2>/dev/null || true

echo "✅ Scripts organized into scripts/ folder"

# ============================================================================
# 3. Organize images into assets folder
# ============================================================================
echo ""
echo "🖼️  Organizing images..."
mkdir -p assets/images

mv -f bootique.png assets/images/ 2>/dev/null || true
mv -f bootique2.png assets/images/ 2>/dev/null || true
mv -f bootique3.png assets/images/ 2>/dev/null || true
mv -f backoffice.png assets/images/ 2>/dev/null || true
mv -f backoffice2.png assets/images/ 2>/dev/null || true

echo "✅ Images moved to assets/images/"

# ============================================================================
# 4. Remove temporary and generated files
# ============================================================================
echo ""
echo "🗑️  Removing temporary files..."

# Remove Python cache
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true

# Remove IDE files
rm -rf .idea/ 2>/dev/null || true
rm -rf .vscode/.phpunit.result.cache 2>/dev/null || true

# Move Python presentation script
mv -f create_presentation.py scripts/ 2>/dev/null || true
mv -f presentation_ecommerce.pptx assets/ 2>/dev/null || true

echo "✅ Temporary files removed"

# ============================================================================
# 5. Clean Symfony cache and logs (if exists)
# ============================================================================
echo ""
echo "🧹 Cleaning Symfony cache..."

if [ -d "var/cache" ]; then
    rm -rf var/cache/* 2>/dev/null || true
    echo "✅ Symfony cache cleared"
fi

if [ -d "var/log" ]; then
    # Keep log directory but remove old logs
    find var/log -type f -name "*.log" -mtime +7 -delete 2>/dev/null || true
    echo "✅ Old log files removed (kept last 7 days)"
fi

# ============================================================================
# 6. Update .gitignore
# ============================================================================
echo ""
echo "📝 Updating .gitignore..."

cat > .gitignore << 'EOL'
###> symfony/framework-bundle ###
/.env.local
/.env.local.php
/.env.*.local
/config/secrets/prod/prod.decrypt.private.php
/public/bundles/
/var/
/vendor/
###< symfony/framework-bundle ###

###> phpunit/phpunit ###
/phpunit.xml
.phpunit.result.cache
###< phpunit/phpunit ###

###> symfony/phpunit-bridge ###
.phpunit.result.cache
/phpunit.xml
###< symfony/phpunit-bridge ###

###> IDE and Editor ###
.idea/
.vscode/
*.sublime-project
*.sublime-workspace
.DS_Store
Thumbs.db

###> Node ###
node_modules/
npm-debug.log
yarn-error.log

###> Python ###
__pycache__/
*.pyc
*.pyo
*.egg-info/
.python-version

###> Backup ###
*.bak
*.backup
*.old
cleanup_backup_*/

###> Database ###
*.sql.gz
*.sql.bak

###> SSL Certificates ###
*.pem
*.key
*.crt
!docker/nginx/ssl/.gitkeep

###> Composer ###
composer.phar

###> System ###
.env.production
.env.staging
EOL

echo "✅ .gitignore updated"

# ============================================================================
# 7. Create organized README structure
# ============================================================================
echo ""
echo "📖 Creating README index..."

cat > docs/README.md << 'EOL'
# Documentation Index

## 📚 Main Documentation
- [Project Report](../PROJECT_REPORT.md) - Comprehensive project documentation
- [Main README](../README.md) - Quick start guide
- [Architecture Diagrams](ARCHITECTURE_DIAGRAMS.md) - System architecture
- [Presentation](PRESENTATION.md) - Project presentation

## 🔐 Security Documentation
- [2FA Setup Guide](security/2FA_SETUP_GUIDE.md)
- [Password Policy](security/PASSWORD_POLICY.md)
- [Password Policy Implementation](security/PASSWORD_POLICY_IMPLEMENTATION.md)
- [Security Hardening](security/SECURITY_HARDENING.md)
- [Security Hardening Complete](security/SECURITY_HARDENING_COMPLETE.md)
- [Firewall Quick Reference](security/FIREWALL_QUICK_REFERENCE.md)

## 🚀 Deployment Documentation
- [Kubernetes Deployment](deployment/README_k8s.md)
- [Cloudflare Tunnel Guide](deployment/CLOUDFLARE_TUNNEL_GUIDE.md)
- [DNS & SSL Setup](deployment/DNS_SSL_GUIDE.md)
- [External Access Guide](deployment/EXTERNAL_ACCESS_GUIDE.md)
- [Network Access](deployment/NETWORK_ACCESS.md)
- [Nginx SSL Setup](deployment/NGINX_SSL_SETUP_COMPLETE.md)
- [SSL Certificate Summary](deployment/SSL_CERTIFICATE_SUMMARY.md)
- [VMware Port Forwarding](deployment/VMWARE_PORT_FORWARDING.md)

## 📖 User Guides
- [Client Device Setup](guides/CLIENT_DEVICE_SETUP.md)
- [Auto 2FA Setup](guides/AUTO_2FA_README.md)
- [Backup & Restore](guides/BACKUP_README.md)
- [Git Upload Guide](guides/GIT_UPLOAD_GUIDE.md)

## 📜 Scripts Documentation

### Security Scripts
Located in `scripts/security/`:
- `harden-firewall.sh` - Harden system firewall
- `verify-security.sh` - Verify security configuration
- `additional-hardening.sh` - Additional security measures

### Deployment Scripts
Located in `scripts/deployment/`:
- `rebuild-and-deploy.sh` - Full rebuild and deployment
- `setup-dns-ssl.sh` - DNS and SSL setup
- `setup-local-dns.sh` - Local DNS configuration
- `setup-nginx-selfsigned-ssl.sh` - Self-signed SSL setup
- `install-cloudflare-tunnel.sh` - Cloudflare tunnel installation
- `cloudflare-tunnel-setup-interactive.sh` - Interactive Cloudflare setup
- `install-git.sh` - Git installation
- `install-letsencrypt.sh` - Let's Encrypt installation
- `check-external-access.sh` - Check external connectivity

### Backup Scripts
Located in `scripts/backup/`:
- `backup-restore.sh` - Database backup and restore

## 🗄️ Archived Documentation
- [Quick Fix External Access](archived/QUICK_FIX_EXTERNAL_ACCESS.md)
- [QR Code Persistence](archived/QR_CODE_PERSISTENCE.md)
EOL

echo "✅ Documentation index created"

# ============================================================================
# 8. Make all scripts executable
# ============================================================================
echo ""
echo "🔧 Setting script permissions..."

find scripts/ -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
chmod +x cleanup-project.sh 2>/dev/null || true

echo "✅ Script permissions set"

# ============================================================================
# 9. Create project structure documentation
# ============================================================================
echo ""
echo "📂 Creating project structure documentation..."

cat > PROJECT_STRUCTURE.md << 'EOL'
# Project Structure

```
ecommerce_web_site_with_sym-master/
├── assets/                          # Project assets
│   ├── images/                      # Screenshots and images
│   └── presentation_ecommerce.pptx  # Project presentation
│
├── bin/                             # Symfony binaries
│   ├── console                      # Symfony console
│   └── phpunit                      # PHPUnit runner
│
├── config/                          # Symfony configuration
│   ├── packages/                    # Package configurations
│   ├── routes/                      # Route definitions
│   ├── bundles.php                  # Bundle configuration
│   ├── services.yaml                # Service definitions
│   └── routes.yaml                  # Main routes
│
├── docs/                            # Documentation
│   ├── archived/                    # Archived documentation
│   ├── deployment/                  # Deployment guides
│   ├── guides/                      # User guides
│   ├── security/                    # Security documentation
│   ├── ARCHITECTURE_DIAGRAMS.md     # Architecture diagrams
│   ├── PRESENTATION.md              # Project presentation
│   └── README.md                    # Documentation index
│
├── k8s/                             # Kubernetes manifests
│   ├── app-deployment.yaml          # Application deployment
│   ├── mysql-deployment.yaml        # MySQL deployment
│   ├── phpmyadmin-deployment.yaml   # PHPMyAdmin deployment
│   ├── mysql-pvc.yaml               # Persistent volume claim
│   ├── secrets.yaml                 # Kubernetes secrets
│   ├── namespace.yaml               # Namespace definition
│   └── db-init-job.yaml             # Database initialization
│
├── migrations/                      # Database migrations
│   ├── Version*.php                 # Doctrine migrations
│   └── add_2fa_column.sql           # Manual migration
│
├── monitoring/                      # Monitoring configuration
│   ├── prometheus-deployment.yaml   # Prometheus setup
│   ├── grafana-deployment.yaml      # Grafana setup
│   └── mysql-exporter.yaml          # MySQL metrics exporter
│
├── public/                          # Web root
│   ├── assets/                      # Public assets
│   ├── uploads/                     # User uploads
│   ├── index.php                    # Front controller
│   └── adminer.php                  # Adminer database tool
│
├── scripts/                         # Utility scripts
│   ├── backup/                      # Backup scripts
│   │   └── backup-restore.sh
│   ├── deployment/                  # Deployment scripts
│   │   ├── rebuild-and-deploy.sh
│   │   ├── setup-dns-ssl.sh
│   │   ├── install-cloudflare-tunnel.sh
│   │   └── ...
│   ├── security/                    # Security scripts
│   │   ├── harden-firewall.sh
│   │   ├── verify-security.sh
│   │   └── additional-hardening.sh
│   └── create_presentation.py       # Presentation generator
│
├── src/                             # Application source code
│   ├── Command/                     # Console commands
│   ├── Controller/                  # Controllers
│   │   ├── Admin/                   # Admin controllers
│   │   ├── HomeController.php
│   │   ├── ProductController.php
│   │   ├── CartController.php
│   │   ├── OrderController.php
│   │   ├── PaymentController.php
│   │   └── ...
│   ├── Entity/                      # Doctrine entities
│   │   ├── User.php
│   │   ├── Product.php
│   │   ├── Order.php
│   │   ├── Category.php
│   │   └── ...
│   ├── Form/                        # Form types
│   ├── Repository/                  # Entity repositories
│   ├── Security/                    # Security classes
│   ├── Service/                     # Business services
│   ├── Validator/                   # Custom validators
│   └── Kernel.php                   # Application kernel
│
├── templates/                       # Twig templates
│   ├── base.html.twig               # Base template
│   ├── home/                        # Home templates
│   ├── product/                     # Product templates
│   ├── cart/                        # Cart templates
│   ├── order/                       # Order templates
│   ├── security/                    # Security templates
│   └── ...
│
├── tests/                           # Tests
│   ├── Controller/                  # Controller tests
│   └── ...
│
├── translations/                    # Translation files
│
├── var/                             # Temporary files (not in git)
│   ├── cache/                       # Application cache
│   └── log/                         # Application logs
│
├── .dockerignore                    # Docker ignore file
├── .env                             # Environment variables (template)
├── .env.test                        # Test environment variables
├── .gitignore                       # Git ignore file
├── cleanup-project.sh               # This cleanup script
├── composer.json                    # PHP dependencies
├── composer.lock                    # Locked dependencies
├── docker-compose.yml               # Docker Compose configuration
├── docker-compose-full.yml          # Full Docker Compose with all services
├── Dockerfile                       # Docker image definition
├── e-commerce-symfo.sql             # Database dump
├── ecommerce-rebuild.service        # Systemd service file
├── phpunit.xml.dist                 # PHPUnit configuration
├── PROJECT_REPORT.md                # Comprehensive project report
├── PROJECT_STRUCTURE.md             # This file
├── README.md                        # Main README
└── symfony.lock                     # Symfony Flex lock file
```

## Key Directories

### Source Code (`src/`)
Contains all PHP application code including controllers, entities, services, and business logic.

### Templates (`templates/`)
Twig templates for rendering HTML views.

### Configuration (`config/`)
Symfony configuration files for packages, services, and routes.

### Public (`public/`)
Web server document root. Contains the front controller and publicly accessible assets.

### Documentation (`docs/`)
All project documentation organized by category.

### Scripts (`scripts/`)
Utility scripts for deployment, security, and backup operations.

### Kubernetes (`k8s/`)
Kubernetes manifest files for container orchestration.

### Tests (`tests/`)
PHPUnit tests for the application.

## Important Files

- `composer.json` - PHP dependencies and project metadata
- `Dockerfile` - Docker image build instructions
- `docker-compose.yml` - Local development environment
- `.env` - Environment variables (not committed)
- `PROJECT_REPORT.md` - Comprehensive project documentation
- `README.md` - Quick start guide
EOL

echo "✅ Project structure documentation created"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "================================"
echo "✅ Cleanup Complete!"
echo "================================"
echo ""
echo "📊 Summary:"
echo "  • Documentation organized in docs/ folder"
echo "  • Scripts organized in scripts/ folder"
echo "  • Images moved to assets/images/"
echo "  • Temporary files removed"
echo "  • .gitignore updated"
echo "  • All scripts made executable"
echo ""
echo "📁 New Structure:"
echo "  • docs/security/          - Security documentation"
echo "  • docs/deployment/        - Deployment guides"
echo "  • docs/guides/            - User guides"
echo "  • docs/archived/          - Archived docs"
echo "  • scripts/security/       - Security scripts"
echo "  • scripts/deployment/     - Deployment scripts"
echo "  • scripts/backup/         - Backup scripts"
echo "  • assets/images/          - Project images"
echo ""
echo "📖 Documentation:"
echo "  • docs/README.md          - Documentation index"
echo "  • PROJECT_STRUCTURE.md    - Project structure guide"
echo "  • PROJECT_REPORT.md       - Main project report"
echo ""
echo "🎯 Next Steps:"
echo "  1. Review the organized structure"
echo "  2. Update any hardcoded paths in scripts if needed"
echo "  3. Commit changes to git"
echo "  4. Remove backup folder if everything looks good:"
echo "     rm -rf $BACKUP_DIR"
echo ""
