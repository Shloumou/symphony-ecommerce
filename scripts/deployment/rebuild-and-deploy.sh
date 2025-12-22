#!/bin/bash

# Script pour reconstruire et déployer l'application avec les dépendances QR code
# À utiliser après chaque redémarrage du cluster ou de la VM

set -e

echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║        Reconstruction et Déploiement de l'Application E-commerce        ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Vérifier que minikube est démarré
echo -e "${BLUE}[1/5] Vérification de Minikube...${NC}"
if ! minikube status &> /dev/null; then
    echo -e "${YELLOW}Minikube n'est pas démarré. Démarrage...${NC}"
    minikube start
else
    echo -e "${GREEN}✅ Minikube est actif${NC}"
fi
echo ""

# 2. Construire l'image Docker
echo -e "${BLUE}[2/5] Construction de l'image Docker...${NC}"
echo "Cela peut prendre plusieurs minutes..."
docker build -t ecommerce_web_site_with_sym:latest . || {
    echo -e "${YELLOW}⚠ Erreur de construction. Tentative de reconstruction...${NC}"
    docker build --no-cache -t ecommerce_web_site_with_sym:latest .
}
echo -e "${GREEN}✅ Image Docker construite${NC}"
echo ""

# 3. Charger l'image dans minikube
echo -e "${BLUE}[3/5] Chargement de l'image dans Minikube...${NC}"
minikube image load ecommerce_web_site_with_sym:latest
echo -e "${GREEN}✅ Image chargée dans Minikube${NC}"
echo ""

# 4. Vérifier que le namespace existe
echo -e "${BLUE}[4/5] Vérification du namespace...${NC}"
if ! kubectl get namespace ecommerce &> /dev/null; then
    echo -e "${YELLOW}Création du namespace ecommerce...${NC}"
    kubectl create namespace ecommerce
fi
echo -e "${GREEN}✅ Namespace prêt${NC}"
echo ""

# 5. Redémarrer le déploiement
echo -e "${BLUE}[5/5] Redémarrage du déploiement...${NC}"
kubectl rollout restart deployment/ecommerce-app -n ecommerce
echo ""

# Attendre que le pod soit prêt
echo -e "${BLUE}Attente du nouveau pod...${NC}"
kubectl wait --for=condition=ready pod -l app=ecommerce-app -n ecommerce --timeout=300s || {
    echo -e "${YELLOW}⚠ Timeout en attendant le pod. Vérification du statut...${NC}"
    kubectl get pods -n ecommerce -l app=ecommerce-app
}
echo ""

# Vérifier que le QR code fonctionne
echo -e "${BLUE}Vérification de la bibliothèque QR code...${NC}"
POD_NAME=$(kubectl get pods -n ecommerce -l app=ecommerce-app -o jsonpath='{.items[0].metadata.name}')
if kubectl exec -n ecommerce $POD_NAME -- php -r "require '/var/www/html/vendor/autoload.php'; echo class_exists('Endroid\QrCode\Builder\Builder') ? '✅' : '❌';" 2>/dev/null | grep -q "✅"; then
    echo -e "${GREEN}✅ QR Code disponible !${NC}"
else
    echo -e "${YELLOW}❌ QR Code non disponible${NC}"
    echo "Vérification des dépendances..."
    kubectl exec -n ecommerce $POD_NAME -- ls -la /var/www/html/vendor/endroid/ 2>&1 | head -5
fi
echo ""

echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                         ✅ DÉPLOIEMENT TERMINÉ !                        ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Votre application est accessible sur :${NC}"
echo "  🌐 https://salem-ecommerce.duckdns.org"
echo "  🌐 https://ecommerce.local"
echo ""
echo -e "${BLUE}Pour tester le QR code 2FA :${NC}"
echo "  1. Connectez-vous sur /connexion"
echo "  2. Allez sur /2fa"
echo "  3. Le QR code devrait s'afficher"
echo ""
