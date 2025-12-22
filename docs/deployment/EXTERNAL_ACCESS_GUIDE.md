# Guide d'accès externe pour salem-ecommerce.duckdns.org

## Problème identifié

✅ DNS configuré : salem-ecommerce.duckdns.org → 197.16.234.153
✅ Certificat Let's Encrypt valide installé
✅ Nginx écoute sur 0.0.0.0:443
✅ Firewall local (firewalld) ouvert pour HTTP/HTTPS
❌ **Port 443 bloqué au niveau du firewall/routeur externe**

## Solution selon votre environnement

### Option 1 : AWS EC2

Si votre VM est sur AWS, ajoutez ces règles au **Security Group** :

```bash
# Obtenir l'ID du Security Group
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
SG_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)

# Ouvrir les ports HTTP et HTTPS
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0
```

**Ou via la console AWS** :
1. EC2 Dashboard → Instances → Sélectionnez votre instance
2. Security → Security Groups → Edit inbound rules
3. Add Rule :
   - Type: HTTP, Port: 80, Source: 0.0.0.0/0
   - Type: HTTPS, Port: 443, Source: 0.0.0.0/0
4. Save rules

### Option 2 : Azure VM

```bash
# Ouvrir le port 443
az vm open-port --resource-group <RESOURCE_GROUP> \
    --name <VM_NAME> \
    --port 443 \
    --priority 1001

# Ouvrir le port 80
az vm open-port --resource-group <RESOURCE_GROUP> \
    --name <VM_NAME> \
    --port 80 \
    --priority 1002
```

### Option 3 : Google Cloud (GCP)

```bash
# Créer une règle de firewall
gcloud compute firewall-rules create allow-https \
    --allow tcp:443 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTPS traffic"

gcloud compute firewall-rules create allow-http \
    --allow tcp:80 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow HTTP traffic"
```

### Option 4 : Routeur local / On-premise

Si votre VM est sur un réseau local avec routeur :

1. Accédez à l'interface de votre routeur (généralement 192.168.1.1)
2. Cherchez "Port Forwarding" ou "NAT"
3. Ajoutez ces règles :
   - Port externe 80 → IP interne 192.168.207.128:80
   - Port externe 443 → IP interne 192.168.207.128:443

### Option 5 : VMware / VirtualBox

Si vous utilisez une VM locale :

**VMware Workstation** :
1. VM Settings → Network Adapter → NAT Settings
2. Port Forwarding : 
   - Host Port 443 → Guest IP 192.168.207.128:443
   - Host Port 80 → Guest IP 192.168.207.128:80

**VirtualBox** :
1. Settings → Network → Advanced → Port Forwarding
2. Ajoutez :
   - Name: HTTPS, Protocol: TCP, Host Port: 443, Guest Port: 443
   - Name: HTTP, Protocol: TCP, Host Port: 80, Guest Port: 80

## Vérification après configuration

Une fois le port forwarding configuré, testez :

```bash
# Depuis votre machine locale (pas la VM)
curl -I https://salem-ecommerce.duckdns.org

# Devrait retourner : HTTP/2 200
```

## Alternative : Cloudflare Tunnel (Si port forwarding impossible)

Si vous ne pouvez pas configurer le port forwarding, utilisez Cloudflare Tunnel :

```bash
# Installer cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# Authentification
cloudflared tunnel login

# Créer un tunnel
cloudflared tunnel create ecommerce-tunnel

# Configurer le tunnel
cat > ~/.cloudflared/config.yml <<EOF
tunnel: ecommerce-tunnel
credentials-file: /home/salem/.cloudflared/<TUNNEL-ID>.json

ingress:
  - hostname: salem-ecommerce.duckdns.org
    service: https://localhost:443
    originServerName: salem-ecommerce.duckdns.org
  - service: http_status:404
EOF

# Démarrer le tunnel
cloudflared tunnel run ecommerce-tunnel
```

## Informations de diagnostic

- **IP publique** : 197.16.234.153
- **IP locale VM** : 192.168.207.128
- **DNS** : salem-ecommerce.duckdns.org → 197.16.234.153
- **Nginx** : Écoute sur 0.0.0.0:443 ✅
- **Firewall local** : HTTP/HTTPS autorisés ✅
- **Certificat** : Let's Encrypt valide jusqu'au 3 mars 2026 ✅

## Support

Si après avoir configuré le port forwarding ça ne fonctionne toujours pas :

1. Vérifiez les logs Nginx : `sudo tail -f /var/log/nginx/error.log`
2. Testez le port : `nc -zv 197.16.234.153 443` (depuis l'extérieur)
3. Vérifiez le pare-feu du fournisseur cloud
4. Contactez votre administrateur réseau si environnement d'entreprise
