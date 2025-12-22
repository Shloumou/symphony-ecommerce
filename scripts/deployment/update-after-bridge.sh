#!/bin/bash

# Script pour passer en mode Bridge et mettre à jour DuckDNS
# À exécuter APRÈS avoir configuré VMware en mode Bridge

echo "=== Mise à jour après passage en mode Bridge ==="
echo ""

# Obtenir la nouvelle IP
NEW_IP=$(curl -s ifconfig.me)
echo "Nouvelle IP publique: $NEW_IP"

# Mettre à jour DuckDNS
echo "Mise à jour de DuckDNS..."
RESPONSE=$(curl -s "https://www.duckdns.org/update?domains=salem-ecommerce&token=e9726b9f-3386-4d5e-b15b-9864b2cbf013&ip=$NEW_IP")

if [ "$RESPONSE" == "OK" ]; then
    echo "✅ DuckDNS mis à jour avec succès!"
else
    echo "❌ Erreur lors de la mise à jour DuckDNS: $RESPONSE"
    exit 1
fi

# Attendre la propagation DNS (2-3 minutes)
echo ""
echo "Attente de la propagation DNS (30 secondes)..."
sleep 30

# Vérifier la résolution DNS
echo ""
echo "Vérification DNS..."
nslookup salem-ecommerce.duckdns.org

# Tester l'accès externe
echo ""
echo "Test d'accès depuis l'IP publique..."
timeout 5 bash -c "cat < /dev/null > /dev/tcp/$NEW_IP/443" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Port 443 accessible!"
    echo ""
    echo "🎉 Votre site est maintenant accessible depuis Internet:"
    echo "   https://salem-ecommerce.duckdns.org"
else
    echo "❌ Port 443 toujours bloqué"
    echo "Vérifiez le firewall de votre routeur/box internet"
fi
