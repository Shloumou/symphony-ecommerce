#!/bin/bash

echo "🚀 Setting up Nginx with Self-Signed SSL Certificate..."

# Configuration
VM_IP="192.168.207.128"
LOCAL_DOMAIN="ecommerce.local"

# Install Nginx
echo "📦 Installing Nginx..."
sudo dnf install -y nginx

# Create SSL directory
sudo mkdir -p /etc/nginx/ssl

# Generate self-signed certificate (valid for 365 days)
echo "🔐 Generating self-signed SSL certificate..."
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/ecommerce.key \
  -out /etc/nginx/ssl/ecommerce.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=$LOCAL_DOMAIN" \
  -addext "subjectAltName=DNS:$LOCAL_DOMAIN,DNS:localhost,IP:$VM_IP"

# Set proper permissions
sudo chmod 600 /etc/nginx/ssl/ecommerce.key
sudo chmod 644 /etc/nginx/ssl/ecommerce.crt

# Create Nginx configuration with HTTPS
echo "⚙️ Creating Nginx HTTPS configuration..."
sudo tee /etc/nginx/conf.d/ecommerce.conf > /dev/null <<'EOF'
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name 192.168.207.128 ecommerce.local localhost;
    return 301 https://$host$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name 192.168.207.128 ecommerce.local localhost;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/ecommerce.crt;
    ssl_certificate_key /etc/nginx/ssl/ecommerce.key;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logs
    access_log /var/log/nginx/ecommerce-ssl-access.log;
    error_log /var/log/nginx/ecommerce-ssl-error.log;

    # Proxy to Kubernetes NodePort
    location / {
        proxy_pass http://192.168.49.2:31224;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Ssl on;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Static file caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://192.168.49.2:31224;
        proxy_set_header Host $host;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "❌ Nginx configuration has errors. Exiting."
    exit 1
fi

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl restart nginx

# Open firewall ports
echo "🔥 Opening firewall ports..."
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Add local DNS entry to /etc/hosts
echo "🌐 Adding local DNS entry..."
if ! grep -q "ecommerce.local" /etc/hosts; then
    echo "127.0.0.1   ecommerce.local" | sudo tee -a /etc/hosts
fi

echo ""
echo "✅ Nginx with Self-Signed SSL setup complete!"
echo ""
echo "📱 Access your app:"
echo "   https://192.168.207.128"
echo "   https://ecommerce.local (from VM only)"
echo ""
echo "⚠️  Browser Warning:"
echo "   You'll see a security warning because the certificate is self-signed."
echo "   Click 'Advanced' → 'Proceed to site' to continue."
echo ""
echo "📱 For other devices on your network:"
echo "   1. Access: https://192.168.207.128"
echo "   2. Accept the security warning"
echo "   3. Or add ecommerce.local to device's hosts file:"
echo "      192.168.207.128  ecommerce.local"
echo ""
echo "🔍 Certificate details:"
sudo openssl x509 -in /etc/nginx/ssl/ecommerce.crt -text -noout | grep -A 2 "Subject:"
