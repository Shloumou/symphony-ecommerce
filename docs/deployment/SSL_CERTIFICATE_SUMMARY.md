# 🔒 Certificat SSL/TLS installé pour ecommerce.local

## ✅ Configuration réussie

### 📋 Récapitulatif

**Date d'installation** : 3 décembre 2025  
**Domaine** : `ecommerce.local`  
**Type de certificat** : Auto-signé (Self-Signed)  
**Validité** : 365 jours  
**Protocoles** : TLS 1.2, TLS 1.3

---

## 🌐 Accès à votre application

### URL sécurisée
```
https://ecommerce.local
```

### ⚠️ Avertissement de sécurité
Comme le certificat est auto-signé, votre navigateur affichera un avertissement :
- **Chrome/Edge** : "Votre connexion n'est pas privée"
- **Firefox** : "Avertissement : risque probable de sécurité"

**C'est normal !** Cliquez sur "Avancé" puis "Continuer vers ecommerce.local"

---

## 📁 Fichiers créés

### Certificat SSL
```bash
# Certificat public
/etc/nginx/ssl/ecommerce.local.crt

# Clé privée
/etc/nginx/ssl/ecommerce.local.key
```

### Configuration Nginx
```bash
/etc/nginx/conf.d/ecommerce.local.conf
```

### Configuration DNS locale
```bash
# Ajouté dans /etc/hosts
127.0.0.1 ecommerce.local
```

---

## 🔧 Configuration détaillée

### Paramètres SSL
- **Algorithme** : RSA 2048 bits
- **Chiffrement** : ECDHE-RSA-AES128-GCM-SHA256, ECDHE-RSA-AES256-GCM-SHA384
- **Session cache** : 10m
- **Session timeout** : 10m

### Headers de sécurité activés
```nginx
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
```

### Redirection automatique
- HTTP (port 80) → HTTPS (port 443) automatiquement

---

## 🧪 Tests

### Tester le certificat
```bash
# Test HTTPS local
curl -Ik https://ecommerce.local

# Voir les détails du certificat
openssl s_client -connect ecommerce.local:443 -servername ecommerce.local

# Vérifier les dates de validité
openssl x509 -in /etc/nginx/ssl/ecommerce.local.crt -text -noout | grep -A 2 "Validity"
```

### Tester la redirection HTTP → HTTPS
```bash
curl -I http://ecommerce.local
# Devrait retourner : HTTP/1.1 301 Moved Permanently
```

---

## 📊 Architecture

```
Navigateur
    ↓
https://ecommerce.local (HTTPS - Port 443)
    ↓
[Nginx SSL Termination]
    ↓
http://192.168.49.2:31224 (Minikube)
    ↓
[Kubernetes Service: ecommerce-service]
    ↓
[Pod: ecommerce-app]
    ↓
[Application Symfony]
```

---

## 🔄 Maintenance

### Renouveler le certificat (après 1 an)
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/ecommerce.local.key \
  -out /etc/nginx/ssl/ecommerce.local.crt \
  -subj "/C=TN/ST=Tunisia/L=Tunis/O=Ecommerce/OU=IT/CN=ecommerce.local"

sudo systemctl reload nginx
```

### Vérifier la validité
```bash
openssl x509 -in /etc/nginx/ssl/ecommerce.local.crt -noout -dates
```

### Logs Nginx
```bash
# Logs d'accès HTTPS
sudo tail -f /var/log/nginx/ecommerce.local.access.log

# Logs d'erreur
sudo tail -f /var/log/nginx/ecommerce.local.error.log
```

---

## 🖥️ Accès depuis d'autres machines

Pour accéder depuis un autre ordinateur sur le même réseau :

### 1. Sur la machine cliente
Modifiez le fichier hosts :

**Linux/Mac**
```bash
sudo nano /etc/hosts
# Ajoutez (remplacez par l'IP de votre serveur) :
197.16.234.153 ecommerce.local
```

**Windows**
```
1. Ouvrir en tant qu'administrateur : C:\Windows\System32\drivers\etc\hosts
2. Ajouter :
197.16.234.153 ecommerce.local
```

### 2. Installer le certificat (pour éviter l'avertissement)

**Linux**
```bash
sudo cp ecommerce.local.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

**Windows**
```
1. Double-clic sur ecommerce.local.crt
2. Installer le certificat → Ordinateur local
3. Placer dans "Autorités racines de confiance"
```

---

## ⚙️ Commandes utiles

```bash
# Redémarrer Nginx
sudo systemctl restart nginx

# Recharger la configuration (sans interruption)
sudo systemctl reload nginx

# Vérifier la configuration
sudo nginx -t

# Voir le statut
sudo systemctl status nginx

# Désactiver temporairement HTTPS
sudo mv /etc/nginx/conf.d/ecommerce.local.conf /etc/nginx/conf.d/ecommerce.local.conf.disabled
sudo systemctl reload nginx

# Réactiver HTTPS
sudo mv /etc/nginx/conf.d/ecommerce.local.conf.disabled /etc/nginx/conf.d/ecommerce.local.conf
sudo systemctl reload nginx
```

---

## 🔐 Sécurité supplémentaire

### Activer les logs d'audit
```bash
# Voir qui accède à votre site
sudo tail -f /var/log/nginx/ecommerce.local.access.log | grep -v "192.168"
```

### Rate limiting (protection DDoS)
Ajoutez dans `/etc/nginx/conf.d/ecommerce.local.conf` :
```nginx
limit_req_zone $binary_remote_addr zone=ecommerce_limit:10m rate=10r/s;

server {
    location / {
        limit_req zone=ecommerce_limit burst=20;
        # ... reste de la config
    }
}
```

### Bloquer des IPs spécifiques
```nginx
# Dans le bloc server
deny 1.2.3.4;
allow all;
```

---

## 📚 Comparaison : Auto-signé vs Let's Encrypt

| Caractéristique | Auto-signé (ecommerce.local) | Let's Encrypt (salem-ecommerce.duckdns.org) |
|----------------|------------------------------|----------------------------------------------|
| **Coût** | Gratuit ✅ | Gratuit ✅ |
| **Chiffrement** | AES 256 bits ✅ | AES 256 bits ✅ |
| **Validité** | 1 an (365 jours) | 90 jours |
| **Renouvellement** | Manuel | Automatique ✅ |
| **Avertissement navigateur** | Oui ⚠️ | Non ✅ |
| **Usage recommandé** | Développement/Local | Production/Public ✅ |
| **Accessibilité** | Réseau local uniquement | Internet ✅ |

---

## ✅ Résumé

Votre application e-commerce est maintenant accessible en HTTPS sécurisé sur :

- 🔒 **Local** : https://ecommerce.local (certificat auto-signé)
- 🌐 **Public** : https://salem-ecommerce.duckdns.org (Let's Encrypt) ⚠️ Port 443 bloqué

**Chiffrement actif** : TLS 1.2/1.3 avec AES-256  
**Headers de sécurité** : HSTS, X-Frame-Options, CSP  
**Redirection automatique** : HTTP → HTTPS

---

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifier les logs : `sudo tail -f /var/log/nginx/error.log`
2. Tester la config : `sudo nginx -t`
3. Vérifier les ports : `sudo ss -tlnp | grep nginx`
4. Vérifier le certificat : `openssl x509 -in /etc/nginx/ssl/ecommerce.local.crt -text -noout`

**Configuration terminée avec succès !** 🎉
