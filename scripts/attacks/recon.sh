#!/bin/bash
#
# Reconnaissance Script for AD Security Lab
# Author: AD Security Lab
# Description: Network and AD reconnaissance from Kali Linux
#
# Usage: ./recon.sh [target_ip]
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DC_IP="${1:-192.168.1.100}"
SUBNET="192.168.1.0/24"
DOMAIN="yourcompany.local"
OUTPUT_DIR="$HOME/ad-lab-recon"

# Banner
echo -e "${BLUE}"
echo "=========================================="
echo "  AD Security Lab - Reconnaissance"
echo "=========================================="
echo -e "${NC}"

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo -e "${GREEN}[+] Output directory: $OUTPUT_DIR${NC}"
echo ""

# ============================================
# Phase 1: Network Discovery
# ============================================
echo -e "${YELLOW}[*] Phase 1: Network Discovery${NC}"
echo "--------------------------------------"

# Host discovery
echo -e "${BLUE}[*] Discovering live hosts on $SUBNET...${NC}"
nmap -sn "$SUBNET" -oN "$OUTPUT_DIR/hosts.txt" 2>/dev/null | grep -E "Nmap scan|Host is up|for"
echo ""

# ============================================
# Phase 2: Port Scanning
# ============================================
echo -e "${YELLOW}[*] Phase 2: Port Scanning${NC}"
echo "--------------------------------------"

# Quick scan of DC
echo -e "${BLUE}[*] Scanning Domain Controller ($DC_IP)...${NC}"
nmap -sV -sC -p 53,88,135,139,389,445,636,3268,3389,5985 "$DC_IP" -oN "$OUTPUT_DIR/dc_scan.txt" 2>/dev/null

echo -e "${GREEN}[+] Scan results saved to $OUTPUT_DIR/dc_scan.txt${NC}"
echo ""

# ============================================
# Phase 3: SMB Enumeration
# ============================================
echo -e "${YELLOW}[*] Phase 3: SMB Enumeration${NC}"
echo "--------------------------------------"

# Enumerate shares (null session)
echo -e "${BLUE}[*] Enumerating SMB shares (null session)...${NC}"
crackmapexec smb "$DC_IP" --shares 2>/dev/null | tee "$OUTPUT_DIR/smb_shares.txt"
echo ""

# Enumerate users
echo -e "${BLUE}[*] Attempting to enumerate users...${NC}"
crackmapexec smb "$DC_IP" --users 2>/dev/null | tee "$OUTPUT_DIR/smb_users.txt"
echo ""

# ============================================
# Phase 4: LDAP Enumeration
# ============================================
echo -e "${YELLOW}[*] Phase 4: LDAP Enumeration${NC}"
echo "--------------------------------------"

# Anonymous LDAP bind
echo -e "${BLUE}[*] Attempting anonymous LDAP query...${NC}"
ldapsearch -x -H "ldap://$DC_IP" -b "DC=yourcompany,DC=local" "(objectClass=*)" dn 2>/dev/null | head -20
echo ""

# ============================================
# Phase 5: DNS Enumeration
# ============================================
echo -e "${YELLOW}[*] Phase 5: DNS Enumeration${NC}"
echo "--------------------------------------"

echo -e "${BLUE}[*] DNS queries for $DOMAIN...${NC}"

# Get domain controllers
echo -e "  [*] Querying for domain controllers..."
dig @"$DC_IP" "_ldap._tcp.dc._msdcs.$DOMAIN" SRV 2>/dev/null | grep -A5 "ANSWER SECTION"

# Get kerberos servers
echo -e "  [*] Querying for Kerberos servers..."
dig @"$DC_IP" "_kerberos._tcp.$DOMAIN" SRV 2>/dev/null | grep -A5 "ANSWER SECTION"
echo ""

# ============================================
# Phase 6: RPC Enumeration
# ============================================
echo -e "${YELLOW}[*] Phase 6: RPC Enumeration${NC}"
echo "--------------------------------------"

echo -e "${BLUE}[*] Attempting RPC enumeration (null session)...${NC}"
# Using rpcclient with null session
echo -e "  [*] Note: Run manually for interactive session:"
echo -e "      rpcclient -U \"\" -N $DC_IP"
echo -e "      > enumdomusers"
echo -e "      > enumdomgroups"
echo ""

# ============================================
# Phase 7: Create User List for Attacks
# ============================================
echo -e "${YELLOW}[*] Phase 7: Preparing Attack Files${NC}"
echo "--------------------------------------"

# Create user wordlist
echo -e "${BLUE}[*] Creating user wordlist...${NC}"
cat > "$OUTPUT_DIR/users.txt" << 'EOF'
administrator
admin
guest
jsmith
jdoe
bwilson
admin.user
svc_sql
svc_backup
krbtgt
EOF
echo -e "${GREEN}[+] User list: $OUTPUT_DIR/users.txt${NC}"

# Create password wordlist
echo -e "${BLUE}[*] Creating password wordlist...${NC}"
cat > "$OUTPUT_DIR/passwords.txt" << 'EOF'
Password123!
Summer2024!
Welcome1!
Company2024!
AdminP@ss1!
SQLService123!
P@ssw0rd123!
Winter2024!
Spring2024!
Password1!
Password1
password
admin
EOF
echo -e "${GREEN}[+] Password list: $OUTPUT_DIR/passwords.txt${NC}"
echo ""

# ============================================
# Summary
# ============================================
echo -e "${BLUE}"
echo "=========================================="
echo "  Reconnaissance Complete"
echo "=========================================="
echo -e "${NC}"

echo -e "${YELLOW}Files created:${NC}"
ls -la "$OUTPUT_DIR/"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Review scan results in $OUTPUT_DIR/"
echo "2. Run password spray: ./password-spray.sh"
echo "3. Run Kerberos attacks: ./lateral-movement.sh"
echo ""

echo -e "${YELLOW}Manual Commands:${NC}"
echo "  # Full port scan"
echo "  nmap -sV -sC -p- $DC_IP -oN full_scan.txt"
echo ""
echo "  # BloodHound collection (requires creds)"
echo "  bloodhound-python -u USER -p 'PASS' -d $DOMAIN -ns $DC_IP -c All"
echo ""
echo "  # Enum4linux"
echo "  enum4linux -a $DC_IP"
echo ""
