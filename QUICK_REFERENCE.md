# Quick Reference Guide

Quick commands and paths for the cleaned La Boot'ique project.

---

## 📁 Important Paths

### Documentation
```bash
docs/README.md                    # Documentation index
docs/security/                    # Security documentation
docs/deployment/                  # Deployment guides
docs/guides/                      # User guides
PROJECT_REPORT.md                 # Main project report
CONTRIBUTING.md                   # How to contribute
CHANGELOG.md                      # Version history
```

### Scripts
```bash
scripts/security/                 # Security scripts
scripts/deployment/               # Deployment scripts
scripts/backup/                   # Backup scripts
cleanup-project.sh                # Project cleanup tool
```

### Application
```bash
src/                             # Application source code
templates/                       # Twig templates
config/                          # Configuration files
public/                          # Web root
```

---

## 🚀 Quick Commands

### Development

```bash
# Start development server
symfony server:start

# Or use PHP built-in server
php -S localhost:8000 -t public/

# Clear cache
php bin/console cache:clear

# Run migrations
php bin/console doctrine:migrations:migrate

# Create admin user
php bin/console app:create-admin admin@example.com SecurePassword123!

# Enable 2FA for user
php bin/console app:enable-2fa user@example.com
```

### Testing

```bash
# Run all tests
php bin/phpunit

# Run specific test
php bin/phpunit tests/Controller/HomeControllerTest.php

# Run with coverage
php bin/phpunit --coverage-html coverage/
```

### Docker

```bash
# Build and start containers
docker-compose up -d

# View logs
docker-compose logs -f

# Stop containers
docker-compose down

# Rebuild containers
docker-compose up -d --build
```

### Kubernetes

```bash
# Deploy to Kubernetes
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/

# Check status
kubectl -n ecommerce get pods
kubectl -n ecommerce get services

# View logs
kubectl -n ecommerce logs deployment/ecommerce-app

# Access application
minikube -n ecommerce service ecommerce-app-service
```

### Security

```bash
# Harden firewall
./scripts/security/harden-firewall.sh

# Verify security
./scripts/security/verify-security.sh

# Additional hardening
./scripts/security/additional-hardening.sh
```

### Deployment

```bash
# Full rebuild and deploy
./scripts/deployment/rebuild-and-deploy.sh

# Setup DNS and SSL
./scripts/deployment/setup-dns-ssl.sh

# Install Cloudflare Tunnel
./scripts/deployment/install-cloudflare-tunnel.sh

# Setup Nginx SSL
./scripts/deployment/setup-nginx-selfsigned-ssl.sh

# Check external access
./scripts/deployment/check-external-access.sh
```

### Backup

```bash
# Backup database
./scripts/backup/backup-restore.sh backup

# Restore database
./scripts/backup/backup-restore.sh restore

# List backups
ls -lh backups/
```

---

## 📖 Documentation Quick Links

### Getting Started
- [README.md](README.md) - Main documentation
- [docs/deployment/README_k8s.md](docs/deployment/README_k8s.md) - Kubernetes setup

### Security Setup
- [docs/security/2FA_SETUP_GUIDE.md](docs/security/2FA_SETUP_GUIDE.md)
- [docs/security/PASSWORD_POLICY.md](docs/security/PASSWORD_POLICY.md)
- [docs/security/SECURITY_HARDENING.md](docs/security/SECURITY_HARDENING.md)

### Deployment
- [docs/deployment/CLOUDFLARE_TUNNEL_GUIDE.md](docs/deployment/CLOUDFLARE_TUNNEL_GUIDE.md)
- [docs/deployment/DNS_SSL_GUIDE.md](docs/deployment/DNS_SSL_GUIDE.md)
- [docs/deployment/EXTERNAL_ACCESS_GUIDE.md](docs/deployment/EXTERNAL_ACCESS_GUIDE.md)

### Architecture
- [docs/ARCHITECTURE_DIAGRAMS.md](docs/ARCHITECTURE_DIAGRAMS.md)
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)

---

## 🔧 Common Tasks

### Add a New Product (Admin Panel)
1. Login to admin: `https://your-domain/admin`
2. Navigate to Products
3. Click "Add Product"
4. Fill in details and save

### Enable 2FA for Admin
```bash
kubectl -n ecommerce exec deployment/ecommerce-app -- \
  php bin/console app:enable-2fa admin@ecommerce.local
```

### Check Application Logs
```bash
# Docker
docker-compose logs -f app

# Kubernetes
kubectl -n ecommerce logs -f deployment/ecommerce-app

# Local
tail -f var/log/dev.log
```

### Update Dependencies
```bash
# Update Composer dependencies
composer update

# Install new package
composer require vendor/package-name
```

### Database Operations
```bash
# Create database
php bin/console doctrine:database:create

# Run migrations
php bin/console doctrine:migrations:migrate

# Create migration
php bin/console make:migration

# Execute SQL
php bin/console doctrine:query:sql "SELECT * FROM user"
```

---

## 🐛 Troubleshooting

### Clear All Caches
```bash
# Symfony cache
php bin/console cache:clear
rm -rf var/cache/*

# Docker cache
docker-compose down
docker system prune -a

# Kubernetes cache
kubectl delete pods -n ecommerce --all
```

### Fix Permissions
```bash
# Symfony directories
chmod -R 755 var/
chown -R www-data:www-data var/
chmod -R 755 public/uploads/
```

### Reset Database
```bash
# Drop and recreate
php bin/console doctrine:database:drop --force
php bin/console doctrine:database:create
php bin/console doctrine:migrations:migrate
```

### Check Service Status
```bash
# Docker
docker-compose ps

# Kubernetes
kubectl -n ecommerce get all

# System services
systemctl status nginx
systemctl status mysql
```

---

## 🔍 Useful Queries

### Find Files
```bash
# Find controllers
find src/Controller -type f -name "*.php"

# Find templates
find templates -type f -name "*.twig"

# Find entity files
find src/Entity -type f -name "*.php"

# Find all documentation
find docs -type f -name "*.md"
```

### Search in Code
```bash
# Search for class
grep -r "class ProductController" src/

# Search for function
grep -r "function checkout" src/

# Search in templates
grep -r "product.name" templates/
```

### Git Operations
```bash
# Check status
git status

# Commit changes
git add .
git commit -m "feat: add new feature"

# Push changes
git push origin main

# Create branch
git checkout -b feature/new-feature
```

---

## 📊 Monitoring

### Check Application Health
```bash
# HTTP health check
curl http://localhost:8080/

# Database connection
php bin/console doctrine:query:sql "SELECT 1"

# Services status
docker-compose ps
kubectl -n ecommerce get pods
```

### View Metrics (if configured)
```bash
# Prometheus
http://localhost:9090

# Grafana
http://localhost:3000

# PHPMyAdmin
http://localhost:8081
```

---

## 🎯 Production Checklist

```bash
# Before deployment
[ ] Run tests: php bin/phpunit
[ ] Clear cache: php bin/console cache:clear --env=prod
[ ] Check security: ./scripts/security/verify-security.sh
[ ] Backup database: ./scripts/backup/backup-restore.sh backup
[ ] Update dependencies: composer install --no-dev --optimize-autoloader
[ ] Set APP_ENV=prod in .env.local
[ ] Generate optimized autoloader: composer dump-autoload --optimize
[ ] Check file permissions
[ ] Verify SSL certificates
[ ] Test external access
```

---

## 📞 Getting Help

### Documentation
1. Check `README.md` for overview
2. Browse `docs/` for detailed guides
3. Read `CONTRIBUTING.md` for contribution info
4. Check `CHANGELOG.md` for version history

### Troubleshooting
1. Check application logs
2. Verify service status
3. Review recent changes
4. Search documentation
5. Check GitHub issues

### Support Channels
- 📖 Documentation: `docs/README.md`
- 🐛 Issues: GitHub Issues
- 💬 Discussions: GitHub Discussions
- 📧 Contact: Contact form on website

---

## 🎨 Common Customizations

### Change Site Name
Edit: `config/packages/scheb_2fa.yaml`
```yaml
scheb_two_factor:
    totp:
        issuer: 'Your Site Name'
```

### Add New Route
Edit: `config/routes.yaml`
```yaml
new_route:
    path: /your-path
    controller: App\Controller\YourController::yourMethod
```

### Customize Email Templates
Location: `templates/email/`
Edit Twig files to customize appearance

### Add New Admin Section
Location: `src/Controller/Admin/`
Create new EasyAdmin CRUD controller

---

## ⚡ Performance Tips

```bash
# Enable OPcache in production
php.ini: opcache.enable=1

# Use APCu for caching
composer require symfony/cache

# Optimize Composer autoloader
composer dump-autoload --optimize --no-dev

# Use Nginx caching
# Configure in nginx.conf

# Enable HTTP/2
# Configure in nginx.conf

# Minimize assets
php bin/console assets:install --symlink
```

---

**Quick Reference Version:** 2.0.0  
**Last Updated:** December 22, 2025  
**Project:** La Boot'ique E-commerce Platform

---

*For detailed information, see the full documentation in `docs/`*
