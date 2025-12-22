# 🔒 Firewall Quick Reference Card

## ✅ Current Security Status

**External Access (Internet → VM):**
- ✅ Port 22 (SSH) - Secure Shell access
- ✅ Port 80 (HTTP) - Web traffic
- ✅ Port 443 (HTTPS) - Secure web traffic
- ❌ All other ports - **BLOCKED**

**Internal Access (VM only):**
- Port 3306 (MySQL) - Database
- Port 8080 (App Container) - Application
- All Docker internal networks

---

## 🚀 Quick Commands

### Check Firewall Status
```bash
sudo firewall-cmd --list-all
sudo firewall-cmd --list-ports
```

### View Active Rules
```bash
sudo firewall-cmd --list-all-zones
sudo iptables -L -n -v
```

### Check Listening Ports
```bash
sudo ss -tulpn
sudo netstat -tulpn
```

### Test Security
```bash
./verify-security.sh
```

---

## 🔧 Common Operations

### Open a Port (Temporarily)
```bash
sudo firewall-cmd --add-port=8080/tcp
```

### Open a Port (Permanently)
```bash
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

### Close a Port
```bash
sudo firewall-cmd --remove-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

### Allow Specific IP
```bash
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.100" accept' --permanent
sudo firewall-cmd --reload
```

### Block Specific IP
```bash
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="1.2.3.4" reject' --permanent
sudo firewall-cmd --reload
```

---

## 🐳 Docker Network Security

### Check Docker Networks
```bash
docker network ls
docker network inspect ecommerce_web_site_with_sym-master_default
```

### Check Container Ports
```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

### Verify Internal Communication
```bash
docker exec -it <container_name> nc -zv db 3306
```

---

## 🛡️ Emergency Commands

### Block All Traffic (Panic Mode)
```bash
sudo firewall-cmd --panic-on
```

### Restore Traffic
```bash
sudo firewall-cmd --panic-off
```

### Reset Firewall to Defaults
```bash
sudo firewall-cmd --complete-reload
```

### Temporarily Disable Firewall (NOT RECOMMENDED)
```bash
sudo systemctl stop firewalld
```

### Re-enable Firewall
```bash
sudo systemctl start firewalld
```

---

## 📊 Monitoring

### Watch Live Connections
```bash
watch -n 1 'ss -tunap'
```

### Monitor Dropped Packets
```bash
sudo journalctl -u firewalld -f
```

### Check Recent SSH Attempts
```bash
sudo journalctl -u sshd | tail -50
```

### View Blocked Connection Attempts
```bash
sudo grep "DPT=" /var/log/messages | tail -20
```

---

## 🔍 Security Verification

### Test External Access
```bash
# From another machine
nmap -p 22,80,443,8080,3306 <your-vm-ip>
```

### Test Port Response
```bash
nc -zv <your-vm-ip> 80    # Should connect
nc -zv <your-vm-ip> 3306  # Should timeout/refuse
```

### Check SSH Configuration
```bash
sudo sshd -T | grep -E "port|permitrootlogin|passwordauthentication"
```

---

## 📝 Maintenance Tasks

### Weekly
- ✅ Review firewall logs: `sudo journalctl -u firewalld --since "1 week ago"`
- ✅ Check for failed SSH attempts: `sudo grep "Failed password" /var/log/secure`
- ✅ Verify service status: `sudo systemctl status firewalld docker nginx mysql`

### Monthly
- ✅ Update firewall rules if needed
- ✅ Review and update IP allowlists
- ✅ Test backup/restore procedures
- ✅ Security audit: Run `./verify-security.sh`

---

## 🆘 Troubleshooting

### Cannot Connect to Website
```bash
# Check if ports are open
sudo firewall-cmd --list-ports

# Check if web server is running
sudo systemctl status nginx
docker ps | grep nginx
```

### Cannot Access Database from App
```bash
# Check Docker network
docker network inspect <network_name>

# Test internal connectivity
docker exec -it app ping db
docker exec -it app nc -zv db 3306
```

### SSH Connection Issues
```bash
# Verify SSH port is open
sudo firewall-cmd --list-services

# Check SSH service
sudo systemctl status sshd

# View SSH logs
sudo journalctl -u sshd -n 50
```

---

## 📞 Quick Reference Numbers

| Service | Port | Access |
|---------|------|--------|
| SSH | 22 | External |
| HTTP | 80 | External |
| HTTPS | 443 | External |
| MySQL | 3306 | Internal Only |
| App | 8080 | Internal Only |

---

## ⚠️ Important Notes

1. **Never expose database port (3306) externally**
2. **Always use HTTPS in production** (443)
3. **Regular SSH key rotation recommended**
4. **Monitor logs for suspicious activity**
5. **Keep firewall rules documented**
6. **Test changes in staging first**

---

## 🔗 Related Files

- Main hardening script: `./harden-firewall.sh`
- Additional hardening: `./additional-hardening.sh`
- Security verification: `./verify-security.sh`
- Full documentation: `./SECURITY_HARDENING_COMPLETE.md`

---

**Last Updated:** November 23, 2025  
**Security Level:** High 🔒  
**Status:** Production Ready ✅
