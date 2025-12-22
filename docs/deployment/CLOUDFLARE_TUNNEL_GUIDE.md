# 🚀 Guide Cloudflare Tunnel - Étape par Étape

## 🎯 Objectif
Exposer `https://salem-ecommerce.duckdns.org` sur Internet **sans ouvrir de ports** sur votre firewall.

---

## 📋 Prérequis

✅ `cloudflared` est déjà installé sur votre VM
✅ Nginx fonctionne sur `localhost:443`
✅ Certificat SSL configuré

---

## 🔧 Configuration (5 étapes simples)

### Étape 1️⃣ : Créer un compte Cloudflare (gratuit)

1. Ouvrez votre navigateur (sur votre machine locale, pas la VM)
2. Allez sur : **https://dash.cloudflare.com/sign-up**
3. Créez un compte gratuit (email + mot de passe)
4. Vérifiez votre email

---

### Étape 2️⃣ : Accéder à Cloudflare Zero Trust

1. Une fois connecté, allez sur : **https://one.dash.cloudflare.com/**
2. Si c'est votre première fois, cliquez sur "Get started" pour Zero Trust
3. Choisissez un nom pour votre équipe (ex: `salem-team`)
4. Sélectionnez le plan **Free** (0€/mois)

---

### Étape 3️⃣ : Créer un tunnel

1. Dans le menu de gauche : **Networks** → **Tunnels**
2. Cliquez sur le bouton **"Create a tunnel"**
3. Sélectionnez **"Cloudflared"**
4. Donnez un nom au tunnel : `ecommerce-tunnel`
5. Cliquez **"Save tunnel"**

---

### Étape 4️⃣ : Installer le connecteur

Après avoir créé le tunnel, Cloudflare affiche une commande qui ressemble à :

```bash
sudo cloudflared service install eyJhIjoiNzg5YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY3ODkwIiwidCI6ImFiY2RlZi0xMjM0LTU2NzgtOTBhYi1jZGVmMTIzNDU2NzgiLCJzIjoiWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYIn0=
```

**🎯 ACTIONS À FAIRE :**

1. **Copiez** cette commande complète depuis Cloudflare
2. **Revenez à la VM** (connexion SSH)
3. **Collez et exécutez** la commande dans le terminal

La commande va :
- ✅ Installer le tunnel comme service systemd
- ✅ Le démarrer automatiquement
- ✅ Le configurer pour démarrer au boot

---

### Étape 5️⃣ : Configurer le routing (Public Hostname)

De retour dans l'interface Cloudflare :

1. Vous êtes maintenant sur l'onglet **"Public Hostname"**
2. Cliquez **"Add a public hostname"**

Remplissez les champs :

```
┌─────────────────────────────────────────┐
│ Subdomain: salem-ecommerce              │
│ Domain: duckdns.org                     │  
│ Path: (laissez vide)                    │
├─────────────────────────────────────────┤
│ Type: HTTPS ⚠️                          │
│ URL: localhost:443                      │
├─────────────────────────────────────────┤
│ Additional settings:                    │
│ ☑ No TLS Verify                         │
└─────────────────────────────────────────┘
```

**Important** : 
- Type doit être **HTTPS** (pas HTTP)
- URL doit être **localhost:443** (pas 192.168...)
- Cochez **"No TLS Verify"** car on utilise Let's Encrypt

3. Cliquez **"Save hostname"**

---

## ✅ Vérification

### Sur la VM :

```bash
# Vérifier que le service tourne
sudo systemctl status cloudflared

# Voir les logs
sudo journalctl -u cloudflared -f

# Tester localement
curl -I https://salem-ecommerce.duckdns.org
```

### Depuis l'extérieur :

Depuis votre téléphone (en 4G) ou une autre machine :

```
https://salem-ecommerce.duckdns.org
```

Vous devriez voir votre site avec **🔒 connexion sécurisée** (certificat Cloudflare)

---

## 🔍 Troubleshooting

### Problème : "tunnel not found"

```bash
# Redémarrer le service
sudo systemctl restart cloudflared

# Vérifier les logs
sudo journalctl -u cloudflared -n 50
```

### Problème : "502 Bad Gateway"

Vérifiez que Nginx écoute bien sur localhost:443 :

```bash
sudo ss -tlnp | grep :443
curl -Ik https://localhost:443
```

### Problème : "Connection refused"

Vérifiez la configuration du tunnel :

```bash
sudo cat /etc/cloudflared/config.yml
```

Le fichier devrait contenir le tunnel ID et le type de service.

---

## 🎉 Résultat attendu

Une fois configuré, votre architecture ressemble à :

```
Internet
   ↓
Cloudflare Tunnel (CDN + DDoS protection)
   ↓
VM Cloudflared Client (port 7844 sortant)
   ↓
Nginx localhost:443
   ↓
Kubernetes Minikube (192.168.49.2:31224)
   ↓
Application Symfony
```

**Avantages** :
- ✅ Pas de port 443 à ouvrir sur le firewall
- ✅ Protection DDoS gratuite
- ✅ CDN mondial (votre site est plus rapide)
- ✅ Certificat SSL géré par Cloudflare
- ✅ Fonctionne même derrière NAT/firewall d'entreprise

---

## 📊 Monitoring

Dans le dashboard Cloudflare, vous pouvez voir :
- 📈 Trafic en temps réel
- 🌍 Carte géographique des visiteurs
- 🚦 Statut du tunnel (online/offline)
- 📊 Bande passante utilisée

---

## 🛠️ Commandes utiles

```bash
# Statut du service
sudo systemctl status cloudflared

# Démarrer
sudo systemctl start cloudflared

# Arrêter
sudo systemctl stop cloudflared

# Redémarrer
sudo systemctl restart cloudflared

# Logs en temps réel
sudo journalctl -u cloudflared -f

# Désinstaller (si besoin)
sudo cloudflared service uninstall
```

---

## 🆘 Besoin d'aide ?

Si vous avez des problèmes, exécutez le diagnostic :

```bash
./check-external-access.sh
```

Et consultez les logs :

```bash
sudo journalctl -u cloudflared -n 100 --no-pager
```

---

**Créé le 3 décembre 2025** | Configuration pour salem-ecommerce.duckdns.org
