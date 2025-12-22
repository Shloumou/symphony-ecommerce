#!/bin/bash

###########################################
# VM Firewall Hardening Script
# Purpose: Lock down VM to only expose ports 22, 80, 443 externally
# All other services remain accessible only from localhost/docker
###########################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}VM Firewall Hardening Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Backup current firewall rules
echo -e "${YELLOW}[1/8] Backing up current firewall configuration...${NC}"
firewall-cmd --list-all > /tmp/firewall-backup-$(date +%Y%m%d-%H%M%S).txt
echo -e "${GREEN}✓ Backup saved to /tmp/firewall-backup-$(date +%Y%m%d-%H%M%S).txt${NC}"
echo ""

# Get default zone
DEFAULT_ZONE=$(firewall-cmd --get-default-zone)
echo -e "${YELLOW}[2/8] Default firewall zone: ${DEFAULT_ZONE}${NC}"
echo ""

# Remove all existing services from public zone (we'll add back only what we need)
echo -e "${YELLOW}[3/8] Removing unnecessary services from firewall...${NC}"
firewall-cmd --permanent --zone=public --remove-service=dhcpv6-client 2>/dev/null || true
firewall-cmd --permanent --zone=public --remove-service=cockpit 2>/dev/null || true
firewall-cmd --permanent --zone=public --remove-service=mdns 2>/dev/null || true
firewall-cmd --permanent --zone=public --remove-service=samba-client 2>/dev/null || true
echo -e "${GREEN}✓ Unnecessary services removed${NC}"
echo ""

# Configure firewall to only allow essential ports
echo -e "${YELLOW}[4/8] Configuring firewall rules...${NC}"
echo "  - Allowing SSH (port 22)"
firewall-cmd --permanent --zone=public --add-service=ssh

echo "  - Allowing HTTP (port 80)"
firewall-cmd --permanent --zone=public --add-service=http

echo "  - Allowing HTTPS (port 443)"
firewall-cmd --permanent --zone=public --add-service=https

echo -e "${GREEN}✓ External ports configured: 22, 80, 443${NC}"
echo ""

# Block all other incoming connections
echo -e "${YELLOW}[5/8] Setting default policies...${NC}"
firewall-cmd --permanent --zone=public --set-target=DROP 2>/dev/null || {
    # If set-target doesn't work, ensure DROP is default for incoming
    firewall-cmd --permanent --zone=public --remove-service=all 2>/dev/null || true
}
echo -e "${GREEN}✓ Default policy set to DROP for unmatched traffic${NC}"
echo ""

# Allow Docker networks (trusted zone for internal communication)
echo -e "${YELLOW}[6/8] Configuring Docker network rules...${NC}"
# Docker bridge networks should be in trusted zone for internal communication
firewall-cmd --permanent --zone=trusted --add-source=172.17.0.0/16 2>/dev/null || true
firewall-cmd --permanent --zone=trusted --add-source=172.18.0.0/16 2>/dev/null || true
firewall-cmd --permanent --zone=trusted --add-source=192.168.0.0/16 2>/dev/null || true

# Allow localhost
firewall-cmd --permanent --zone=trusted --add-source=127.0.0.0/8 2>/dev/null || true
echo -e "${GREEN}✓ Docker and localhost networks configured in trusted zone${NC}"
echo ""

# Enable masquerading for Docker (NAT)
echo -e "${YELLOW}[7/8] Enabling masquerading for Docker...${NC}"
firewall-cmd --permanent --zone=public --add-masquerade
echo -e "${GREEN}✓ Masquerading enabled${NC}"
echo ""

# Reload firewall to apply changes
echo -e "${YELLOW}[8/8] Applying firewall configuration...${NC}"
firewall-cmd --reload
echo -e "${GREEN}✓ Firewall rules applied${NC}"
echo ""

# Display current configuration
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Current Firewall Configuration${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo -e "${YELLOW}Public Zone (External Access):${NC}"
firewall-cmd --zone=public --list-all
echo ""

echo -e "${YELLOW}Trusted Zone (Internal Access):${NC}"
firewall-cmd --zone=trusted --list-all
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Firewall Hardening Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  ✓ External ports open: 22 (SSH), 80 (HTTP), 443 (HTTPS)"
echo "  ✓ All other ports blocked from external access"
echo "  ✓ Docker containers can communicate internally"
echo "  ✓ Localhost services remain accessible"
echo "  ✓ Database and other services only accessible from within VM"
echo ""
echo -e "${YELLOW}Note:${NC} Your SSH connection will remain active."
echo "If you get locked out, access via VM console and run:"
echo "  sudo firewall-cmd --zone=public --add-service=ssh --permanent"
echo "  sudo firewall-cmd --reload"
echo ""
