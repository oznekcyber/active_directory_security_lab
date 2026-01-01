# Attack Analysis Report

## Executive Summary

This document provides an analysis of attack simulations performed in the Active Directory Security Lab environment. The purpose is to validate detection capabilities and identify gaps in security monitoring.

**Lab Environment:**
- Domain: yourcompany.local
- Domain Controller: DC01 (192.168.1.100)
- Workstations: WS01, WS02 (192.168.1.101-102)
- Attacker Machine: Kali Linux (192.168.1.10)

**Assessment Date:** [YYYY-MM-DD]
**Assessor:** [Name]

---

## 1. Attack Simulations Performed

### 1.1 Network Reconnaissance

| Metric | Value |
|--------|-------|
| Attack Start Time | [HH:MM:SS] |
| Attack End Time | [HH:MM:SS] |
| Tools Used | nmap, crackmapexec, enum4linux |
| Detection Status | ☐ Detected / ☐ Not Detected |

**Attack Description:**
Network scanning and enumeration to discover hosts, open ports, and services in the target environment.

**Commands Executed:**
```bash
nmap -sn 192.168.1.0/24
nmap -sV -sC -p- 192.168.1.100
crackmapexec smb 192.168.1.100 --shares
```

**Detection Analysis:**
- [ ] Event ID 4625 (failed logons) observed
- [ ] Multiple connection attempts logged
- [ ] Firewall logs captured scanning activity

**Findings:**
[Document what was discovered and any detection gaps]

---

### 1.2 Password Spraying

| Metric | Value |
|--------|-------|
| Attack Start Time | [HH:MM:SS] |
| Attack End Time | [HH:MM:SS] |
| Target Users | [Number] |
| Passwords Tested | [Number] |
| Successful Credentials | [Number] |
| Detection Status | ☐ Detected / ☐ Not Detected |

**Attack Description:**
Attempted authentication with common passwords against multiple user accounts to identify weak credentials.

**Commands Executed:**
```bash
crackmapexec smb 192.168.1.100 -u users.txt -p passwords.txt --continue-on-success
```

**Compromised Accounts:**
| Username | Password | Risk Level |
|----------|----------|------------|
| jsmith | Password123! | Medium |
| [user] | [password] | [level] |

**Detection Analysis:**
- [ ] KQL rule triggered: password-spraying.kql
- [ ] SIGMA rule triggered: Password Spraying Attack Detection
- [ ] Sentinel incident created

**Findings:**
[Document detection timing, accuracy, and any gaps]

---

### 1.3 AS-REP Roasting

| Metric | Value |
|--------|-------|
| Attack Start Time | [HH:MM:SS] |
| Vulnerable Users Found | [Number] |
| Hashes Obtained | [Number] |
| Hashes Cracked | [Number] |
| Detection Status | ☐ Detected / ☐ Not Detected |

**Attack Description:**
Exploited accounts configured without Kerberos pre-authentication to obtain crackable password hashes.

**Commands Executed:**
```bash
impacket-GetNPUsers yourcompany.local/ -usersfile users.txt -dc-ip 192.168.1.100 -format hashcat -outputfile asrep_hashes.txt
hashcat -m 18200 asrep_hashes.txt /usr/share/wordlists/rockyou.txt
```

**Vulnerable Accounts:**
| Username | Pre-Auth Disabled | Hash Cracked |
|----------|------------------|--------------|
| bwilson | Yes | Yes - Welcome1! |

**Detection Analysis:**
- [ ] Event ID 4768 with RC4 encryption observed
- [ ] KQL rule triggered: asrep-roasting.kql
- [ ] Sentinel alert generated

**Findings:**
[Document detection capabilities and recommendations]

---

### 1.4 Kerberoasting

| Metric | Value |
|--------|-------|
| Attack Start Time | [HH:MM:SS] |
| SPNs Discovered | [Number] |
| Service Tickets Obtained | [Number] |
| Hashes Cracked | [Number] |
| Detection Status | ☐ Detected / ☐ Not Detected |

**Attack Description:**
Requested Kerberos service tickets for accounts with SPNs to obtain crackable password hashes.

**Commands Executed:**
```bash
impacket-GetUserSPNs yourcompany.local/jsmith:Password123! -dc-ip 192.168.1.100 -outputfile kerberoast_hashes.txt
hashcat -m 13100 kerberoast_hashes.txt /usr/share/wordlists/rockyou.txt
```

**Kerberoasted Accounts:**
| Service Account | SPN | Password Cracked |
|-----------------|-----|------------------|
| svc_sql | MSSQLSvc/sql.yourcompany.local:1433 | Yes - SQLService123! |

**Detection Analysis:**
- [ ] Event ID 4769 with RC4 encryption observed
- [ ] KQL rule triggered: kerberoasting.kql
- [ ] Anomaly in TGS request volume detected

**Findings:**
[Document detection timing and recommendations]

---

### 1.5 Lateral Movement

| Metric | Value |
|--------|-------|
| Attack Start Time | [HH:MM:SS] |
| Technique Used | Pass-the-Hash / WinRM / PsExec |
| Source Host | [Hostname] |
| Target Host(s) | [Hostname(s)] |
| Success Rate | [%] |
| Detection Status | ☐ Detected / ☐ Not Detected |

**Attack Description:**
Used compromised credentials to move laterally through the network and access additional systems.

**Commands Executed:**
```bash
impacket-psexec yourcompany.local/jsmith:Password123!@192.168.1.101
evil-winrm -i 192.168.1.101 -u jsmith -p 'Password123!'
```

**Access Obtained:**
| Target | Method | Access Level |
|--------|--------|--------------|
| WS01 | Local Admin | Administrator |

**Detection Analysis:**
- [ ] Event ID 4624 (logon) observed
- [ ] Event ID 4648 (explicit credentials) observed
- [ ] NTLM authentication from unusual source detected

**Findings:**
[Document lateral movement detection capabilities]

---

### 1.6 DCSync Attack

| Metric | Value |
|--------|-------|
| Attack Start Time | [HH:MM:SS] |
| Account Used | [Username] |
| Hashes Extracted | [Number] |
| Detection Status | ☐ Detected / ☐ Not Detected |

**Attack Description:**
Impersonated a Domain Controller to request password hash replication from the actual DC.

**Commands Executed:**
```bash
impacket-secretsdump yourcompany.local/admin.user:AdminP@ss1!@192.168.1.100
```

**Extracted Credentials:**
| Account Type | Count |
|--------------|-------|
| Domain Users | [Number] |
| Service Accounts | [Number] |
| Computer Accounts | [Number] |
| krbtgt | 1 |

**Detection Analysis:**
- [ ] Event ID 4662 with replication rights observed
- [ ] KQL rule triggered: dcsync.kql
- [ ] Critical alert generated

**Findings:**
[Document DCSync detection and response capabilities]

---

### 1.7 Golden Ticket

| Metric | Value |
|--------|-------|
| Attack Start Time | [HH:MM:SS] |
| krbtgt Hash Used | Yes/No |
| Ticket Created | Yes/No |
| Persistence Achieved | Yes/No |
| Detection Status | ☐ Detected / ☐ Not Detected |

**Attack Description:**
Created a forged Kerberos TGT using the krbtgt hash to obtain persistent domain access.

**Commands Executed:**
```bash
impacket-ticketer -nthash <krbtgt_hash> -domain-sid <SID> -domain yourcompany.local administrator
export KRB5CCNAME=administrator.ccache
impacket-psexec yourcompany.local/administrator@dc01.yourcompany.local -k -no-pass
```

**Detection Analysis:**
- [ ] Abnormal TGT lifetime detected
- [ ] KQL rule triggered: golden-ticket.kql
- [ ] TGS without corresponding TGT observed

**Findings:**
[Document Golden Ticket detection challenges and recommendations]

---

## 2. Detection Summary

### Detection Coverage Matrix

| Attack Technique | MITRE ATT&CK | Events Generated | Rule Triggered | Alert Created | Time to Detect |
|-----------------|--------------|------------------|----------------|---------------|----------------|
| Password Spraying | T1110.003 | 4625 | Yes/No | Yes/No | [minutes] |
| AS-REP Roasting | T1558.004 | 4768 | Yes/No | Yes/No | [minutes] |
| Kerberoasting | T1558.003 | 4769 | Yes/No | Yes/No | [minutes] |
| Pass-the-Hash | T1550.002 | 4624, 4648 | Yes/No | Yes/No | [minutes] |
| DCSync | T1003.006 | 4662 | Yes/No | Yes/No | [minutes] |
| Golden Ticket | T1558.001 | 4768 | Yes/No | Yes/No | [minutes] |

### Detection Rate
- **Total Attacks:** [Number]
- **Detected:** [Number]
- **Not Detected:** [Number]
- **Detection Rate:** [%]

---

## 3. Gaps and Recommendations

### Critical Gaps

1. **[Gap Title]**
   - Description: [Details]
   - Risk: High/Medium/Low
   - Recommendation: [Action required]

2. **[Gap Title]**
   - Description: [Details]
   - Risk: High/Medium/Low
   - Recommendation: [Action required]

### Recommended Improvements

| Priority | Improvement | Effort | Impact |
|----------|-------------|--------|--------|
| High | [Description] | [Low/Med/High] | [Low/Med/High] |
| Medium | [Description] | [Low/Med/High] | [Low/Med/High] |
| Low | [Description] | [Low/Med/High] | [Low/Med/High] |

---

## 4. SOAR Playbook Validation

| Playbook | Trigger Condition | Executed | Actions Completed | Time to Respond |
|----------|-------------------|----------|-------------------|-----------------|
| Disable Compromised User | High-severity alert | Yes/No | [%] | [seconds] |
| Block Malicious IP | Multiple failed logons | Yes/No | [%] | [seconds] |
| Enrich with Threat Intel | Any incident | Yes/No | [%] | [seconds] |

---

## 5. Conclusion

[Summary of overall security posture, key findings, and next steps]

---

## Appendix A: Evidence Screenshots

[Include relevant screenshots of alerts, incidents, and detections]

## Appendix B: Log Samples

[Include sample log entries for each detected attack]

## Appendix C: Tool Versions

| Tool | Version |
|------|---------|
| Sysmon | [Version] |
| Kali Linux | [Version] |
| CrackMapExec | [Version] |
| Impacket | [Version] |
| Hashcat | [Version] |

---

*Report generated by AD Security Lab*
