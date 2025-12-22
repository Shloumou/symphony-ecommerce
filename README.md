# La Boot'ique :handbag: :dress: :high_heel:

[![Security Status](https://img.shields.io/badge/security-hardened-green.svg)]()
[![Symfony](https://img.shields.io/badge/Symfony-5.4-blue.svg)]()
[![PHP](https://img.shields.io/badge/PHP-8.2-purple.svg)]()
[![Docker](https://img.shields.io/badge/Docker-ready-blue.svg)]()
[![Kubernetes](https://img.shields.io/badge/Kubernetes-ready-blue.svg)]()

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Technology Stack](#technology-stack)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Project Structure](#project-structure)
- [Security Features](#security-features)
- [Deployment Options](#deployment-options)

---

## Overview

**La Boot'ique** is a production-ready e-commerce platform for fashion products, built with modern web technologies and enterprise-level security features. The platform supports secure payment processing, two-factor authentication, and can be deployed in various environments from local development to Kubernetes clusters.

### Key Highlights
- 🔒 **Enterprise Security**: 2FA, strong password policies, SSL/TLS encryption
- 🚀 **Production Ready**: Docker and Kubernetes support
- 💳 **Payment Integration**: Stripe payment gateway
- 📧 **Email Notifications**: Mailjet integration for transactional emails
- 🎨 **Modern UI**: Bootstrap 5 responsive design
- 🛠️ **Admin Panel**: EasyAdmin for comprehensive back-office management

---

## Features

### 🛍️ Customer Features
- **Product Catalog**: Browse fashion products with detailed descriptions, images, and pricing
- **Search & Filter**: Find products by name, category, or other attributes
- **Shopping Cart**: Add/remove items and manage quantities
- **Secure Checkout**: Complete purchases through Stripe payment gateway
- **User Accounts**: Registration with email verification
- **Two-Factor Authentication**: Enhanced security using TOTP
- **Order History**: Track past orders and their status
- **Contact Form**: Direct communication with administrators

### 👨‍💼 Administrative Features
- **Product Management**: Add, edit, delete products with inventory control
- **Category Management**: Organize products hierarchically
- **Order Management**: View and process customer orders
- **User Management**: Manage customer accounts and permissions
- **Carrier Management**: Configure shipping options and prices
- **Banner Management**: Control homepage promotional content
- **Top Products**: Feature selected products prominently

---

## Screenshots

### Storefront
<table>
  <tr>
    <td><img src="./assets/images/bootique.png" alt="Homepage" width="300"/></td>
    <td><img src="./assets/images/bootique2.png" alt="Product Page" width="300"/></td>
    <td><img src="./assets/images/bootique3.png" alt="Cart" width="300"/></td>
  </tr>
</table>

### Back Office
<table>
  <tr>
    <td><img src="./assets/images/backoffice.png" alt="Admin Dashboard" width="400"/></td>
    <td><img src="./assets/images/backoffice2.png" alt="Product Management" width="400"/></td>
  </tr>
</table>

---

## Technology Stack

### Backend
- **Framework**: Symfony 5.4 LTS
- **Language**: PHP 8.2
- **Database**: MySQL 8.0
- **ORM**: Doctrine 2.11
- **Payment**: Stripe PHP SDK
- **Email**: Mailjet API v3
- **Security**: scheb/2fa-bundle, Custom validators

### Frontend
- **Template Engine**: Twig 3.x
- **CSS Framework**: Bootstrap 5
- **JavaScript**: Vanilla JS

### Infrastructure
- **Containerization**: Docker 24.x
- **Orchestration**: Kubernetes (Minikube)
- **Web Server**: Nginx + Apache
- **Admin Tools**: EasyAdmin 3.5, PHPMyAdmin

### DevOps
- **CI/CD**: Automated scripts
- **Monitoring**: Prometheus + Grafana (optional)
- **Security**: firewalld, fail2ban
- **SSL/TLS**: Let's Encrypt

---

## Quick Start

### Prerequisites
- PHP 8.2 or higher
- Composer 2.x
- MySQL 8.0
- Docker & Docker Compose (optional)
- Kubernetes/Minikube (optional)

### Installation

#### Option 1: Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ecommerce_web_site_with_sym-master

# Install dependencies
composer install

# Configure environment
cp .env .env.local
# Edit .env.local with your database credentials and API keys

# Create database and run migrations
php bin/console doctrine:database:create
php bin/console doctrine:migrations:migrate

# Import initial data (optional)
mysql -u your_user -p your_database < e-commerce-symfo.sql

# Clear cache
php bin/console cache:clear

# Start development server
symfony server:start
# or
php -S localhost:8000 -t public/
```

#### Option 2: Docker Compose

```bash
# Build and start containers
docker-compose up -d

# Access the application at http://localhost:8080
```

#### Option 3: Kubernetes

```bash
# See detailed instructions
cat docs/deployment/README_k8s.md

# Quick deploy
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/
```

### Configuration

Edit `.env.local` with your settings:

```env
# Database
DATABASE_URL="mysql://user:password@127.0.0.1:3306/ecommerce?serverVersion=8.0"

# Stripe API Keys
STRIPE_PUBLIC_KEY=your_stripe_public_key
STRIPE_SECRET_KEY=your_stripe_secret_key

# Mailjet API Keys
MAILJET_API_KEY=your_mailjet_api_key
MAILJET_API_SECRET=your_mailjet_secret

# App Environment
APP_ENV=dev
APP_SECRET=your_random_secret
```

---

## Documentation

All documentation is organized in the `docs/` folder:

### 📚 Main Documentation
- [📄 Comprehensive Project Report](PROJECT_REPORT.md)
- [📁 Project Structure](PROJECT_STRUCTURE.md)
- [🏗️ Architecture Diagrams](docs/ARCHITECTURE_DIAGRAMS.md)
- [📊 Presentation](docs/PRESENTATION.md)

### 🔐 Security
- [Two-Factor Authentication Setup](docs/security/2FA_SETUP_GUIDE.md)
- [Password Policy](docs/security/PASSWORD_POLICY.md)
- [Security Hardening Guide](docs/security/SECURITY_HARDENING.md)
- [Firewall Configuration](docs/security/FIREWALL_QUICK_REFERENCE.md)

### 🚀 Deployment
- [Kubernetes Deployment](docs/deployment/README_k8s.md)
- [Cloudflare Tunnel Setup](docs/deployment/CLOUDFLARE_TUNNEL_GUIDE.md)
- [DNS & SSL Configuration](docs/deployment/DNS_SSL_GUIDE.md)
- [External Access Guide](docs/deployment/EXTERNAL_ACCESS_GUIDE.md)
- [Nginx SSL Setup](docs/deployment/NGINX_SSL_SETUP_COMPLETE.md)

### 📖 User Guides
- [Client Device Setup](docs/guides/CLIENT_DEVICE_SETUP.md)
- [Backup & Restore](docs/guides/BACKUP_README.md)
- [Git Upload Guide](docs/guides/GIT_UPLOAD_GUIDE.md)

**[📖 View Full Documentation Index](docs/README.md)**

---

## Project Structure

```
ecommerce_web_site_with_sym-master/
├── assets/              # Images and presentations
├── bin/                 # Symfony binaries
├── config/              # Configuration files
├── docs/                # 📚 All documentation
│   ├── security/        # Security guides
│   ├── deployment/      # Deployment guides
│   ├── guides/          # User guides
│   └── archived/        # Archived docs
├── k8s/                 # Kubernetes manifests
├── migrations/          # Database migrations
├── monitoring/          # Prometheus/Grafana configs
├── public/              # Web root
├── scripts/             # 🔧 Utility scripts
│   ├── security/        # Security scripts
│   ├── deployment/      # Deployment scripts
│   └── backup/          # Backup scripts
├── src/                 # Application source code
│   ├── Controller/      # Controllers
│   ├── Entity/          # Doctrine entities
│   ├── Form/            # Form types
│   ├── Repository/      # Repositories
│   ├── Security/        # Security classes
│   └── Validator/       # Custom validators
├── templates/           # Twig templates
├── tests/               # PHPUnit tests
└── translations/        # Translation files
```

**[📁 View Detailed Structure](PROJECT_STRUCTURE.md)**

---

## Security Features

### 🔒 Multi-Layer Security

1. **Two-Factor Authentication (2FA)**
   - TOTP-based authentication
   - QR code generation for easy setup
   - Compatible with Google Authenticator, Microsoft Authenticator, Authy

2. **Strong Password Policy**
   - Minimum 12 characters
   - Uppercase, lowercase, numbers, special characters required
   - Bcrypt hashing with cost factor 13
   - OWASP compliant

3. **Network Security**
   - Firewall hardening (only ports 22, 80, 443 exposed)
   - SSL/TLS encryption (Let's Encrypt)
   - HTTPS enforcement with HSTS headers
   - Optional Cloudflare Tunnel (Zero Trust)

4. **Application Security**
   - CSRF protection
   - SQL injection prevention (Doctrine ORM)
   - XSS protection (Twig auto-escaping)
   - Role-based access control (RBAC)

5. **Data Security**
   - Encrypted database credentials (Kubernetes Secrets)
   - Secure session management
   - Regular backups with encryption

**[🔐 View Security Documentation](docs/security/)**

---

## Deployment Options

### 1. Local Development
Simple PHP server or Symfony CLI for quick testing and development.

### 2. Docker Compose
Multi-container setup with application, database, and PHPMyAdmin.
```bash
docker-compose up -d
```

### 3. Kubernetes (Minikube)
Production-like environment with orchestration, scaling, and self-healing.
```bash
kubectl apply -f k8s/
```

### 4. Cloud Production (AWS)
Full production deployment with EC2, RDS, S3, CloudFront, and Route 53.
- CloudFormation templates available
- Automated deployment scripts

### 5. Cloudflare Tunnel
Secure external access without port forwarding.
```bash
./scripts/deployment/install-cloudflare-tunnel.sh
```

**[🚀 View Deployment Guides](docs/deployment/)**

---

## Useful Commands

### Development
```bash
# Clear cache
php bin/console cache:clear

# Run migrations
php bin/console doctrine:migrations:migrate

# Create admin user
php bin/console app:create-admin admin@example.com password

# Enable 2FA for user
php bin/console app:enable-2fa user@example.com
```

### Testing
```bash
# Run tests
php bin/phpunit

# Run specific test
php bin/phpunit tests/Controller/HomeControllerTest.php
```

### Deployment
```bash
# Security hardening
./scripts/security/harden-firewall.sh

# Verify security
./scripts/security/verify-security.sh

# Full rebuild and deploy
./scripts/deployment/rebuild-and-deploy.sh

# Database backup
./scripts/backup/backup-restore.sh backup
```

---

## Contributing

Contributions are welcome! Please follow these guidelines:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## Support

For questions, issues, or support:
- 📧 Contact form on the website
- 📖 Check the [documentation](docs/README.md)
- 🐛 [Open an issue](issues)

---

## Acknowledgments

- **Symfony** - The PHP framework
- **Stripe** - Payment processing
- **Mailjet** - Email service
- **Let's Encrypt** - Free SSL certificates
- **Docker** & **Kubernetes** - Container orchestration
- All open-source contributors

---

**Built with ❤️ using modern web technologies**
