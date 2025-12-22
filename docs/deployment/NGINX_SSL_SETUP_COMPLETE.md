# ✅ Nginx + SSL/TLS + Local DNS Setup Complete!

## 🎉 Your ecommerce application is now accessible with HTTPS!

### 📱 Access URLs

**From this VM:**
- `https://192.168.207.128`
- `https://ecommerce.local`
- `https://localhost`

**From other devices on your network:**
- `https://192.168.207.128`
- `https://ecommerce.local` (after DNS configuration)

---

## 📱 Configure Other Devices (Phone, Laptop, etc.)

### Step 1: Set DNS Server

**Android/iOS:**
1. Go to WiFi Settings
2. Long press your WiFi network
3. Select "Modify Network" or "Advanced"
4. Change DNS to: `192.168.207.128`
5. Save and reconnect

**Windows:**
```powershell
# Open PowerShell as Administrator
netsh interface ip set dns "Wi-Fi" static 192.168.207.128
netsh interface ip add dns "Wi-Fi" 8.8.8.8 index=2
```

**Linux:**
```bash
sudo nmcli connection modify "Your-WiFi-Name" ipv4.dns "192.168.207.128 8.8.8.8"
sudo nmcli connection down "Your-WiFi-Name" && sudo nmcli connection up "Your-WiFi-Name"
```

**macOS:**
```
System Preferences → Network → WiFi → Advanced → DNS
Add: 192.168.207.128
```

### Step 2: Access the App

Open browser and go to:
```
https://ecommerce.local
```

⚠️ **You'll see a security warning** because the certificate is self-signed. This is normal!

Click:
- **Chrome/Edge**: "Advanced" → "Proceed to ecommerce.local (unsafe)"
- **Firefox**: "Advanced" → "Accept the Risk and Continue"  
- **Safari**: "Show Details" → "visit this website"

---

## 🔍 What Was Installed

### 1. Nginx Web Server
- Version: 1.28.0
- Listening on ports: 80 (HTTP), 443 (HTTPS)
- HTTP automatically redirects to HTTPS
- Proxies traffic to Kubernetes app at `192.168.49.2:31224`

### 2. Self-Signed SSL Certificate
- Location: `/etc/nginx/ssl/ecommerce.crt` and `/etc/nginx/ssl/ecommerce.key`
- Valid for: 365 days
- Supports: ecommerce.local, localhost, 192.168.207.128

### 3. Local DNS Server (dnsmasq)
- Resolves `ecommerce.local` to `192.168.207.128`
- Listens on port 53
- Upstream DNS: 8.8.8.8, 8.8.4.4

### 4. Firewall Configuration
- Opened ports: 80 (HTTP), 443 (HTTPS), 53 (DNS)

### 5. SELinux Configuration
- Allowed Nginx to make network connections

---

## 🛠️ Useful Commands

### Check Services Status
```bash
# Nginx
sudo systemctl status nginx

# DNS Server
sudo systemctl status dnsmasq

# Both services
sudo systemctl status nginx dnsmasq
```

### Restart Services
```bash
# Restart Nginx
sudo systemctl restart nginx

# Restart DNS
sudo systemctl restart dnsmasq

# Restart both
sudo systemctl restart nginx dnsmasq
```

### View Logs
```bash
# Nginx access logs
sudo tail -f /var/log/nginx/ecommerce-ssl-access.log

# Nginx error logs
sudo tail -f /var/log/nginx/ecommerce-ssl-error.log

# DNS logs
sudo journalctl -u dnsmasq -f
```

### Test Connectivity
```bash
# Test HTTPS (ignore certificate warning)
curl -k https://ecommerce.local

# Test DNS resolution
nslookup ecommerce.local 127.0.0.1

# Test backend app
curl http://192.168.49.2:31224

# Check open ports
sudo ss -tulnp | grep -E "(:80|:443|:53)"
```

### Configuration Files
```bash
# Nginx main config
/etc/nginx/nginx.conf

# Ecommerce site config
/etc/nginx/conf.d/ecommerce.conf

# SSL certificates
/etc/nginx/ssl/ecommerce.crt
/etc/nginx/ssl/ecommerce.key

# DNS config
/etc/dnsmasq.d/ecommerce.conf

# Hosts file
/etc/hosts
```

---

## 🔧 Troubleshooting

### Problem: Can't access from other devices

**Check DNS:**
```bash
# On the other device, check DNS is set correctly
# Should show 192.168.207.128

# From VM, test DNS is working
sudo systemctl status dnsmasq
nslookup ecommerce.local 127.0.0.1
```

**Check Firewall:**
```bash
sudo firewall-cmd --list-all
# Should show: services: dns http https
```

### Problem: 502 Bad Gateway

**Check backend app:**
```bash
curl http://192.168.49.2:31224
kubectl -n ecommerce get pods
```

**Check Nginx can connect:**
```bash
sudo tail -f /var/log/nginx/ecommerce-ssl-error.log
# If you see "Permission denied", run:
sudo setsebool -P httpd_can_network_connect 1
```

### Problem: DNS not resolving

**Restart dnsmasq:**
```bash
sudo systemctl restart dnsmasq
sudo systemctl status dnsmasq
```

**Test from VM:**
```bash
nslookup ecommerce.local 127.0.0.1
dig @127.0.0.1 ecommerce.local
```

### Problem: Certificate error

**Regenerate certificate:**
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/ecommerce.key \
  -out /etc/nginx/ssl/ecommerce.crt \
  -subj "/C=US/ST=State/L=City/O=Ecommerce/CN=ecommerce.local" \
  -addext "subjectAltName=DNS:ecommerce.local,DNS:localhost,IP:192.168.207.128"

sudo systemctl restart nginx
```

---

## 🔒 Security Notes

### Self-Signed Certificate
- ⚠️ Browser will show warnings (this is expected)
- ✅ Traffic is encrypted between client and server
- ❌ Certificate is not trusted by certificate authorities
- 💡 For production, use Let's Encrypt for free trusted certificates

### Firewall
- ✅ Only ports 80, 443, 53, and 31224 are open
- ✅ All other traffic is blocked

### SELinux
- ✅ Enabled and enforcing
- ✅ Nginx allowed to make network connections
- ✅ Other restrictions still apply

---

## 📊 Network Architecture

```
Other Devices          VM Host               Minikube Cluster
(Phone, Laptop)    (192.168.207.128)       (192.168.49.2)
     |                     |                        |
     |                     |                        |
     |--- HTTPS:443 --->  Nginx  --- HTTP:31224 -->| 
     |                  (SSL/TLS)                   |
     |                     |                    K8s Service
     |                     |                    (NodePort)
     |                     |                        |
     |--- DNS:53 ----> dnsmasq                     |
     |                     |                    App Pods
     |                     |                 (PHP/Symfony)
     |                     |                        |
     +--- ecommerce.local -+                   MySQL Pod
      resolves to                            (Database)
    192.168.207.128
```

---

## 🎯 Quick Start Guide for New Devices

1. **Connect to the same WiFi** as the VM
2. **Set DNS to** `192.168.207.128` in WiFi settings
3. **Open browser** and go to `https://ecommerce.local`
4. **Accept the certificate warning**
5. **Enjoy your ecommerce app!** 🎉

---

## 📞 Support

**Created:** $(date)
**VM IP:** 192.168.207.128  
**Domain:** ecommerce.local  
**Nginx Version:** 1.28.0  
**SSL:** Self-signed certificate (365 days)  
**DNS:** dnsmasq  

**Services Running:**
- ✅ Nginx (HTTPS reverse proxy)
- ✅ dnsmasq (Local DNS)
- ✅ Kubernetes (ecommerce app)
- ✅ MySQL (database)
- ✅ Firewall (configured)

---

## 🚀 Next Steps (Optional)

### Add More Domains
Edit `/etc/dnsmasq.d/ecommerce.conf` and add:
```
address=/anotherdomain.local/192.168.207.128
```
Then restart: `sudo systemctl restart dnsmasq`

### Get Real SSL Certificate (Production)
```bash
# Install certbot
sudo dnf install -y certbot python3-certbot-nginx

# Get certificate (requires public domain and open port 80)
sudo certbot --nginx -d yourdomain.com
```

### Monitor Traffic
```bash
# Install monitoring tools
sudo dnf install -y nginx-mod-http-image-filter

# Real-time access log
sudo tail -f /var/log/nginx/ecommerce-ssl-access.log

# Count requests
sudo tail -1000 /var/log/nginx/ecommerce-ssl-access.log | wc -l
```

---

**🎉 Setup Complete! Your ecommerce app is now accessible via HTTPS from any device on your network!**
