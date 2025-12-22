#!/bin/bash

###############################################################################
# Script de configuration DNS + SSL/TLS pour application Symfony
# Configure un nom de domaine et un certificat Let's Encrypt SSL/TLS
###############################################################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  DNS + SSL/TLS Setup for Symfony App  ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Vérifier les privilèges root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Erreur: Ce script doit être exécuté avec sudo${NC}"
    exit 1
fi

# Détecter le système d'exploitation
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Impossible de détecter le système d'exploitation${NC}"
    exit 1
fi

# =====================================================
# ÉTAPE 1 : Configuration du nom de domaine
# =====================================================

echo -e "${YELLOW}[1/5] Configuration du nom de domaine${NC}"
echo ""
echo -e "${BLUE}Vous avez 2 options :${NC}"
echo "  1) Utiliser un nom de domaine réel (ex: votresite.com)"
echo "  2) Utiliser un service DNS dynamique gratuit (ex: DuckDNS, NoIP)"
echo "  3) Utiliser un domaine local pour tests (ex: ecommerce.local)"
echo ""

read -p "Choisissez une option (1/2/3): " DNS_OPTION

case $DNS_OPTION in
    1)
        echo ""
        echo -e "${GREEN}Option 1 : Domaine réel${NC}"
        echo "Vous devez :"
        echo "  - Posséder un nom de domaine (ex: chez OVH, GoDaddy, Namecheap)"
        echo "  - Créer un enregistrement A pointant vers votre IP publique"
        echo ""
        read -p "Entrez votre nom de domaine (ex: ecommerce.example.com): " DOMAIN_NAME
        
        # Obtenir l'IP publique
        PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com)
        echo -e "${BLUE}Votre IP publique : ${PUBLIC_IP}${NC}"
        echo ""
        echo -e "${YELLOW}Action requise :${NC}"
        echo "  1. Allez sur votre registrar de domaine"
        echo "  2. Créez un enregistrement DNS A :"
        echo "     Nom: @ ou ${DOMAIN_NAME}"
        echo "     Type: A"
        echo "     Valeur: ${PUBLIC_IP}"
        echo "     TTL: 300"
        echo ""
        read -p "Avez-vous configuré le DNS ? (y/n): " DNS_CONFIGURED
        
        if [ "$DNS_CONFIGURED" != "y" ]; then
            echo -e "${RED}Veuillez configurer le DNS avant de continuer${NC}"
            exit 1
        fi
        
        USE_LETSENCRYPT=true
        ;;
        
    2)
        echo ""
        echo -e "${GREEN}Option 2 : DNS Dynamique (DuckDNS)${NC}"
        echo "DuckDNS est un service DNS gratuit : https://www.duckdns.org"
        echo ""
        echo "Étapes :"
        echo "  1. Créez un compte sur https://www.duckdns.org"
        echo "  2. Créez un sous-domaine (ex: mon-ecommerce)"
        echo "  3. Notez votre token"
        echo ""
        read -p "Entrez votre sous-domaine DuckDNS (ex: mon-ecommerce): " DUCKDNS_SUBDOMAIN
        read -p "Entrez votre token DuckDNS: " DUCKDNS_TOKEN
        
        DOMAIN_NAME="${DUCKDNS_SUBDOMAIN}.duckdns.org"
        
        # Installer le client DuckDNS
        echo -e "${BLUE}Installation du client DuckDNS...${NC}"
        mkdir -p /etc/duckdns
        cat > /etc/duckdns/duck.sh << EOF
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=" | curl -k -o /etc/duckdns/duck.log -K -
EOF
        chmod +x /etc/duckdns/duck.sh
        
        # Mise à jour initiale
        /etc/duckdns/duck.sh
        
        # Ajouter au cron pour mise à jour automatique
        (crontab -l 2>/dev/null; echo "*/5 * * * * /etc/duckdns/duck.sh >/dev/null 2>&1") | crontab -
        
        echo -e "${GREEN}✓ DuckDNS configuré : ${DOMAIN_NAME}${NC}"
        USE_LETSENCRYPT=true
        ;;
        
    3)
        echo ""
        echo -e "${GREEN}Option 3 : Domaine local${NC}"
        read -p "Entrez le nom de domaine local (ex: ecommerce.local): " DOMAIN_NAME
        
        # Ajouter au /etc/hosts
        if ! grep -q "$DOMAIN_NAME" /etc/hosts; then
            echo "127.0.0.1 $DOMAIN_NAME" >> /etc/hosts
            echo -e "${GREEN}✓ Ajouté à /etc/hosts${NC}"
        fi
        
        USE_LETSENCRYPT=false
        echo -e "${YELLOW}Note: Certificat auto-signé sera utilisé (pas Let's Encrypt)${NC}"
        ;;
        
    *)
        echo -e "${RED}Option invalide${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✓ Domaine configuré : ${DOMAIN_NAME}${NC}"

# =====================================================
# ÉTAPE 2 : Installation de Nginx
# =====================================================

echo ""
echo -e "${YELLOW}[2/5] Installation de Nginx${NC}"

if command -v nginx &> /dev/null; then
    echo -e "${GREEN}✓ Nginx déjà installé${NC}"
else
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt-get update
        apt-get install -y nginx
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "fedora" ]; then
        dnf install -y nginx || yum install -y nginx
    else
        echo -e "${RED}Système non supporté${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Nginx installé${NC}"
fi

# Démarrer Nginx
systemctl enable nginx
systemctl start nginx

# =====================================================
# ÉTAPE 3 : Installation de Certbot (Let's Encrypt)
# =====================================================

if [ "$USE_LETSENCRYPT" = true ]; then
    echo ""
    echo -e "${YELLOW}[3/5] Installation de Certbot (Let's Encrypt)${NC}"
    
    if command -v certbot &> /dev/null; then
        echo -e "${GREEN}✓ Certbot déjà installé${NC}"
    else
        if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
            apt-get install -y certbot python3-certbot-nginx
        elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "fedora" ]; then
            dnf install -y certbot python3-certbot-nginx || yum install -y certbot python3-certbot-nginx
        fi
        echo -e "${GREEN}✓ Certbot installé${NC}"
    fi
else
    echo ""
    echo -e "${YELLOW}[3/5] Génération d'un certificat auto-signé${NC}"
    
    mkdir -p /etc/nginx/ssl
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/${DOMAIN_NAME}.key \
        -out /etc/nginx/ssl/${DOMAIN_NAME}.crt \
        -subj "/C=FR/ST=France/L=Paris/O=Ecommerce/OU=IT/CN=${DOMAIN_NAME}"
    
    echo -e "${GREEN}✓ Certificat auto-signé créé${NC}"
fi

# =====================================================
# ÉTAPE 4 : Configuration Nginx
# =====================================================

echo ""
echo -e "${YELLOW}[4/5] Configuration de Nginx${NC}"

# Détecter le port de l'application
APP_PORT=80
if command -v kubectl &> /dev/null; then
    # Si Kubernetes est utilisé
    K8S_PORT=$(kubectl get svc ecommerce-service -n ecommerce -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
    if [ -n "$K8S_PORT" ]; then
        APP_PORT=$K8S_PORT
        echo -e "${BLUE}Application Kubernetes détectée sur port: ${APP_PORT}${NC}"
    fi
elif docker ps | grep -q symfony-app; then
    # Si Docker est utilisé
    APP_PORT=$(docker port symfony-app | grep "80/tcp" | cut -d':' -f2 || echo "80")
    echo -e "${BLUE}Application Docker détectée sur port: ${APP_PORT}${NC}"
fi

# Backup de la configuration existante
if [ -f /etc/nginx/sites-available/default ]; then
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup.$(date +%Y%m%d_%H%M%S)
fi

# Créer la configuration Nginx
if [ "$USE_LETSENCRYPT" = true ]; then
    # Configuration temporaire pour HTTP (avant Let's Encrypt)
    cat > /etc/nginx/sites-available/${DOMAIN_NAME} << EOF
server {
    listen 80;
    server_name ${DOMAIN_NAME};
    
    location / {
        proxy_pass http://localhost:${APP_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
else
    # Configuration HTTPS avec certificat auto-signé
    cat > /etc/nginx/sites-available/${DOMAIN_NAME} << EOF
server {
    listen 80;
    server_name ${DOMAIN_NAME};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN_NAME};
    
    ssl_certificate /etc/nginx/ssl/${DOMAIN_NAME}.crt;
    ssl_certificate_key /etc/nginx/ssl/${DOMAIN_NAME}.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    location / {
        proxy_pass http://localhost:${APP_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$server_name;
    }
}
EOF
fi

# Activer le site
if [ -d /etc/nginx/sites-enabled ]; then
    ln -sf /etc/nginx/sites-available/${DOMAIN_NAME} /etc/nginx/sites-enabled/
    # Désactiver le site par défaut
    rm -f /etc/nginx/sites-enabled/default
else
    # Pour CentOS/RHEL
    ln -sf /etc/nginx/sites-available/${DOMAIN_NAME} /etc/nginx/conf.d/${DOMAIN_NAME}.conf
fi

# Tester la configuration
nginx -t

# Recharger Nginx
systemctl reload nginx

echo -e "${GREEN}✓ Nginx configuré${NC}"

# =====================================================
# ÉTAPE 5 : Obtention du certificat Let's Encrypt
# =====================================================

if [ "$USE_LETSENCRYPT" = true ]; then
    echo ""
    echo -e "${YELLOW}[5/5] Obtention du certificat Let's Encrypt${NC}"
    
    read -p "Entrez votre email pour Let's Encrypt: " EMAIL
    
    # Obtenir le certificat
    certbot --nginx -d ${DOMAIN_NAME} --non-interactive --agree-tos --email ${EMAIL} --redirect
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Certificat SSL/TLS obtenu avec succès${NC}"
        
        # Configurer le renouvellement automatique
        systemctl enable certbot.timer
        systemctl start certbot.timer
        
        echo -e "${GREEN}✓ Renouvellement automatique configuré${NC}"
    else
        echo -e "${RED}✗ Erreur lors de l'obtention du certificat${NC}"
        echo "Vérifiez que :"
        echo "  - Le domaine ${DOMAIN_NAME} pointe bien vers votre IP"
        echo "  - Le port 80 est accessible depuis Internet"
        echo "  - Votre firewall autorise le trafic HTTP/HTTPS"
    fi
else
    echo ""
    echo -e "${YELLOW}[5/5] Configuration finale${NC}"
    echo -e "${GREEN}✓ Certificat auto-signé déjà configuré${NC}"
fi

# =====================================================
# Configuration du firewall
# =====================================================

echo ""
echo -e "${YELLOW}Configuration du firewall${NC}"

if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    echo -e "${GREEN}✓ Firewall configuré (firewalld)${NC}"
elif command -v ufw &> /dev/null; then
    ufw allow 'Nginx Full'
    echo -e "${GREEN}✓ Firewall configuré (ufw)${NC}"
fi

# =====================================================
# Résumé
# =====================================================

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Configuration terminée avec succès !  ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${GREEN}Votre application est maintenant accessible via :${NC}"
if [ "$USE_LETSENCRYPT" = true ]; then
    echo -e "  ${BLUE}https://${DOMAIN_NAME}${NC}"
else
    echo -e "  ${BLUE}https://${DOMAIN_NAME}${NC} (certificat auto-signé)"
    echo -e "  ${YELLOW}Note: Vous devrez accepter l'avertissement de sécurité dans le navigateur${NC}"
fi
echo ""

echo -e "${YELLOW}Informations utiles :${NC}"
echo "  - Configuration Nginx : /etc/nginx/sites-available/${DOMAIN_NAME}"
echo "  - Logs Nginx : /var/log/nginx/"
if [ "$USE_LETSENCRYPT" = true ]; then
    echo "  - Certificat SSL : /etc/letsencrypt/live/${DOMAIN_NAME}/"
    echo "  - Renouvellement auto : systemctl status certbot.timer"
else
    echo "  - Certificat SSL : /etc/nginx/ssl/${DOMAIN_NAME}.crt"
fi
echo ""

echo -e "${YELLOW}Commandes utiles :${NC}"
echo "  - Tester Nginx : nginx -t"
echo "  - Recharger Nginx : systemctl reload nginx"
echo "  - Voir logs : tail -f /var/log/nginx/access.log"
if [ "$USE_LETSENCRYPT" = true ]; then
    echo "  - Renouveler SSL : certbot renew"
    echo "  - Tester renouvellement : certbot renew --dry-run"
fi
echo ""

echo -e "${GREEN}✓ Setup terminé !${NC}"
