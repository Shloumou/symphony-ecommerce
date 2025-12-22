#!/bin/bash

echo "🌐 Setting up local DNS server with dnsmasq..."

# Install dnsmasq
echo "📦 Installing dnsmasq..."
sudo dnf install -y dnsmasq

# Configure dnsmasq
echo "⚙️ Creating dnsmasq configuration..."
sudo tee /etc/dnsmasq.d/ecommerce.conf > /dev/null <<EOF
# Listen on all interfaces
interface=*

# Local domain
domain=local
local=/local/

# DNS entries
address=/ecommerce.local/192.168.207.128

# Upstream DNS servers
server=8.8.8.8
server=8.8.4.4

# Don't read /etc/hosts
no-hosts

# Cache size
cache-size=1000
EOF

# Enable and start dnsmasq
echo "🚀 Starting dnsmasq service..."
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq

# Open DNS port in firewall
echo "🔥 Opening DNS port in firewall..."
sudo firewall-cmd --permanent --add-service=dns
sudo firewall-cmd --reload

# Test DNS
echo ""
echo "🧪 Testing DNS resolution..."
sleep 2
nslookup ecommerce.local 127.0.0.1

echo ""
echo "✅ Local DNS server configured!"
echo ""
echo "📱 Configure devices to use this DNS:"
echo "   DNS Server: 192.168.207.128"
echo ""
echo "   On Android/iOS:"
echo "   WiFi Settings → Advanced → DNS → 192.168.207.128"
echo ""
echo "   On Windows:"
echo "   Network Settings → Change adapter → Properties → IPv4 → DNS"
echo ""
echo "   Then access: https://ecommerce.local"
echo ""
echo "🔍 DNS Status:"
sudo systemctl status dnsmasq --no-pager | head -10
