# Network Access Configuration

## Access URLs

### From the VM (localhost)
```
http://192.168.49.2:31224
http://localhost:31224
```

### From Other Devices on the Network
```
http://192.168.207.128:31224
```

Replace `192.168.207.128` with your VM's current IP address.

---

## How to Find Your VM IP Address

```bash
# Get the external IP (the one other devices use)
ip addr show ens160 | grep "inet " | awk '{print $2}' | cut -d/ -f1

# Or simpler:
hostname -I | awk '{print $1}'
```

Current VM IP: **192.168.207.128**

---

## Firewall Configuration

### Port 31224 is Open
The application NodePort (31224) is now accessible from external devices.

### Check Firewall Status
```bash
# List all open ports
sudo firewall-cmd --list-ports

# List all rules
sudo firewall-cmd --list-all
```

### If You Need to Open More Ports
```bash
# Open a port temporarily (until reboot)
sudo firewall-cmd --add-port=PORT_NUMBER/tcp

# Open a port permanently
sudo firewall-cmd --permanent --add-port=PORT_NUMBER/tcp
sudo firewall-cmd --reload
```

### If You Need to Close the Port
```bash
sudo firewall-cmd --permanent --remove-port=31224/tcp
sudo firewall-cmd --reload
```

---

## Troubleshooting Network Access

### 1. Check if the app is running
```bash
kubectl -n ecommerce get pods
curl http://192.168.49.2:31224
```

### 2. Check firewall
```bash
sudo firewall-cmd --list-ports | grep 31224
```

### 3. Check service
```bash
kubectl -n ecommerce get svc ecommerce-service
```

### 4. Test from another device
From another computer on the same network:
```bash
# Linux/Mac
curl -I http://192.168.207.128:31224

# Windows PowerShell
Invoke-WebRequest -Uri http://192.168.207.128:31224 -Method Head

# Or just open in browser:
http://192.168.207.128:31224
```

### 5. Check if VM IP changed (DHCP)
If you can't connect after reboot, the VM might have a new IP:
```bash
hostname -I
```

---

## Network Architecture

```
Other Devices                VM Host                    Minikube
  (Phone,                  (192.168.207.128)         (192.168.49.2)
   Laptop)                       |                          |
      |                          |                          |
      |-----> :31224 -----> Firewall -----> :31224 -----> NodePort
                                 |                          |
                                 |                          |
                            VM Network                  K8s Service
                          (192.168.207.0/24)          (LoadBalancer)
                                                            |
                                                            v
                                                       ecommerce-app
                                                         (Pods)
```

### Flow:
1. External device connects to VM IP on port 31224
2. VM firewall allows traffic on port 31224
3. Traffic reaches Minikube on the bridge network
4. Kubernetes NodePort service forwards to the app pods
5. App responds back through the same path

---

## Static IP Configuration (Optional)

If your VM gets a new IP after reboot, you can set a static IP:

### Check current network settings
```bash
nmcli connection show
```

### Set static IP (example)
```bash
sudo nmcli connection modify ens160 ipv4.addresses 192.168.207.128/24
sudo nmcli connection modify ens160 ipv4.gateway 192.168.207.2
sudo nmcli connection modify ens160 ipv4.dns "8.8.8.8 8.8.4.4"
sudo nmcli connection modify ens160 ipv4.method manual
sudo nmcli connection down ens160 && sudo nmcli connection up ens160
```

---

## Security Notes

⚠️ **Important Security Considerations:**

1. **Firewall is now open** - The app is accessible from any device on your local network
2. **No HTTPS** - Traffic is unencrypted (HTTP only)
3. **No authentication firewall** - Anyone on the network can access it
4. **Production use** - If deploying to production:
   - Use HTTPS with SSL certificates
   - Configure proper firewall rules
   - Use authentication/authorization
   - Consider using an Ingress controller with proper security

### Recommended for Production:
- Set up Nginx Ingress with SSL
- Use Let's Encrypt for certificates
- Configure network policies in Kubernetes
- Add rate limiting and DDoS protection
- Use a proper firewall with allowlists

---

## Quick Reference

| What | Command/URL |
|------|-------------|
| **Access from VM** | `http://192.168.49.2:31224` |
| **Access from network** | `http://192.168.207.128:31224` |
| **Get VM IP** | `hostname -I \| awk '{print $1}'` |
| **Check firewall** | `sudo firewall-cmd --list-ports` |
| **Open port** | `sudo firewall-cmd --permanent --add-port=31224/tcp && sudo firewall-cmd --reload` |
| **Close port** | `sudo firewall-cmd --permanent --remove-port=31224/tcp && sudo firewall-cmd --reload` |
| **Check service** | `kubectl -n ecommerce get svc` |
| **Minikube IP** | `minikube ip` |

---

## Testing from Different Devices

### From a Phone (Same WiFi Network)
1. Open browser on phone
2. Go to: `http://192.168.207.128:31224`
3. You should see the ecommerce application

### From Another Laptop (Same Network)
```bash
# Test connectivity
ping 192.168.207.128

# Test the application
curl http://192.168.207.128:31224
```

### From Windows Computer
```powershell
# Open PowerShell and test
Test-NetConnection -ComputerName 192.168.207.128 -Port 31224

# Or open in browser
Start-Process "http://192.168.207.128:31224"
```

---

## Current Status ✅

- ✅ Application running in Kubernetes
- ✅ NodePort service configured (31224)
- ✅ Firewall port 31224 opened
- ✅ VM IP: 192.168.207.128
- ✅ Minikube IP: 192.168.49.2
- ✅ Access from other devices: **ENABLED**

**You can now access the application from any device on your network at:**
## `http://192.168.207.128:31224`
