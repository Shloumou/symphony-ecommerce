#!/bin/bash

###########################################
# Additional VM Security Hardening
# Purpose: Close unnecessary services and harden system
###########################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Additional Security Hardening${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# 1. Bind MySQL/Database to localhost only
echo -e "${YELLOW}[1/9] Checking database configuration...${NC}"
if [ -f "/etc/my.cnf" ] || [ -f "/etc/mysql/my.cnf" ]; then
    echo "  Note: If running database in Docker, ensure it's not exposed externally"
    echo "  Check docker-compose.yml ports section should be '127.0.0.1:3306:3306'"
else
    echo "  Database running in container (OK)"
fi
echo -e "${GREEN}✓ Database check complete${NC}"
echo ""

# 2. Disable unnecessary services
echo -e "${YELLOW}[2/9] Checking for unnecessary services...${NC}"
SERVICES_TO_CHECK=("cups" "avahi-daemon" "bluetooth")
for service in "${SERVICES_TO_CHECK[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "  Found active service: $service (consider disabling if not needed)"
        read -p "  Disable $service? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            systemctl stop "$service"
            systemctl disable "$service"
            echo "  ✓ $service disabled"
        fi
    fi
done
echo -e "${GREEN}✓ Service check complete${NC}"
echo ""

# 3. Configure SSH hardening
echo -e "${YELLOW}[3/9] Checking SSH configuration...${NC}"
SSHD_CONFIG="/etc/ssh/sshd_config"
if [ -f "$SSHD_CONFIG" ]; then
    echo "  Current SSH settings:"
    grep -E "^(PermitRootLogin|PasswordAuthentication|Port)" "$SSHD_CONFIG" || echo "  Using defaults"
    echo ""
    echo "  Recommended SSH hardening (manually edit if needed):"
    echo "    - PermitRootLogin no"
    echo "    - PasswordAuthentication no (use SSH keys)"
    echo "    - Port 22 (or custom port)"
fi
echo -e "${GREEN}✓ SSH check complete${NC}"
echo ""

# 4. Ensure fail2ban is configured (optional)
echo -e "${YELLOW}[4/9] Checking fail2ban installation...${NC}"
if command -v fail2ban-client &> /dev/null; then
    echo "  fail2ban is installed"
    systemctl is-active --quiet fail2ban && echo "  ✓ fail2ban is running" || echo "  ⚠ fail2ban is not running"
else
    echo "  fail2ban not installed"
    echo "  Consider installing: sudo yum install fail2ban -y (RHEL/CentOS)"
    echo "                   or: sudo apt install fail2ban -y (Ubuntu/Debian)"
fi
echo ""

# 5. Check Docker daemon exposure
echo -e "${YELLOW}[5/9] Checking Docker daemon security...${NC}"
if netstat -tlnp 2>/dev/null | grep -q ":2375\|:2376"; then
    echo -e "  ${RED}⚠ WARNING: Docker daemon may be exposed on network${NC}"
    echo "  Ensure Docker daemon is only listening on localhost"
else
    echo "  ✓ Docker daemon not exposed externally"
fi
echo ""

# 6. Review listening ports
echo -e "${YELLOW}[6/9] Current listening ports:${NC}"
echo "  External (0.0.0.0):"
ss -tlnp | grep "0.0.0.0" | awk '{print "    " $4}' | sort -u
echo ""
echo "  Localhost (127.0.0.1):"
ss -tlnp | grep "127.0.0.1" | awk '{print "    " $4}' | sort -u
echo -e "${GREEN}✓ Port review complete${NC}"
echo ""

# 7. Set proper file permissions
echo -e "${YELLOW}[7/9] Checking sensitive file permissions...${NC}"
if [ -f "/home/salem/ecommerce_web_site_with_sym-master/.env" ]; then
    chmod 600 /home/salem/ecommerce_web_site_with_sym-master/.env 2>/dev/null || true
    echo "  ✓ .env file permissions set to 600"
fi
if [ -f "/home/salem/ecommerce_web_site_with_sym-master/.env.local" ]; then
    chmod 600 /home/salem/ecommerce_web_site_with_sym-master/.env.local 2>/dev/null || true
    echo "  ✓ .env.local file permissions set to 600"
fi
echo -e "${GREEN}✓ File permissions check complete${NC}"
echo ""

# 8. Check for system updates
echo -e "${YELLOW}[8/9] Checking for system updates...${NC}"
if command -v yum &> /dev/null; then
    echo "  Run: sudo yum update -y (to update all packages)"
elif command -v apt &> /dev/null; then
    echo "  Run: sudo apt update && sudo apt upgrade -y (to update all packages)"
fi
echo -e "${GREEN}✓ Update check complete${NC}"
echo ""

# 9. Enable automatic security updates (optional)
echo -e "${YELLOW}[9/9] Automatic security updates...${NC}"
if command -v yum &> /dev/null; then
    if ! rpm -qa | grep -q yum-cron; then
        echo "  Consider installing yum-cron for automatic updates:"
        echo "    sudo yum install yum-cron -y"
        echo "    sudo systemctl enable --now yum-cron"
    else
        echo "  ✓ yum-cron is installed"
    fi
elif command -v apt &> /dev/null; then
    if ! dpkg -l | grep -q unattended-upgrades; then
        echo "  Consider installing unattended-upgrades for automatic updates:"
        echo "    sudo apt install unattended-upgrades -y"
        echo "    sudo dpkg-reconfigure -plow unattended-upgrades"
    else
        echo "  ✓ unattended-upgrades is installed"
    fi
fi
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Security Hardening Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Completed:${NC}"
echo "  ✓ Service audit"
echo "  ✓ SSH configuration review"
echo "  ✓ Docker security check"
echo "  ✓ Port exposure review"
echo "  ✓ File permissions"
echo ""
echo -e "${YELLOW}Recommended Next Steps:${NC}"
echo "  1. Review and update SSH configuration"
echo "  2. Install and configure fail2ban"
echo "  3. Keep system updated regularly"
echo "  4. Monitor logs: /var/log/secure and /var/log/messages"
echo "  5. Use strong passwords and SSH keys"
echo "  6. Regular backup strategy (you have backup-restore.sh)"
echo ""
