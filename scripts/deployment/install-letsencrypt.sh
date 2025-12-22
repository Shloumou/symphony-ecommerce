#!/bin/bash

###############################################################################
# Configuration Let's Encrypt avec DuckDNS + Nginx
# Utilise acme.sh pour obtenir un certificat SSL/TLS gratuit
###############################################################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Let's Encrypt SSL/TLS Setup${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Vérifier si on est root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Ce script doit être exécuté avec sudo${NC}"
    exit 1
fi

# Variables
ACME_HOME="/home/salem/.acme.sh"
NGINX_SSL_DIR="/etc/nginx/ssl"
PUBLIC_IP=$(curl -s ifconfig.me)

echo -e "${BLUE}Votre IP publique : ${PUBLIC_IP}${NC}"
echo ""

# =====================================================
# ÉTAPE 1 : Configuration DuckDNS
# =====================================================

echo -e "${YELLOW}[1/6] Configuration DuckDNS${NC}"
echo ""
echo "Allez sur https://www.duckdns.org et créez un compte"
echo "Créez un sous-domaine et notez votre token"
echo ""

read -p "Entrez votre sous-domaine DuckDNS (ex: mon-ecommerce): " DUCKDNS_SUBDOMAIN
read -p "Entrez votre token DuckDNS: " DUCKDNS_TOKEN

DOMAIN="${DUCKDNS_SUBDOMAIN}.duckdns.org"

echo ""
echo -e "${BLUE}Configuration : ${DOMAIN}${NC}"
echo ""

# Créer le script de mise à jour DuckDNS
mkdir -p /etc/duckdns
cat > /etc/duckdns/duck.sh << EOF
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=" | curl -k -o /etc/duckdns/duck.log -K -
EOF

chmod +x /etc/duckdns/duck.sh

# Mise à jour initiale
echo -e "${YELLOW}Mise à jour DNS...${NC}"
/etc/duckdns/duck.sh
sleep 2

if grep -q "OK" /etc/duckdns/duck.log; then
    echo -e "${GREEN}✓ DNS mis à jour avec succès${NC}"
else
    echo -e "${RED}✗ Erreur lors de la mise à jour DNS${NC}"
    cat /etc/duckdns/duck.log
    exit 1
fi

# Ajouter au cron
(crontab -l 2>/dev/null | grep -v duck.sh; echo "*/5 * * * * /etc/duckdns/duck.sh >/dev/null 2>&1") | crontab -

echo -e "${GREEN}✓ DuckDNS configuré${NC}"

# =====================================================
# ÉTAPE 2 : Détecter le port de l'application
# =====================================================

echo ""
echo -e "${YELLOW}[2/6] Détection du port de l'application${NC}"

APP_PORT=31224
K8S_PORT=$(kubectl get svc ecommerce-service -n ecommerce -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
if [ -n "$K8S_PORT" ]; then
    APP_PORT=$K8S_PORT
    echo -e "${GREEN}✓ Application Kubernetes détectée sur port: ${APP_PORT}${NC}"
else
    echo -e "${YELLOW}⚠ Port par défaut: ${APP_PORT}${NC}"
fi

# =====================================================
# ÉTAPE 3 : Configuration Nginx temporaire (HTTP)
# =====================================================

echo ""
echo -e "${YELLOW}[3/6] Configuration Nginx temporaire${NC}"

# Backup
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
fi

# Créer la configuration
cat > /etc/nginx/conf.d/${DOMAIN}.conf << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        proxy_pass http://localhost:${APP_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Créer le dossier pour acme challenge
mkdir -p /var/www/html/.well-known/acme-challenge
chown -R nginx:nginx /var/www/html

# Tester et recharger
nginx -t
systemctl reload nginx

echo -e "${GREEN}✓ Nginx configuré pour HTTP${NC}"

# =====================================================
# ÉTAPE 4 : Vérification DNS
# =====================================================

echo ""
echo -e "${YELLOW}[4/6] Vérification de la propagation DNS${NC}"
echo "Attente de 10 secondes pour la propagation DNS..."
sleep 10

DNS_IP=$(nslookup ${DOMAIN} 8.8.8.8 | grep "Address:" | tail -1 | awk '{print $2}')
echo -e "${BLUE}DNS résolu: ${DNS_IP}${NC}"
echo -e "${BLUE}IP réelle: ${PUBLIC_IP}${NC}"

if [ "$DNS_IP" = "$PUBLIC_IP" ]; then
    echo -e "${GREEN}✓ DNS correctement configuré${NC}"
else
    echo -e "${YELLOW}⚠ Le DNS ne pointe pas encore vers votre IP${NC}"
    echo "Cela peut prendre quelques minutes. Continuons quand même..."
fi

# =====================================================
# ÉTAPE 5 : Obtention du certificat Let's Encrypt
# =====================================================

echo ""
echo -e "${YELLOW}[5/6] Obtention du certificat Let's Encrypt${NC}"

# Devenir l'utilisateur salem pour exécuter acme.sh
su - salem -c "export ACME_HOME=${ACME_HOME} && ${ACME_HOME}/acme.sh --issue -d ${DOMAIN} -w /var/www/html --log"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Certificat obtenu avec succès${NC}"
else
    echo -e "${RED}✗ Erreur lors de l'obtention du certificat${NC}"
    echo "Vérifiez que :"
    echo "  - Le DNS pointe bien vers ${PUBLIC_IP}"
    echo "  - Le port 80 est accessible depuis Internet"
    echo "  - Le firewall autorise le trafic HTTP"
    exit 1
fi

# =====================================================
# ÉTAPE 6 : Installation du certificat dans Nginx
# =====================================================

echo ""
echo -e "${YELLOW}[6/6] Installation du certificat dans Nginx${NC}"

# Créer le dossier SSL
mkdir -p ${NGINX_SSL_DIR}

# Installer le certificat
su - salem -c "export ACME_HOME=${ACME_HOME} && ${ACME_HOME}/acme.sh --install-cert -d ${DOMAIN} \
    --key-file ${NGINX_SSL_DIR}/${DOMAIN}.key \
    --fullchain-file ${NGINX_SSL_DIR}/${DOMAIN}.crt \
    --reloadcmd 'sudo systemctl reload nginx'"

# Donner les permissions
chmod 644 ${NGINX_SSL_DIR}/${DOMAIN}.crt
chmod 600 ${NGINX_SSL_DIR}/${DOMAIN}.key
chown root:root ${NGINX_SSL_DIR}/${DOMAIN}.*

# Mettre à jour la configuration Nginx pour HTTPS
cat > /etc/nginx/conf.d/${DOMAIN}.conf << EOF
# Redirection HTTP vers HTTPS
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

# Configuration HTTPS
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    
    # Certificat SSL
    ssl_certificate ${NGINX_SSL_DIR}/${DOMAIN}.crt;
    ssl_certificate_key ${NGINX_SSL_DIR}/${DOMAIN}.key;
    
    # Paramètres SSL sécurisés
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Headers de sécurité
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Proxy vers l'application
    location / {
        proxy_pass http://localhost:${APP_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$server_name;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

# Tester et recharger Nginx
nginx -t
systemctl reload nginx

echo -e "${GREEN}✓ Certificat installé et Nginx configuré${NC}"

# =====================================================
# Configuration du firewall
# =====================================================

echo ""
echo -e "${YELLOW}Configuration du firewall${NC}"

if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    echo -e "${GREEN}✓ Firewall configuré${NC}"
fi

# =====================================================
# Résumé
# =====================================================

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Configuration terminée avec succès !${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${GREEN}Votre application est accessible via :${NC}"
echo -e "  ${BLUE}https://${DOMAIN}${NC}"
echo ""
echo -e "${YELLOW}Informations :${NC}"
echo "  - Certificat : ${NGINX_SSL_DIR}/${DOMAIN}.crt"
echo "  - Clé privée : ${NGINX_SSL_DIR}/${DOMAIN}.key"
echo "  - Configuration Nginx : /etc/nginx/conf.d/${DOMAIN}.conf"
echo "  - Renouvellement auto : Configuré dans acme.sh"
echo ""
echo -e "${YELLOW}Commandes utiles :${NC}"
echo "  - Tester SSL : curl -I https://${DOMAIN}"
echo "  - Voir certificat : openssl x509 -in ${NGINX_SSL_DIR}/${DOMAIN}.crt -text -noout"
echo "  - Renouveler : sudo su - salem -c '~/.acme.sh/acme.sh --renew -d ${DOMAIN}'"
echo "  - Logs Nginx : tail -f /var/log/nginx/access.log"
echo ""
echo -e "${GREEN}✓ Certificat Let's Encrypt installé avec succès !${NC}"
