#!/bin/bash

###########################################
# Security Verification Script
# Purpose: Verify that only ports 22, 80, 443 are accessible externally
###########################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Security Verification Report${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Get VM IP address
VM_IP=$(hostname -I | awk '{print $1}')
echo -e "${BLUE}VM IP Address: ${VM_IP}${NC}"
echo ""

# 1. Check firewall status
echo -e "${YELLOW}[1/6] Firewall Status${NC}"
if systemctl is-active --quiet firewalld; then
    echo -e "  ${GREEN}✓ Firewalld is active${NC}"
    echo ""
    echo "  Public Zone Configuration:"
    sudo firewall-cmd --zone=public --list-all | sed 's/^/    /'
else
    echo -e "  ${RED}✗ Firewalld is not active${NC}"
fi
echo ""

# 2. Check open ports from external perspective
echo -e "${YELLOW}[2/6] Externally Accessible Ports (0.0.0.0)${NC}"
echo "  Ports listening on all interfaces:"
sudo ss -tlnp | grep "0.0.0.0" | grep -v "127.0.0.1" | awk '{print "    " $4 " - " $6}' | sort -u
echo ""

# 3. Verify only required ports are open
echo -e "${YELLOW}[3/6] Port Accessibility Check${NC}"
REQUIRED_PORTS=("22" "80" "443")
for port in "${REQUIRED_PORTS[@]}"; do
    if sudo ss -tlnp | grep -q ":$port "; then
        echo -e "  ${GREEN}✓ Port $port is listening${NC}"
    else
        echo -e "  ${RED}✗ Port $port is NOT listening${NC}"
    fi
done
echo ""

# 4. Check for unintended open ports
echo -e "${YELLOW}[4/6] Checking for Unintended Exposed Ports${NC}"
BLOCKED_PORTS=("3306" "5432" "6379" "8080" "9000" "25" "1025" "8025")
ISSUES=0
for port in "${BLOCKED_PORTS[@]}"; do
    if sudo ss -tlnp | grep "0.0.0.0:$port " | grep -v docker-proxy; then
        echo -e "  ${RED}⚠ WARNING: Port $port is exposed on 0.0.0.0${NC}"
        ISSUES=$((ISSUES + 1))
    fi
done
if [ $ISSUES -eq 0 ]; then
    echo -e "  ${GREEN}✓ No unintended ports exposed to external network${NC}"
fi
echo ""

# 5. Docker security check
echo -e "${YELLOW}[5/6] Docker Security Check${NC}"
if command -v docker &> /dev/null; then
    echo "  Running containers:"
    docker ps --format "    {{.Names}} - {{.Ports}}" 2>/dev/null || echo "    No running containers"
    echo ""
    
    # Check if Docker daemon is exposed
    if sudo ss -tlnp | grep -q "0.0.0.0:2375\|0.0.0.0:2376"; then
        echo -e "  ${RED}✗ WARNING: Docker daemon is exposed${NC}"
    else
        echo -e "  ${GREEN}✓ Docker daemon is not exposed externally${NC}"
    fi
else
    echo "  Docker not installed"
fi
echo ""

# 6. SSH Security Check
echo -e "${YELLOW}[6/6] SSH Security Configuration${NC}"
if [ -f "/etc/ssh/sshd_config" ]; then
    echo "  Current settings:"
    
    PERMIT_ROOT=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')
    if [ "$PERMIT_ROOT" = "no" ]; then
        echo -e "    ${GREEN}✓ PermitRootLogin: no${NC}"
    else
        echo -e "    ${YELLOW}⚠ PermitRootLogin: ${PERMIT_ROOT:-yes (default)}${NC}"
        echo "      Recommendation: Set to 'no' in /etc/ssh/sshd_config"
    fi
    
    PASS_AUTH=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}')
    if [ "$PASS_AUTH" = "no" ]; then
        echo -e "    ${GREEN}✓ PasswordAuthentication: no${NC}"
    else
        echo -e "    ${YELLOW}⚠ PasswordAuthentication: ${PASS_AUTH:-yes (default)}${NC}"
        echo "      Recommendation: Set to 'no' and use SSH keys"
    fi
    
    SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
    echo "    Port: ${SSH_PORT:-22 (default)}"
fi
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Security Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Count issues
CRITICAL_ISSUES=0
WARNINGS=0

# Check firewall
if ! systemctl is-active --quiet firewalld; then
    echo -e "${RED}✗ CRITICAL: Firewall is not active${NC}"
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
fi

# Check required ports
for port in 22 80 443; do
    if ! sudo ss -tlnp | grep -q ":$port "; then
        echo -e "${RED}✗ CRITICAL: Port $port is not listening${NC}"
        CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
    fi
done

# Check SSH configuration
if [ -f "/etc/ssh/sshd_config" ]; then
    PERMIT_ROOT=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')
    if [ "$PERMIT_ROOT" != "no" ]; then
        echo -e "${YELLOW}⚠ WARNING: Root login is enabled${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Check fail2ban
if ! command -v fail2ban-client &> /dev/null; then
    echo -e "${YELLOW}⚠ WARNING: fail2ban is not installed${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Final verdict
echo ""
if [ $CRITICAL_ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ SECURITY STATUS: EXCELLENT${NC}"
    echo "   All security measures are in place."
elif [ $CRITICAL_ISSUES -eq 0 ]; then
    echo -e "${YELLOW}✅ SECURITY STATUS: GOOD${NC}"
    echo "   Critical security is configured. $WARNINGS minor warnings."
else
    echo -e "${RED}❌ SECURITY STATUS: NEEDS ATTENTION${NC}"
    echo "   $CRITICAL_ISSUES critical issues found. Please address immediately."
fi
echo ""

# Recommendations
echo -e "${YELLOW}Next Steps:${NC}"
if [ $CRITICAL_ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "  1. ✓ Regularly monitor logs: sudo tail -f /var/log/secure"
    echo "  2. ✓ Keep system updated: sudo yum update -y"
    echo "  3. ✓ Regular backups: ./backup-restore.sh backup"
    echo "  4. ✓ Review access logs weekly"
else
    if ! command -v fail2ban-client &> /dev/null; then
        echo "  • Install fail2ban: sudo yum install fail2ban -y"
    fi
    if [ "$PERMIT_ROOT" != "no" ]; then
        echo "  • Disable root SSH login in /etc/ssh/sshd_config"
    fi
fi
echo ""

# Test from external machine
echo -e "${BLUE}To test from external machine:${NC}"
echo "  nc -zv $VM_IP 22    # Should connect"
echo "  nc -zv $VM_IP 80    # Should connect"
echo "  nc -zv $VM_IP 443   # Should connect"
echo "  nc -zv $VM_IP 3306  # Should timeout (blocked)"
echo "  nc -zv $VM_IP 5432  # Should timeout (blocked)"
echo ""
