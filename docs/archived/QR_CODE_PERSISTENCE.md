# 🔄 Guide de Persistance du QR Code 2FA

## 🎯 Problème

Après un redémarrage du cluster Kubernetes ou de la VM, le QR code 2FA ne s'affiche plus car l'image Docker avec les dépendances QR code n'est pas persistante dans minikube.

## ✅ Solutions

### Solution 1 : Script Automatique (Recommandé)

#### Utilisation Manuelle

Après chaque redémarrage de la VM ou du cluster, exécutez :

```bash
cd /home/salem/ecommerce_web_site_with_sym-master
./rebuild-and-deploy.sh
```

Ce script va :
1. ✅ Vérifier que minikube est démarré
2. ✅ Reconstruire l'image Docker avec les dépendances QR code
3. ✅ Charger l'image dans minikube
4. ✅ Redémarrer le déploiement
5. ✅ Vérifier que le QR code fonctionne

#### Automatisation au Démarrage (Optionnel)

Pour que l'application se rebuilde automatiquement au démarrage de la VM :

```bash
# Copier le service systemd
sudo cp ecommerce-rebuild.service /etc/systemd/system/

# Activer le service
sudo systemctl daemon-reload
sudo systemctl enable ecommerce-rebuild.service

# Tester le service
sudo systemctl start ecommerce-rebuild.service
sudo systemctl status ecommerce-rebuild.service
```

**Note** : L'automatisation au démarrage peut rallonger le temps de boot de 5-10 minutes (le temps de reconstruire l'image).

### Solution 2 : Build Initial Correct

Si vous préférez ne pas avoir à reconstruire à chaque fois, assurez-vous que le Dockerfile est correct :

```dockerfile
# Multi-stage build for Symfony app
# Stage 1: composer install
FROM composer:2.7 AS builder
WORKDIR /app
# Copy composer files and full project
COPY . /app
# Install missing dependencies first, then install all
RUN composer require --no-update "scheb/2fa-bundle:^6.0" "scheb/2fa-totp:^6.0" "endroid/qr-code:^4.0" && \
    composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader --no-scripts --ignore-platform-reqs --no-ansi || \
    composer update --no-dev --prefer-dist --no-interaction --optimize-autoloader --no-scripts --ignore-platform-reqs --no-ansi
RUN composer dump-autoload --optimize --no-interaction
```

Puis construisez **une seule fois** avec le bon tag :

```bash
docker build -t ecommerce_web_site_with_sym:latest .
minikube image load ecommerce_web_site_with_sym:latest
```

### Solution 3 : Utiliser un Registry Docker

Pour une solution vraiment permanente, utilisez un registry Docker (Docker Hub, Harbor, etc.) :

1. **Construire et pousser l'image** :
```bash
docker build -t votre-username/ecommerce-app:latest .
docker push votre-username/ecommerce-app:latest
```

2. **Mettre à jour le déploiement** :
```yaml
# k8s/app-deployment.yaml
spec:
  containers:
    - name: ecommerce-app
      image: votre-username/ecommerce-app:latest
      imagePullPolicy: Always
```

3. **Appliquer** :
```bash
kubectl apply -f k8s/app-deployment.yaml
```

## 🧪 Vérification

### Test 1 : Vérifier l'image dans minikube

```bash
minikube image ls | grep ecommerce
```

Vous devriez voir :
```
docker.io/library/ecommerce_web_site_with_sym:latest
```

### Test 2 : Vérifier la bibliothèque QR code dans le pod

```bash
kubectl exec -n ecommerce $(kubectl get pods -n ecommerce -l app=ecommerce-app -o name | head -1) -- \
  php -r "require '/var/www/html/vendor/autoload.php'; echo class_exists('Endroid\QrCode\Builder\Builder') ? '✅ QR Code OK\n' : '❌ QR Code manquant\n';"
```

### Test 3 : Tester le QR code via l'interface web

1. Ouvrez https://salem-ecommerce.duckdns.org/connexion
2. Connectez-vous (ex: admin@admin.com)
3. Allez sur https://salem-ecommerce.duckdns.org/2fa
4. ✅ Le QR code devrait s'afficher

### Test 4 : Générer un QR code via console

```bash
kubectl exec -n ecommerce $(kubectl get pods -n ecommerce -l app=ecommerce-app -o name | head -1) -- \
  php bin/console app:show-totp admin@admin.com
```

## 📋 Checklist Post-Redémarrage

Après chaque redémarrage de la VM ou du cluster :

- [ ] Vérifier que minikube est démarré : `minikube status`
- [ ] Exécuter le script de rebuild : `./rebuild-and-deploy.sh`
- [ ] Vérifier que le pod est en cours d'exécution : `kubectl get pods -n ecommerce`
- [ ] Tester le QR code dans le navigateur

## 🔧 Troubleshooting

### Le QR code ne s'affiche pas après redémarrage

```bash
# 1. Vérifier l'image utilisée
kubectl get deployment ecommerce-app -n ecommerce -o jsonpath='{.spec.template.spec.containers[0].image}'

# 2. Reconstruire et recharger
./rebuild-and-deploy.sh

# 3. Forcer la recréation du pod
kubectl delete pod -n ecommerce -l app=ecommerce-app
kubectl wait --for=condition=ready pod -l app=ecommerce-app -n ecommerce --timeout=300s
```

### L'image n'est pas dans minikube

```bash
# Lister les images disponibles
minikube image ls | grep ecommerce

# Charger l'image
docker build -t ecommerce_web_site_with_sym:latest .
minikube image load ecommerce_web_site_with_sym:latest
```

### Le pod utilise l'ancienne image

```bash
# Vérifier la politique de pull
kubectl describe pod -n ecommerce -l app=ecommerce-app | grep "Image:"

# Forcer un nouveau déploiement
kubectl rollout restart deployment/ecommerce-app -n ecommerce
```

## 📝 Résumé

**Méthode Simple** : Exécutez `./rebuild-and-deploy.sh` après chaque redémarrage

**Méthode Automatique** : Installez le service systemd pour automatiser au démarrage

**Méthode Permanente** : Utilisez un registry Docker externe (Docker Hub, etc.)

---

**Créé le 5 décembre 2025** | Persistance du QR Code 2FA
