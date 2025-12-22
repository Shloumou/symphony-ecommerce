# VM Security Hardening Guide

## Overview
This guide helps you lock down your VM to only expose necessary ports (22, 80, 443) to the outside world while keeping all internal services accessible within the VM.

## 🔒 Security Model

### External Access (Public Internet)
- **Port 22** (SSH) - Remote administration
- **Port 80** (HTTP) - Web server (redirects to HTTPS)
- **Port 443** (HTTPS) - Secure web server
- **ALL OTHER PORTS** - BLOCKED

### Internal Access (Localhost & Docker Networks)
- Database (PostgreSQL/MySQL)
- Application servers
- Docker containers
- Redis, MailHog, and other services

## 📋 Quick Start

### Step 1: Run Main Firewall Hardening
```bash
sudo ./harden-firewall.sh
```

This script will:
- ✅ Backup current firewall configuration
- ✅ Configure firewall to only allow ports 22, 80, 443
- ✅ Block all other incoming external traffic
- ✅ Allow Docker internal networks to communicate
- ✅ Keep localhost services accessible

### Step 2: Run Additional Hardening (Optional but Recommended)
```bash
sudo ./additional-hardening.sh
```

This script will:
- ✅ Audit running services
- ✅ Check SSH security settings
- ✅ Verify Docker daemon security
- ✅ Review all listening ports
- ✅ Set proper file permissions
- ✅ Check for security updates

## 🔍 Verification

### Check Firewall Status
```bash
# View public zone (external access)
sudo firewall-cmd --zone=public --list-all

# View trusted zone (internal access)
sudo firewall-cmd --zone=trusted --list-all

# List all active rules
sudo firewall-cmd --list-all-zones
```

### Check Open Ports
```bash
# View all listening ports
sudo ss -tlnp | grep LISTEN

# Check what's accessible from outside (should only show 22, 80, 443)
sudo nmap localhost -p 1-65535
```

### Test External Access
From another machine:
```bash
# These should work
ssh user@your-vm-ip
curl http://your-vm-ip
curl https://your-vm-ip

# These should be blocked (timeout)
telnet your-vm-ip 3306  # MySQL
telnet your-vm-ip 5432  # PostgreSQL
telnet your-vm-ip 8080  # Other services
```

## 🐳 Docker Security

### Ensure Database is Not Exposed
Your `docker-compose.yml` should NOT have:
```yaml
# ❌ BAD - Exposes to all interfaces
ports:
  - "3306:3306"

# ✅ GOOD - No ports exposed or localhost only
# Option 1: No ports section (internal only)
# Option 2: Localhost binding
ports:
  - "127.0.0.1:3306:3306"
```

### Current Configuration
Your database service is correctly configured without external port exposure, meaning:
- ✅ Database accessible from other Docker containers
- ✅ Database accessible from host via `docker exec`
- ❌ Database NOT accessible from external network

## 🔧 Service Port Mapping

| Service | Port | Accessibility | Purpose |
|---------|------|---------------|---------|
| SSH | 22 | External | Remote administration |
| HTTP | 80 | External | Web traffic (redirect to HTTPS) |
| HTTPS | 443 | External | Secure web traffic |
| PostgreSQL | 5432 | Internal only | Database |
| MySQL | 3306 | Internal only | Database (if used) |
| PHP-FPM | 9000 | Internal only | Application server |
| MailHog | 1025/8025 | Internal only | Development mail |
| Redis | 6379 | Internal only | Cache (if used) |

## 🛡️ Additional Security Measures

### 1. SSH Hardening
Edit `/etc/ssh/sshd_config`:
```bash
# Disable root login
PermitRootLogin no

# Use SSH keys only (disable password auth)
PasswordAuthentication no

# Change default port (optional)
Port 2222  # Remember to update firewall!

# Allow specific users only
AllowUsers your-username
```

After changes:
```bash
sudo systemctl restart sshd

# If you changed the port, update firewall:
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --reload
```

### 2. Install Fail2Ban (Brute Force Protection)
```bash
# RHEL/CentOS/Rocky
sudo yum install epel-release -y
sudo yum install fail2ban -y

# Ubuntu/Debian
sudo apt install fail2ban -y

# Enable and start
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

Configure fail2ban for SSH:
```bash
sudo vim /etc/fail2ban/jail.local
```

Add:
```ini
[sshd]
enabled = true
port = ssh
logpath = /var/log/secure
maxretry = 3
bantime = 3600
```

### 3. Enable SELinux (if not already)
```bash
# Check status
getenforce

# Set to enforcing
sudo setenforce 1

# Make permanent
sudo vim /etc/selinux/config
# Set: SELINUX=enforcing
```

### 4. Regular Security Updates
```bash
# RHEL/CentOS/Rocky - Enable automatic updates
sudo yum install yum-cron -y
sudo systemctl enable --now yum-cron

# Ubuntu/Debian - Enable automatic updates
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 5. Monitor Logs
```bash
# SSH authentication logs
sudo tail -f /var/log/secure

# Firewall logs
sudo tail -f /var/log/firewalld

# Web server logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## 🚨 Troubleshooting

### Locked Out of SSH
If you accidentally lock yourself out:
1. Access VM via console (VMware, VirtualBox, etc.)
2. Login locally
3. Run:
```bash
sudo firewall-cmd --zone=public --add-service=ssh --permanent
sudo firewall-cmd --reload
```

### Can't Access Website
```bash
# Check if nginx is running
sudo systemctl status nginx

# Check if firewall allows HTTP/HTTPS
sudo firewall-cmd --zone=public --list-services

# Add if missing
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload
```

### Docker Containers Can't Communicate
```bash
# Check trusted zone
sudo firewall-cmd --zone=trusted --list-all

# Add Docker networks if missing
sudo firewall-cmd --permanent --zone=trusted --add-source=172.17.0.0/16
sudo firewall-cmd --permanent --zone=trusted --add-source=172.18.0.0/16
sudo firewall-cmd --reload
```

## 📊 Firewall Management Commands

### View Configuration
```bash
# List all zones
sudo firewall-cmd --get-zones

# Get default zone
sudo firewall-cmd --get-default-zone

# List all services
sudo firewall-cmd --get-services

# View specific zone
sudo firewall-cmd --zone=public --list-all
```

### Add/Remove Services
```bash
# Add a service
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --reload

# Remove a service
sudo firewall-cmd --permanent --zone=public --remove-service=dhcpv6-client
sudo firewall-cmd --reload

# Add custom port
sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp
sudo firewall-cmd --reload
```

### Backup/Restore
```bash
# Backup current configuration
sudo firewall-cmd --list-all > firewall-backup.txt

# View backup
cat firewall-backup.txt
```

## ✅ Security Checklist

- [ ] Firewall configured (only ports 22, 80, 443 open)
- [ ] SSH hardened (no root login, key-based auth)
- [ ] Fail2ban installed and configured
- [ ] Database not exposed externally
- [ ] Docker daemon secured (not exposed)
- [ ] SELinux enabled (if applicable)
- [ ] Automatic security updates enabled
- [ ] Strong passwords or SSH keys
- [ ] Regular backups configured
- [ ] Monitoring and logging enabled
- [ ] Unnecessary services disabled
- [ ] File permissions properly set
- [ ] SSL/TLS certificates valid

## 📝 Regular Maintenance

### Weekly
- Check fail2ban logs for attacks
- Review SSH authentication logs
- Check disk space usage

### Monthly
- Review firewall logs
- Update all system packages
- Review user accounts and access
- Test backups

### Quarterly
- Review and update security policies
- Audit open ports and services
- Update SSL certificates if needed
- Security scan with tools like `nmap` or `OpenVAS`

## 🔗 Related Documentation
- [2FA Setup Guide](2FA_SETUP_GUIDE.md)
- [Backup and Restore](BACKUP_README.md)
- [Network Access Configuration](NETWORK_ACCESS.md)
- [NGINX SSL Setup](NGINX_SSL_SETUP_COMPLETE.md)

## 📞 Support
If you encounter issues:
1. Check the troubleshooting section above
2. Review logs in `/var/log/`
3. Verify firewall rules with `sudo firewall-cmd --list-all-zones`
4. Test connectivity from external machine

---
**Last Updated:** November 23, 2025
**Security Level:** Hardened Production Environment
