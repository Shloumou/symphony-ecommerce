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
