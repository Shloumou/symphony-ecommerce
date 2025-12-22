# 🌐 Guide DNS + SSL/TLS pour Application E-commerce

Ce guide explique comment configurer un nom de domaine et un certificat SSL/TLS pour accéder à votre application Symfony e-commerce depuis l'extérieur de la VM de manière sécurisée.

---

## 🎯 Objectif

Transformer l'accès à votre application :
- ❌ **Avant** : `http://34.224.26.92` (IP publique, pas de HTTPS)
- ✅ **Après** : `https://mon-ecommerce.example.com` (Nom de domaine, HTTPS sécurisé)

---

## 📋 Prérequis

- ✅ Application Symfony déployée (Docker ou Kubernetes)
- ✅ VM accessible depuis Internet
- ✅ Port 80 et 443 ouverts dans le firewall
- ✅ Accès sudo/root sur la VM

---

## 🚀 Installation rapide

### Option 1 : Script automatique (Recommandé)

```bash
cd /home/salem/ecommerce_web_site_with_sym-master

# Rendre le script exécutable
chmod +x setup-dns-ssl.sh

# Exécuter le script
sudo ./setup-dns-ssl.sh
```

Le script vous guidera à travers 3 options :
1. **Domaine réel** (si vous possédez un nom de domaine)
2. **DNS dynamique gratuit** (DuckDNS, NoIP)
3. **Domaine local** (pour tests)

### Option 2 : Configuration manuelle

Suivez les sections ci-dessous selon votre choix.

---

## 📍 Option 1 : Utiliser un nom de domaine réel

### Étape 1 : Acheter un nom de domaine

Choisissez un registrar :
- [Namecheap](https://www.namecheap.com) (~$10/an)
- [GoDaddy](https://www.godaddy.com)
- [OVH](https://www.ovh.com)
- [Google Domains](https://domains.google)

### Étape 2 : Configurer le DNS

1. Obtenez votre IP publique :
```bash
curl ifconfig.me
# Résultat : 34.224.26.92
```

2. Dans le panneau de configuration de votre registrar :
   - Créez un enregistrement **A**
   - Nom : `@` (ou votre sous-domaine comme `shop`)
   - Type : `A`
   - Valeur : `34.224.26.92`
   - TTL : `300` (5 minutes)

3. Vérifiez la propagation DNS (peut prendre 1-48h) :
```bash
nslookup votredomaine.com
dig votredomaine.com
```

### Étape 3 : Installer Nginx et Let's Encrypt

```bash
# Installer Nginx
sudo dnf install -y nginx  # Pour Rocky Linux/CentOS
# OU
sudo apt install -y nginx  # Pour Ubuntu/Debian

# Installer Certbot
sudo dnf install -y certbot python3-certbot-nginx
# OU
sudo apt install -y certbot python3-certbot-nginx
```

### Étape 4 : Configurer Nginx

```bash
# Créer la configuration
sudo nano /etc/nginx/sites-available/ecommerce.conf
```

Contenu :
```nginx
server {
    listen 80;
    server_name votredomaine.com www.votredomaine.com;
    
    location / {
        proxy_pass http://localhost:80;  # Port de votre app
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Activer et tester :
```bash
sudo ln -s /etc/nginx/sites-available/ecommerce.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Étape 5 : Obtenir le certificat SSL/TLS

```bash
sudo certbot --nginx -d votredomaine.com -d www.votredomaine.com
```

Suivez les instructions interactives :
- Entrez votre email
- Acceptez les termes
- Choisissez la redirection automatique HTTP → HTTPS

Le certificat sera automatiquement renouvelé tous les 90 jours.

---

## 🦆 Option 2 : DNS Dynamique gratuit (DuckDNS)

Idéal si vous n'avez pas de nom de domaine.

### Étape 1 : Créer un compte DuckDNS

1. Allez sur https://www.duckdns.org
2. Connectez-vous avec Google/GitHub
3. Créez un sous-domaine : `mon-ecommerce`
4. Notez votre **token**

### Étape 2 : Configurer DuckDNS sur la VM

```bash
# Créer le dossier
sudo mkdir -p /etc/duckdns

# Créer le script de mise à jour
sudo nano /etc/duckdns/duck.sh
```

Contenu :
```bash
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=mon-ecommerce&token=VOTRE-TOKEN&ip=" | curl -k -o /etc/duckdns/duck.log -K -
```

Remplacez :
- `mon-ecommerce` par votre sous-domaine
- `VOTRE-TOKEN` par votre token DuckDNS

```bash
# Rendre exécutable
sudo chmod +x /etc/duckdns/duck.sh

# Tester
sudo /etc/duckdns/duck.sh
cat /etc/duckdns/duck.log  # Devrait afficher "OK"

# Ajouter au cron (mise à jour toutes les 5 minutes)
(sudo crontab -l 2>/dev/null; echo "*/5 * * * * /etc/duckdns/duck.sh >/dev/null 2>&1") | sudo crontab -
```

### Étape 3 : Configurer Nginx avec Let's Encrypt

Votre domaine est maintenant : `mon-ecommerce.duckdns.org`

Suivez les mêmes étapes que l'Option 1 (Étapes 3-5) en utilisant votre domaine DuckDNS.

---

## 🏠 Option 3 : Domaine local (Tests uniquement)

Pour tester localement sans domaine réel.

### Étape 1 : Modifier /etc/hosts

Sur la VM :
```bash
sudo nano /etc/hosts
```

Ajouter :
```
127.0.0.1 ecommerce.local
```

Sur votre machine locale (pour y accéder) :
```bash
# Linux/Mac
sudo nano /etc/hosts

# Windows
# Ouvrir C:\Windows\System32\drivers\etc\hosts en tant qu'admin

# Ajouter :
34.224.26.92 ecommerce.local
```

### Étape 2 : Certificat auto-signé

```bash
# Créer le dossier SSL
sudo mkdir -p /etc/nginx/ssl

# Générer le certificat
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/ecommerce.local.key \
    -out /etc/nginx/ssl/ecommerce.local.crt \
    -subj "/C=FR/ST=France/L=Paris/O=Ecommerce/OU=IT/CN=ecommerce.local"
```

### Étape 3 : Configuration Nginx avec SSL

```bash
sudo nano /etc/nginx/sites-available/ecommerce-local.conf
```

Contenu :
```nginx
server {
    listen 80;
    server_name ecommerce.local;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ecommerce.local;
    
    ssl_certificate /etc/nginx/ssl/ecommerce.local.crt;
    ssl_certificate_key /etc/nginx/ssl/ecommerce.local.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Activer :
```bash
sudo ln -s /etc/nginx/sites-available/ecommerce-local.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

⚠️ **Note** : Votre navigateur affichera un avertissement de sécurité (certificat auto-signé). Cliquez sur "Avancé" → "Continuer".

---

## 🔥 Configuration du Firewall

### Pour firewalld (Rocky Linux/CentOS)

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### Pour ufw (Ubuntu/Debian)

```bash
sudo ufw allow 'Nginx Full'
sudo ufw status
```

### Pour iptables

```bash
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

---

## 🔍 Vérification et Tests

### 1. Tester la configuration Nginx

```bash
sudo nginx -t
```

### 2. Vérifier les logs

```bash
# Logs d'accès
sudo tail -f /var/log/nginx/access.log

# Logs d'erreur
sudo tail -f /var/log/nginx/error.log
```

### 3. Tester le certificat SSL

```bash
# Depuis la VM
curl -I https://votredomaine.com

# Tester avec OpenSSL
openssl s_client -connect votredomaine.com:443 -servername votredomaine.com
```

### 4. Vérifier le renouvellement automatique

```bash
# Voir le timer certbot
sudo systemctl status certbot.timer

# Test de renouvellement (dry-run)
sudo certbot renew --dry-run
```

---

## 🛠️ Dépannage

### Problème : "Connection refused"

```bash
# Vérifier que l'app est en cours d'exécution
sudo docker ps
# OU
kubectl get pods -n ecommerce

# Vérifier le port
sudo netstat -tlnp | grep :80
```

### Problème : "502 Bad Gateway"

```bash
# Vérifier la configuration Nginx
sudo nginx -t

# Vérifier que le proxy_pass pointe vers le bon port
sudo nano /etc/nginx/sites-available/votre-config

# Redémarrer Nginx
sudo systemctl restart nginx
```

### Problème : Certificat Let's Encrypt échoue

```bash
# Vérifier que le DNS pointe vers la bonne IP
nslookup votredomaine.com

# Vérifier que le port 80 est accessible depuis Internet
curl -I http://votredomaine.com

# Vérifier les logs Certbot
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Problème : Redirection infinie

Vérifiez les headers dans Nginx :
```nginx
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $server_name;
```

---

## 📊 Commandes utiles

```bash
# Recharger Nginx sans interruption
sudo systemctl reload nginx

# Redémarrer Nginx
sudo systemctl restart nginx

# Vérifier le status
sudo systemctl status nginx

# Renouveler manuellement le certificat
sudo certbot renew

# Lister les certificats
sudo certbot certificates

# Supprimer un certificat
sudo certbot delete --cert-name votredomaine.com
```

---

## 🔒 Bonnes pratiques de sécurité

### 1. HTTPS seulement

Forcez la redirection HTTP → HTTPS dans Nginx :
```nginx
server {
    listen 80;
    server_name votredomaine.com;
    return 301 https://$server_name$request_uri;
}
```

### 2. Headers de sécurité

Ajoutez dans votre bloc `server` :
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

### 3. SSL fort

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
```

### 4. Rate limiting

```nginx
limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;

server {
    location / {
        limit_req zone=mylimit burst=20;
        # ...
    }
}
```

---

## 📚 Ressources

- [Let's Encrypt](https://letsencrypt.org/)
- [DuckDNS](https://www.duckdns.org/)
- [Nginx SSL Configuration](https://ssl-config.mozilla.org/)
- [SSL Labs Test](https://www.ssllabs.com/ssltest/)

---

## ✅ Checklist finale

- [ ] Nom de domaine configuré (DNS A record)
- [ ] Nginx installé et configuré
- [ ] Certificat SSL/TLS obtenu
- [ ] Ports 80 et 443 ouverts dans le firewall
- [ ] Redirection HTTP → HTTPS activée
- [ ] Renouvellement automatique configuré
- [ ] Application accessible via HTTPS

**Félicitations ! Votre application est maintenant accessible de manière sécurisée !** 🎉
