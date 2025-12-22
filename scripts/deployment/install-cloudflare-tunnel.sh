#!/bin/bash

# Installation et configuration de Cloudflare Tunnel
# Alternative si le port forwarding VMware ne fonctionne pas

echo "=== Installation de Cloudflare Tunnel ==="
echo ""

# 1. Télécharger cloudflared
echo "Téléchargement de cloudflared..."
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /tmp/cloudflared
sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

echo "✅ cloudflared installé"
cloudflared --version

# 2. Instructions de configuration
echo ""
echo "=== Configuration Cloudflare Tunnel ==="
echo ""
echo "Étape 1: Authentification"
echo "Exécutez cette commande et suivez les instructions dans votre navigateur:"
echo ""
echo "  cloudflared tunnel login"
echo ""
echo "Étape 2: Créer un tunnel"
echo "  cloudflared tunnel create ecommerce-tunnel"
echo ""
echo "Étape 3: Router le DNS"
echo "  cloudflared tunnel route dns ecommerce-tunnel salem-ecommerce.duckdns.org"
echo ""
echo "Étape 4: Créer le fichier de configuration"
echo ""
cat > /tmp/cloudflared-config.yml <<'EOF'
tunnel: ecommerce-tunnel
credentials-file: /home/salem/.cloudflared/<TUNNEL-ID>.json

ingress:
  - hostname: salem-ecommerce.duckdns.org
    service: https://localhost:443
    originRequest:
      originServerName: salem-ecommerce.duckdns.org
      noTLSVerify: false
  - service: http_status:404
EOF

echo "Copiez cette configuration dans ~/.cloudflared/config.yml"
cat /tmp/cloudflared-config.yml
echo ""

echo "Étape 5: Démarrer le tunnel"
echo "  cloudflared tunnel run ecommerce-tunnel"
echo ""
echo "Étape 6 (Optionnel): Service systemd pour démarrage automatique"
echo "  sudo cloudflared service install"
echo "  sudo systemctl start cloudflared"
echo "  sudo systemctl enable cloudflared"
echo ""

echo "=== Avantages de Cloudflare Tunnel ==="
echo "✅ Pas besoin d'ouvrir de ports sur le firewall"
echo "✅ Protection DDoS gratuite"
echo "✅ CDN global intégré"
echo "✅ Certificat SSL automatique"
echo ""

echo "Pour plus d'informations:"
echo "https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/"
