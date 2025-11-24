# Client Device Setup Guide for ecommerce.local

## ✅ Server Status (Already Confirmed)
- ✅ Nginx is running and accessible on port 443
- ✅ dnsmasq is listening on 192.168.207.128:53
- ✅ Firewall allows DNS (port 53), HTTP (port 80), and HTTPS (port 443)
- ✅ DNS resolution works: `nslookup ecommerce.local 192.168.207.128`

## 📱 Client Device Configuration Steps

### Step 1: Ensure Network Connectivity
First, make sure your device can reach the VM:

```bash
# From your phone/laptop, try to ping the VM
ping 192.168.207.128
```

If ping fails:
- Ensure both devices are on the **same network** (192.168.207.0/24)
- Check if your router allows device-to-device communication
- Some WiFi networks have "AP Isolation" enabled which blocks this

---

### Step 2: Test DNS Resolution

Try to resolve the domain using the VM's DNS server:

**On Linux/Mac:**
```bash
nslookup ecommerce.local 192.168.207.128
# or
dig @192.168.207.128 ecommerce.local
```

**On Windows:**
```cmd
nslookup ecommerce.local 192.168.207.128
```

**On Android:**
- Install "DNS Lookup" app from Play Store
- Set DNS server to: 192.168.207.128
- Query: ecommerce.local

**Expected Result:**
```
Server:         192.168.207.128
Address:        192.168.207.128#53

Name:   ecommerce.local
Address: 192.168.207.128
```

---

### Step 3: Configure DNS on Your Device

#### 🤖 Android
1. Open **Settings**
2. Go to **Network & Internet** → **WiFi**
3. Long-press your WiFi network → **Modify Network**
4. Tap **Advanced Options**
5. Change **IP Settings** from DHCP to **Static**
6. Keep your current IP, Gateway, and Subnet
7. Set **DNS 1** to: `192.168.207.128`
8. Set **DNS 2** to: `8.8.8.8` (fallback)
9. Save and reconnect

#### 🍎 iOS/iPhone/iPad
1. Open **Settings** → **WiFi**
2. Tap the **(i)** icon next to your connected network
3. Scroll down and tap **Configure DNS**
4. Select **Manual**
5. Tap **Add Server**
6. Enter: `192.168.207.128`
7. Add another server: `8.8.8.8` (fallback)
8. Remove any existing servers
9. Tap **Save**

#### 💻 Windows
1. Open **Control Panel** → **Network and Sharing Center**
2. Click **Change adapter settings**
3. Right-click your network → **Properties**
4. Select **Internet Protocol Version 4 (TCP/IPv4)** → **Properties**
5. Select **Use the following DNS server addresses**
6. Preferred DNS: `192.168.207.128`
7. Alternate DNS: `8.8.8.8`
8. Click **OK**

#### 🐧 Linux
```bash
# Temporary (until reboot)
sudo sh -c 'echo "nameserver 192.168.207.128" > /etc/resolv.conf'

# Permanent (NetworkManager)
sudo nmcli connection modify "Your-WiFi-Name" ipv4.dns "192.168.207.128 8.8.8.8"
sudo nmcli connection down "Your-WiFi-Name"
sudo nmcli connection up "Your-WiFi-Name"
```

#### 🍎 macOS
1. Open **System Preferences** → **Network**
2. Select your network interface → **Advanced**
3. Go to the **DNS** tab
4. Click **+** and add: `192.168.207.128`
5. Add another: `8.8.8.8`
6. Click **OK** → **Apply**

---

### Step 4: Test HTTPS Access

After configuring DNS, test access:

**Using a browser:**
1. Open browser on your device
2. Go to: `https://ecommerce.local`
3. You'll see a security warning (self-signed certificate)
4. Click "Advanced" → "Proceed anyway" or "Accept Risk"

**Using command line (if available):**
```bash
# Test HTTP (should redirect to HTTPS)
curl -I http://ecommerce.local

# Test HTTPS (ignore certificate)
curl -Ik https://ecommerce.local
```

Expected: HTTP/2 200 response

---

## 🔧 Troubleshooting

### Issue 1: Cannot Ping 192.168.207.128

**Possible Causes:**
- Devices on different networks/subnets
- Router has AP Isolation enabled
- VM firewall blocking ICMP

**Solutions:**
```bash
# On the VM, allow ICMP:
sudo firewall-cmd --add-service=icmp --permanent
sudo firewall-cmd --reload

# Check if both devices are on same subnet
ip addr show | grep 192.168.207
```

### Issue 2: DNS Resolution Fails

**Test from client:**
```bash
# Does the VM's DNS respond?
nslookup google.com 192.168.207.128
```

If this works but `ecommerce.local` doesn't:
```bash
# On VM, check dnsmasq logs
sudo journalctl -u dnsmasq -f
# Then try DNS query from client while watching logs
```

If DNS completely fails:
```bash
# On VM, verify dnsmasq is running
sudo systemctl status dnsmasq

# Verify firewall allows DNS
sudo firewall-cmd --list-all | grep dns

# Test DNS port is open from client
telnet 192.168.207.128 53
# or
nc -zv 192.168.207.128 53
```

### Issue 3: DNS Works But HTTPS Fails

**Test direct IP access first:**
```bash
curl -Ik https://192.168.207.128
```

If IP works but domain doesn't:
- DNS cache issue on client
- Browser DNS cache

**Solutions:**
```bash
# Clear DNS cache on client

# Windows:
ipconfig /flushdns

# macOS:
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Linux:
sudo systemd-resolve --flush-caches

# Chrome browser:
# Go to: chrome://net-internals/#dns
# Click "Clear host cache"
```

### Issue 4: "Connection Refused" or Timeout

**Check ports are open:**
```bash
# From client device, test if ports are reachable
telnet 192.168.207.128 443
# or
nc -zv 192.168.207.128 443
```

If ports are closed:
```bash
# On VM, verify Nginx is running
sudo systemctl status nginx

# Verify firewall rules
sudo firewall-cmd --list-ports
sudo firewall-cmd --list-services

# Re-add rules if needed
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload
```

### Issue 5: Certificate Error Won't Go Away

This is **expected** with self-signed certificates. You must:
1. Click "Advanced" or "Show Details"
2. Click "Proceed to ecommerce.local (unsafe)" or "Accept Risk"

**To avoid this (optional):**
- Install the self-signed certificate on your device as a trusted CA
- Or use a real certificate from Let's Encrypt (requires public domain)

---

## 🎯 Quick Verification Checklist

From your **client device**, verify:

1. ✅ **Connectivity**: `ping 192.168.207.128`
2. ✅ **DNS Port**: `nc -zv 192.168.207.128 53`
3. ✅ **HTTPS Port**: `nc -zv 192.168.207.128 443`
4. ✅ **DNS Resolution**: `nslookup ecommerce.local 192.168.207.128`
5. ✅ **Device DNS Config**: DNS set to 192.168.207.128
6. ✅ **HTTPS Access**: Browser can reach `https://ecommerce.local`

---

## 📡 Network Architecture

```
Your Phone/Laptop (192.168.207.X)
         ↓
    [Same Network]
         ↓
RHEL 9 VM (192.168.207.128)
         ↓
    [dnsmasq DNS] → ecommerce.local = 192.168.207.128
         ↓
    [Nginx HTTPS 443]
         ↓
    [Minikube 192.168.49.2:31224]
         ↓
    [Symfony App in Kubernetes]
```

---

## 🔐 For Production Use

Current setup is for **local development only**:
- ❌ Self-signed certificate (browsers will warn)
- ❌ Local DNS only (doesn't work outside your network)

For production:
- ✅ Use real domain name
- ✅ Use Let's Encrypt for valid SSL certificate
- ✅ Use public DNS (Cloudflare, Route53, etc.)

---

## 💡 Alternative Access Method

If DNS configuration is too complex for your device, you can:

1. **Access by IP only:**
   ```
   https://192.168.207.128
   ```
   This bypasses DNS entirely.

2. **Edit hosts file** (requires root/admin):
   
   **Linux/Mac**: `/etc/hosts`
   **Windows**: `C:\Windows\System32\drivers\etc\hosts`
   
   Add line:
   ```
   192.168.207.128    ecommerce.local
   ```

---

## 📞 Need Help?

Run these diagnostic commands on the **VM** and share output:

```bash
# Check all services
sudo systemctl status nginx dnsmasq | grep Active

# Check network listeners
sudo netstat -tulpn | grep -E ':(53|80|443)\s'

# Check firewall
sudo firewall-cmd --list-all

# Test local access
curl -Ik https://ecommerce.local
nslookup ecommerce.local 192.168.207.128
```

Run these on your **client device**:

```bash
# Basic connectivity
ping 192.168.207.128
nslookup ecommerce.local 192.168.207.128
curl -Ik https://192.168.207.128
```
