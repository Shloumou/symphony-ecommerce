#!/bin/bash

# Script de diagnostic pour l'accès externe à salem-ecommerce.duckdns.org
# Créé le 3 décembre 2025

echo "=============================================="
echo "   Diagnostic d'accès externe pour"
echo "   salem-ecommerce.duckdns.org"
echo "=============================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Configuration réseau
echo -e "${BLUE}[1] Configuration réseau${NC}"
echo "----------------------------------------"
LOCAL_IP=$(ip addr show ens160 | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
PUBLIC_IP=$(curl -s ifconfig.me)
GATEWAY=$(ip route show default | awk '{print $3}')

echo -e "IP locale (VM)    : ${GREEN}$LOCAL_IP${NC}"
echo -e "IP publique (NAT) : ${GREEN}$PUBLIC_IP${NC}"
echo -e "Passerelle        : ${GREEN}$GATEWAY${NC}"
echo ""

# 2. DNS
echo -e "${BLUE}[2] Résolution DNS${NC}"
echo "----------------------------------------"
DNS_IP=$(nslookup salem-ecommerce.duckdns.org 2>/dev/null | grep -A1 "answer:" | tail -1 | awk '{print $2}')
if [ "$DNS_IP" == "$PUBLIC_IP" ]; then
    echo -e "salem-ecommerce.duckdns.org → ${GREEN}$DNS_IP ✓${NC}"
else
    echo -e "salem-ecommerce.duckdns.org → ${RED}$DNS_IP ✗${NC}"
    echo -e "${YELLOW}Attention: Le DNS ne pointe pas vers votre IP publique!${NC}"
fi
echo ""

# 3. Nginx
echo -e "${BLUE}[3] État de Nginx${NC}"
echo "----------------------------------------"
if systemctl is-active --quiet nginx; then
    echo -e "Service Nginx     : ${GREEN}Actif ✓${NC}"
else
    echo -e "Service Nginx     : ${RED}Inactif ✗${NC}"
fi

NGINX_80=$(sudo ss -tlnp | grep ":80 " | wc -l)
NGINX_443=$(sudo ss -tlnp | grep ":443 " | wc -l)

if [ "$NGINX_80" -gt 0 ]; then
    echo -e "Port 80 (HTTP)    : ${GREEN}Écoute ✓${NC}"
else
    echo -e "Port 80 (HTTP)    : ${RED}Pas d'écoute ✗${NC}"
fi

if [ "$NGINX_443" -gt 0 ]; then
    echo -e "Port 443 (HTTPS)  : ${GREEN}Écoute ✓${NC}"
else
    echo -e "Port 443 (HTTPS)  : ${RED}Pas d'écoute ✗${NC}"
fi
echo ""

# 4. Firewall local
echo -e "${BLUE}[4] Firewall local (firewalld)${NC}"
echo "----------------------------------------"
if systemctl is-active --quiet firewalld; then
    echo -e "firewalld         : ${GREEN}Actif${NC}"
    
    HTTP_ALLOWED=$(sudo firewall-cmd --list-services | grep -o "http" | wc -l)
    HTTPS_ALLOWED=$(sudo firewall-cmd --list-services | grep -o "https" | wc -l)
    
    if [ "$HTTP_ALLOWED" -gt 0 ]; then
        echo -e "Service HTTP      : ${GREEN}Autorisé ✓${NC}"
    else
        echo -e "Service HTTP      : ${RED}Bloqué ✗${NC}"
    fi
    
    if [ "$HTTPS_ALLOWED" -gt 0 ]; then
        echo -e "Service HTTPS     : ${GREEN}Autorisé ✓${NC}"
    else
        echo -e "Service HTTPS     : ${RED}Bloqué ✗${NC}"
    fi
else
    echo -e "firewalld         : ${YELLOW}Inactif${NC}"
fi
echo ""

# 5. Certificat SSL
echo -e "${BLUE}[5] Certificat SSL/TLS${NC}"
echo "----------------------------------------"
if [ -f "/etc/nginx/ssl/salem-ecommerce.duckdns.org.crt" ]; then
    CERT_SUBJECT=$(openssl x509 -in /etc/nginx/ssl/salem-ecommerce.duckdns.org.crt -noout -subject | sed 's/.*CN = //')
    CERT_ISSUER=$(openssl x509 -in /etc/nginx/ssl/salem-ecommerce.duckdns.org.crt -noout -issuer | grep -o "O = [^,]*" | cut -d'=' -f2 | xargs)
    CERT_EXPIRY=$(openssl x509 -in /etc/nginx/ssl/salem-ecommerce.duckdns.org.crt -noout -enddate | cut -d'=' -f2)
    
    echo -e "Certificat        : ${GREEN}Installé ✓${NC}"
    echo "Domaine           : $CERT_SUBJECT"
    echo "Émetteur          : $CERT_ISSUER"
    echo "Expire le         : $CERT_EXPIRY"
else
    echo -e "Certificat        : ${RED}Non trouvé ✗${NC}"
fi
echo ""

# 6. Test de connectivité locale
echo -e "${BLUE}[6] Test d'accès local${NC}"
echo "----------------------------------------"
HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" -k https://localhost:443 --connect-timeout 3)
if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "301" ] || [ "$HTTP_CODE" == "302" ]; then
    echo -e "HTTPS localhost   : ${GREEN}$HTTP_CODE ✓${NC}"
else
    echo -e "HTTPS localhost   : ${RED}$HTTP_CODE ✗${NC}"
fi

HTTP_CODE_DOMAIN=$(curl -o /dev/null -s -w "%{http_code}" -k https://salem-ecommerce.duckdns.org --connect-timeout 3)
if [ "$HTTP_CODE_DOMAIN" == "200" ] || [ "$HTTP_CODE_DOMAIN" == "301" ] || [ "$HTTP_CODE_DOMAIN" == "302" ]; then
    echo -e "HTTPS domaine     : ${GREEN}$HTTP_CODE_DOMAIN ✓${NC}"
else
    echo -e "HTTPS domaine     : ${RED}$HTTP_CODE_DOMAIN ✗${NC}"
fi
echo ""

# 7. Test de connectivité externe (simulation)
echo -e "${BLUE}[7] Test d'accès externe${NC}"
echo "----------------------------------------"
echo "Test depuis l'IP publique $PUBLIC_IP..."

# Test port 80
timeout 5 bash -c "cat < /dev/null > /dev/tcp/$PUBLIC_IP/80" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "Port 80           : ${GREEN}Accessible ✓${NC}"
else
    echo -e "Port 80           : ${RED}Non accessible ✗${NC}"
fi

# Test port 443
timeout 5 bash -c "cat < /dev/null > /dev/tcp/$PUBLIC_IP/443" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "Port 443          : ${GREEN}Accessible ✓${NC}"
else
    echo -e "Port 443          : ${RED}Non accessible ✗${NC}"
    echo -e "${YELLOW}⚠ Le port 443 est bloqué au niveau du firewall externe!${NC}"
fi
echo ""

# 8. Plateforme
echo -e "${BLUE}[8] Environnement${NC}"
echo "----------------------------------------"
PLATFORM=$(sudo dmidecode -s system-product-name 2>/dev/null || echo "Inconnu")
echo "Plateforme        : $PLATFORM"

if [[ "$PLATFORM" == *"VMware"* ]]; then
    echo -e "${YELLOW}"
    echo "Vous êtes sur VMware. Pour l'accès externe:"
    echo "1. Configurez le Port Forwarding dans VMware NAT Settings"
    echo "2. Ou passez la VM en mode Bridge"
    echo "Consultez: VMWARE_PORT_FORWARDING.md"
    echo -e "${NC}"
fi
echo ""

# 9. Résumé et recommandations
echo "=============================================="
echo -e "${BLUE}RÉSUMÉ${NC}"
echo "=============================================="
echo ""

# Vérifier si tout est OK localement
LOCAL_OK=true
if [ "$NGINX_80" -eq 0 ] || [ "$NGINX_443" -eq 0 ]; then LOCAL_OK=false; fi
if [ "$HTTP_ALLOWED" -eq 0 ] || [ "$HTTPS_ALLOWED" -eq 0 ]; then LOCAL_OK=false; fi
if [ "$HTTP_CODE_DOMAIN" != "200" ] && [ "$HTTP_CODE_DOMAIN" != "301" ]; then LOCAL_OK=false; fi

# Test externe
timeout 5 bash -c "cat < /dev/null > /dev/tcp/$PUBLIC_IP/443" 2>/dev/null
EXTERNAL_OK=$?

if [ "$LOCAL_OK" = true ]; then
    echo -e "${GREEN}✓ Configuration locale : OK${NC}"
else
    echo -e "${RED}✗ Configuration locale : PROBLÈME${NC}"
fi

if [ $EXTERNAL_OK -eq 0 ]; then
    echo -e "${GREEN}✓ Accès externe : OK${NC}"
    echo ""
    echo -e "${GREEN}🎉 Votre site est accessible depuis Internet!${NC}"
    echo -e "URL: ${GREEN}https://salem-ecommerce.duckdns.org${NC}"
else
    echo -e "${RED}✗ Accès externe : BLOQUÉ${NC}"
    echo ""
    echo -e "${YELLOW}📋 Actions à effectuer:${NC}"
    echo ""
    echo "1. Ouvrir les ports 80 et 443 sur votre firewall/routeur externe"
    echo "2. Pour VMware, configurez le Port Forwarding:"
    echo "   - Voir: VMWARE_PORT_FORWARDING.md"
    echo ""
    echo "3. Ou utilisez le mode Bridge dans VMware"
    echo ""
    echo "4. Alternative: Utilisez Cloudflare Tunnel (pas besoin de port forwarding)"
    echo "   - Voir: EXTERNAL_ACCESS_GUIDE.md"
fi

echo ""
echo "=============================================="
echo "Pour plus d'aide, consultez:"
echo "  - VMWARE_PORT_FORWARDING.md"
echo "  - EXTERNAL_ACCESS_GUIDE.md"
echo "=============================================="
