# Configuration Port Forwarding VMware

## Votre configuration actuelle

- **VM IP locale** : 192.168.207.128
- **IP publique (NAT)** : 197.16.234.153
- **Plateforme** : VMware Virtual Platform
- **DNS** : salem-ecommerce.duckdns.org → 197.16.234.153

## Solution 1 : VMware Workstation/Player avec NAT

### Étape 1 : Accéder aux paramètres réseau

1. Éteignez la VM (ou mettez en suspend)
2. Clic droit sur la VM → **Settings** (Paramètres)
3. Sélectionnez **Network Adapter**
4. Vérifiez que **NAT** est sélectionné
5. Cliquez sur **NAT Settings...** (ou Virtual Network Editor)

### Étape 2 : Configurer le Port Forwarding

Dans Virtual Network Editor :

1. Sélectionnez **VMnet8 (NAT)**
2. Cliquez sur **NAT Settings**
3. Cliquez sur **Add...** pour ajouter une nouvelle règle

**Règle 1 - HTTPS** :
```
Host Port: 443
Type: TCP
Virtual Machine IP Address: 192.168.207.128
Virtual Machine Port: 443
Description: HTTPS for ecommerce
```

**Règle 2 - HTTP** :
```
Host Port: 80
Type: TCP
Virtual Machine IP Address: 192.168.207.128
Virtual Machine Port: 80
Description: HTTP for ecommerce
```

4. Cliquez sur **OK** pour sauvegarder
5. Redémarrez la VM

### Étape 3 : Tester l'accès

Depuis une machine externe (ou votre machine hôte) :

```bash
# Test HTTP
curl -I http://197.16.234.153

# Test HTTPS
curl -I https://salem-ecommerce.duckdns.org
```

## Solution 2 : VMware avec mode Bridge (Recommandé pour accès externe)

Si le port forwarding ne fonctionne pas, utilisez le mode **Bridge** :

### Configuration Bridge

1. Arrêtez la VM
2. VM Settings → Network Adapter
3. Sélectionnez **Bridged** (au lieu de NAT)
4. Cochez **Replicate physical network connection state**
5. Démarrez la VM

La VM obtiendra alors une IP directe sur votre réseau :

```bash
# Vérifier la nouvelle IP
ip addr show ens160 | grep "inet "
```

### Mettre à jour DuckDNS avec la nouvelle IP

```bash
# Obtenir la nouvelle IP publique
NEW_IP=$(curl -s ifconfig.me)
echo "Nouvelle IP : $NEW_IP"

# Mettre à jour DuckDNS
curl "https://www.duckdns.org/update?domains=salem-ecommerce&token=e9726b9f-3386-4d5e-b15b-9864b2cbf013&ip=$NEW_IP"

# Vérifier
nslookup salem-ecommerce.duckdns.org
```

## Solution 3 : VMware ESXi (Environnement professionnel)

Si vous êtes sur ESXi :

1. Accédez au **vSphere Client** ou **ESXi Web UI**
2. Sélectionnez votre VM
3. Edit Settings → Network Adapter
4. Changez de **VM Network** vers un réseau avec accès externe
5. Ou configurez le port forwarding sur le firewall ESXi :

```bash
# SSH vers ESXi
ssh root@<ESXI_HOST>

# Ajouter des règles de firewall
esxcli network firewall ruleset set --ruleset-id=webAccess --enabled=true

# Redémarrer le firewall
esxcli network firewall refresh
```

## Solution 4 : Tunnel SSH (Accès temporaire)

Si vous ne pouvez pas modifier la configuration VMware, utilisez un tunnel SSH :

```bash
# Depuis votre machine locale
ssh -L 443:localhost:443 -L 80:localhost:80 salem@197.16.234.153

# Puis ajoutez dans /etc/hosts de votre machine locale
127.0.0.1 salem-ecommerce.duckdns.org
```

Accédez ensuite à https://salem-ecommerce.duckdns.org depuis votre navigateur local.

## Vérification de la configuration VMware actuelle

Depuis la VM, vérifiez le type de réseau :

```bash
# Voir l'interface réseau
ip addr show ens160

# Vérifier la route par défaut
ip route show default

# Tester la connectivité sortante
ping -c 3 8.8.8.8
```

## Troubleshooting

### Si le port forwarding ne fonctionne pas :

1. **Vérifier le firewall Windows/Linux de l'hôte** :
   ```bash
   # Windows (PowerShell Admin)
   New-NetFirewallRule -DisplayName "VMware HTTPS" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow
   
   # Linux hôte
   sudo ufw allow 443/tcp
   ```

2. **Redémarrer les services VMware** :
   - Windows : Services → VMware NAT Service → Restart
   - Linux : `sudo systemctl restart vmware-networks`

3. **Vérifier le fichier de configuration NAT** :
   - Windows : `C:\ProgramData\VMware\vmnetnat.conf`
   - Linux : `/etc/vmware/vmnet8/nat/nat.conf`

Ajoutez manuellement :
```ini
[incomingtcp]
443 = 192.168.207.128:443
80 = 192.168.207.128:80
```

Puis redémarrez VMware NAT Service.

## Recommandation finale

Pour un accès externe simple et fiable :

1. ✅ **Utilisez le mode Bridge** (le plus simple)
2. ✅ Ou configurez le port forwarding dans VMware NAT Settings
3. ✅ Ou utilisez Cloudflare Tunnel (pas besoin de port forwarding)

Après configuration, votre site sera accessible depuis n'importe où via :
**https://salem-ecommerce.duckdns.org** 🔒
