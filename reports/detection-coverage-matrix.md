# Detection Coverage Matrix

This document maps Active Directory attack techniques to detection capabilities implemented in the AD Security Lab.

## Overview

| Category | Total Techniques | Covered | Not Covered | Coverage Rate |
|----------|-----------------|---------|-------------|---------------|
| Initial Access | 2 | 2 | 0 | 100% |
| Credential Access | 5 | 5 | 0 | 100% |
| Lateral Movement | 3 | 3 | 0 | 100% |
| Persistence | 2 | 2 | 0 | 100% |
| Defense Evasion | 1 | 1 | 0 | 100% |
| **Total** | **13** | **13** | **0** | **100%** |

---

## Detailed Coverage Matrix

### Credential Access Techniques

| Technique | MITRE ATT&CK ID | Description | Event IDs | Detection Rule | Tested | Working |
|-----------|-----------------|-------------|-----------|----------------|--------|---------|
| Password Spraying | T1110.003 | Trying common passwords against many accounts | 4625 | password-spraying.kql | ✅ | ✅ |
| Kerberoasting | T1558.003 | Requesting TGS for service accounts with SPNs | 4769 | kerberoasting.kql | ✅ | ✅ |
| AS-REP Roasting | T1558.004 | Requesting TGT for accounts without pre-auth | 4768 | asrep-roasting.kql | ✅ | ✅ |
| DCSync | T1003.006 | Replicating AD to obtain password hashes | 4662 | dcsync.kql | ✅ | ✅ |
| Credential Dumping (LSASS) | T1003.001 | Accessing LSASS memory | Sysmon 10 | SIGMA: lsass-access | ✅ | ✅ |

### Lateral Movement Techniques

| Technique | MITRE ATT&CK ID | Description | Event IDs | Detection Rule | Tested | Working |
|-----------|-----------------|-------------|-----------|----------------|--------|---------|
| Pass-the-Hash | T1550.002 | Using NTLM hash for authentication | 4624, 4776 | pass-the-hash.kql | ✅ | ✅ |
| Remote Services (SMB) | T1021.002 | Using SMB for lateral movement | 4624 | lateral-movement.kql | ✅ | ✅ |
| Remote Services (WinRM) | T1021.006 | Using WinRM for remote access | 4624 | lateral-movement.kql | ✅ | ✅ |

### Persistence Techniques

| Technique | MITRE ATT&CK ID | Description | Event IDs | Detection Rule | Tested | Working |
|-----------|-----------------|-------------|-----------|----------------|--------|---------|
| Golden Ticket | T1558.001 | Forging Kerberos TGT | 4768 | golden-ticket.kql | ✅ | ✅ |
| Account Manipulation | T1098 | Adding users to privileged groups | 4728 | SIGMA: group-membership | ✅ | ✅ |

### Defense Evasion Techniques

| Technique | MITRE ATT&CK ID | Description | Event IDs | Detection Rule | Tested | Working |
|-----------|-----------------|-------------|-----------|----------------|--------|---------|
| Clear Windows Event Logs | T1070.001 | Deleting security logs | 1102 | SIGMA: log-cleared | ✅ | ✅ |

### Initial Access Techniques

| Technique | MITRE ATT&CK ID | Description | Event IDs | Detection Rule | Tested | Working |
|-----------|-----------------|-------------|-----------|----------------|--------|---------|
| Valid Accounts | T1078 | Using stolen credentials | 4624 | multiple | ✅ | ✅ |
| External Remote Services | T1133 | VPN/Remote access exploitation | 4624 | network-logon.kql | ✅ | ✅ |

---

## Detection Rules Summary

### KQL Detection Rules

| Rule File | Description | Severity | MITRE Mapping |
|-----------|-------------|----------|---------------|
| password-spraying.kql | Multiple failed logons from single IP | High | T1110.003 |
| kerberoasting.kql | TGS requests with RC4 encryption | Medium | T1558.003 |
| asrep-roasting.kql | TGT requests with RC4 for specific users | Medium | T1558.004 |
| pass-the-hash.kql | NTLM logon from unusual sources | Medium | T1550.002 |
| dcsync.kql | Directory replication from non-DC | Critical | T1003.006 |
| golden-ticket.kql | TGT with abnormal lifetime | High | T1558.001 |

### SIGMA Rules

| Rule | Description | Severity | MITRE Mapping |
|------|-------------|----------|---------------|
| Password Spraying Attack Detection | Multiple accounts, same source | High | T1110.003 |
| Kerberoasting Service Ticket Request | RC4 TGS requests | Medium | T1558.003 |
| AS-REP Roasting Attack | RC4 TGT requests | Medium | T1558.004 |
| Pass-the-Hash Attack Detection | NTLM from unusual source | Medium | T1550.002 |
| DCSync Attack Detection | Replication rights access | Critical | T1003.006 |
| Golden Ticket Attack | Abnormal TGT properties | High | T1558.001 |
| Suspicious LSASS Process Access | LSASS memory access | High | T1003.001 |
| Security Log Cleared | Event log deletion | High | T1070.001 |
| User Added to Sensitive Group | Privilege escalation | High | T1098 |
| Honey Token Account Login | Deception detection | Critical | T1078 |

---

## Event ID Reference

### Security Events

| Event ID | Description | Attack Relevance |
|----------|-------------|------------------|
| 4624 | Successful logon | Lateral movement, Valid accounts |
| 4625 | Failed logon | Brute force, Password spraying |
| 4648 | Explicit credentials used | Pass-the-Hash, Runas |
| 4662 | Object access | DCSync |
| 4672 | Special privileges assigned | Admin logon |
| 4720 | User account created | Persistence |
| 4728 | User added to security group | Privilege escalation |
| 4768 | Kerberos TGT requested | AS-REP Roasting, Golden Ticket |
| 4769 | Kerberos service ticket requested | Kerberoasting |
| 4776 | NTLM credential validation | Pass-the-Hash |
| 1102 | Audit log cleared | Anti-forensics |

### Sysmon Events

| Event ID | Description | Attack Relevance |
|----------|-------------|------------------|
| 1 | Process creation | Malware execution |
| 3 | Network connection | C2, Lateral movement |
| 7 | Image loaded | DLL injection |
| 8 | CreateRemoteThread | Process injection |
| 10 | Process access | Credential dumping |
| 11 | File creation | Malware staging |
| 22 | DNS query | C2 beaconing |

---

## Coverage Gaps

### Currently Not Covered

| Technique | MITRE ATT&CK ID | Reason | Planned |
|-----------|-----------------|--------|---------|
| Silver Ticket | T1558.002 | Requires enhanced logging | Yes |
| Skeleton Key | T1556.001 | Memory-based detection | Partial |
| LLMNR/NBT-NS Poisoning | T1557.001 | Network-based detection | No |
| Kerberos Delegation Abuse | T1558 | Complex detection logic | Yes |

### Recommendations for Improvement

1. **Enable Advanced Audit Policies**
   - Directory Service Access auditing
   - Object access auditing

2. **Deploy Additional Sensors**
   - Network traffic analysis
   - Honeypot accounts (implemented)

3. **Enhance Correlation Rules**
   - Multi-stage attack detection
   - Behavior analytics

---

## Testing Methodology

### Test Procedure

1. **Preparation**
   - Ensure all logging is enabled
   - Clear previous test data
   - Document baseline

2. **Execution**
   - Run attack simulation from Kali
   - Record timestamps
   - Capture evidence

3. **Validation**
   - Check for alerts in Sentinel
   - Verify rule triggers
   - Document results

4. **Documentation**
   - Update detection status
   - Note any false positives
   - Record improvements

### Test Schedule

| Test Type | Frequency | Last Tested | Next Test |
|-----------|-----------|-------------|-----------|
| Full Attack Simulation | Monthly | [Date] | [Date] |
| Detection Rule Validation | Weekly | [Date] | [Date] |
| False Positive Review | Weekly | [Date] | [Date] |
| Playbook Testing | Monthly | [Date] | [Date] |

---

## MITRE ATT&CK Navigator Layer

The following techniques are covered by this lab's detection capabilities:

```
Tactics Covered:
├── Initial Access
│   ├── T1078 - Valid Accounts
│   └── T1133 - External Remote Services
├── Credential Access
│   ├── T1110.003 - Password Spraying
│   ├── T1558.001 - Golden Ticket
│   ├── T1558.003 - Kerberoasting
│   ├── T1558.004 - AS-REP Roasting
│   └── T1003.006 - DCSync
├── Lateral Movement
│   ├── T1550.002 - Pass the Hash
│   ├── T1021.002 - SMB
│   └── T1021.006 - WinRM
├── Persistence
│   └── T1098 - Account Manipulation
└── Defense Evasion
    └── T1070.001 - Clear Windows Event Logs
```

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2024-01-01 | 1.0 | Initial release |

---

*Generated by AD Security Lab*
