#!/bin/bash

# Configuration alternative de Cloudflare Tunnel via API
# Pour contourner les problèmes de login via navigateur

echo "=============================================="
echo "   Configuration Cloudflare Tunnel (API)"
echo "=============================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Cette méthode alternative utilise l'API Cloudflare${NC}"
echo ""

# Vérifier si cloudflared est installé
if ! command -v cloudflared &> /dev/null; then
    echo -e "${RED}cloudflared n'est pas installé${NC}"
    echo "Exécutez d'abord: ./install-cloudflare-tunnel.sh"
    exit 1
fi

echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  INSTRUCTIONS POUR CLOUDFLARE TUNNEL                   ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}Option 1: Utiliser Cloudflare Tunnel avec login manuel${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Sur votre machine LOCALE (pas la VM), ouvrez un navigateur et allez à:"
echo -e "   ${BLUE}https://dash.cloudflare.com/sign-up${NC}"
echo ""
echo "2. Créez un compte gratuit (ou connectez-vous si vous en avez un)"
echo ""
echo "3. Une fois connecté, allez dans:"
echo -e "   ${BLUE}https://one.dash.cloudflare.com/${NC}"
echo ""
echo "4. Dans le menu, allez à: Networks → Tunnels"
echo ""
echo "5. Cliquez sur 'Create a tunnel'"
echo ""
echo "6. Choisissez 'Cloudflared' comme type de tunnel"
echo ""
echo "7. Donnez un nom au tunnel: ${GREEN}ecommerce-tunnel${NC}"
echo ""
echo "8. Après création, Cloudflare vous donnera une COMMANDE d'installation"
echo "   Elle ressemble à:"
echo -e "   ${YELLOW}sudo cloudflared service install <TOKEN>${NC}"
echo ""
echo "9. Copiez cette commande et revenez à la VM"
echo ""
echo "10. Collez et exécutez la commande ici"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${GREEN}Option 2: Configuration manuelle avec API Token${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Si vous préférez la méthode API:"
echo ""
echo "1. Allez sur: https://dash.cloudflare.com/profile/api-tokens"
echo ""
echo "2. Créez un API Token avec les permissions:"
echo "   - Zone.DNS (Edit)"
echo "   - Account.Cloudflare Tunnel (Edit)"
echo ""
echo "3. Copiez le token et exécutez:"
echo ""
echo "   export CF_API_TOKEN='votre-token-ici'"
echo "   ./cloudflare-tunnel-manual-setup.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}Quelle option préférez-vous ?${NC}"
echo ""
echo "Option 1: Interface Web Cloudflare (plus simple) ⭐"
echo "Option 2: API Token (plus technique)"
echo ""
echo -e "${BLUE}Recommandation: Utilisez l'Option 1${NC}"
echo ""

# Attendre que l'utilisateur ait le token
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}Une fois que vous avez le token de Cloudflare:${NC}"
echo ""
read -p "Collez la commande d'installation ici (ou appuyez sur Entrée pour passer): " INSTALL_CMD

if [ ! -z "$INSTALL_CMD" ]; then
    echo ""
    echo -e "${BLUE}Exécution de la commande...${NC}"
    eval "$INSTALL_CMD"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Installation réussie!${NC}"
        echo ""
        echo "Le tunnel devrait démarrer automatiquement."
        echo ""
        echo "Vérifiez le statut avec:"
        echo "  sudo systemctl status cloudflared"
    else
        echo ""
        echo -e "${RED}❌ Erreur lors de l'installation${NC}"
        exit 1
    fi
else
    echo ""
    echo -e "${YELLOW}Configuration manuelle nécessaire.${NC}"
    echo ""
    echo "Suivez les étapes ci-dessus et revenez ici une fois prêt."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Après installation, configurez le routing:${NC}"
echo ""
echo "1. Dans l'interface Cloudflare (onglet Public Hostname):"
echo ""
echo "   Subdomain: salem-ecommerce"
echo "   Domain: duckdns.org"
echo "   Path: (laissez vide)"
echo "   Type: HTTPS"
echo "   URL: localhost:443"
echo ""
echo "2. Cliquez 'Save tunnel'"
echo ""
echo "3. Testez l'accès:"
echo "   curl -I https://salem-ecommerce.duckdns.org"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
