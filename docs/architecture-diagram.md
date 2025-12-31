# Active Directory Lab - Architecture Diagram

## Network Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ACTIVE DIRECTORY LAB                               │
│                       Network: 192.168.1.0/24                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         ATTACK NETWORK                               │    │
│  │                                                                      │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │                     KALI LINUX                               │    │    │
│  │  │                  (Attacker Machine)                          │    │    │
│  │  │                                                              │    │    │
│  │  │  IP: 192.168.1.10                                           │    │    │
│  │  │  Hostname: kali                                              │    │    │
│  │  │                                                              │    │    │
│  │  │  Tools:                                                      │    │    │
│  │  │  ├── Impacket (GetUserSPNs, secretsdump, psexec)            │    │    │
│  │  │  ├── CrackMapExec (SMB enumeration, spraying)               │    │    │
│  │  │  ├── BloodHound (AD path analysis)                          │    │    │
│  │  │  ├── Responder (LLMNR/NBT-NS poisoning)                     │    │    │
│  │  │  ├── Evil-WinRM (WinRM shell access)                        │    │    │
│  │  │  ├── Nmap (network scanning)                                │    │    │
│  │  │  └── Hashcat (password cracking)                            │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  │                              │                                       │    │
│  │                              │ Attack Traffic                        │    │
│  │                              ▼                                       │    │
│  └──────────────────────────────┼───────────────────────────────────────┘    │
│                                 │                                            │
│  ┌──────────────────────────────┼───────────────────────────────────────┐    │
│  │                         CORPORATE NETWORK (Target)                    │    │
│  │                                                                       │    │
│  │     ┌────────────────────────┴────────────────────────┐              │    │
│  │     │                    Switch                        │              │    │
│  │     └────────┬────────────────┬────────────────┬──────┘              │    │
│  │              │                │                │                      │    │
│  │              ▼                ▼                ▼                      │    │
│  │  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐            │    │
│  │  │     DC01       │ │     WS01       │ │     WS02       │            │    │
│  │  │ Domain         │ │ Workstation    │ │ Workstation    │            │    │
│  │  │ Controller     │ │ (Admin)        │ │ (User)         │            │    │
│  │  │                │ │                │ │                │            │    │
│  │  │ 192.168.1.100  │ │ 192.168.1.101  │ │ 192.168.1.102  │            │    │
│  │  │                │ │                │ │                │            │    │
│  │  │ Services:      │ │ Users:         │ │ Users:         │            │    │
│  │  │ ├── AD DS      │ │ ├── jsmith     │ │ ├── jdoe       │            │    │
│  │  │ ├── DNS        │ │ │   (Local     │ │ │   (Standard  │            │    │
│  │  │ ├── DHCP       │ │ │   Admin)     │ │ │   User)      │            │    │
│  │  │ ├── GPO        │ │ └── admin.user │ │ └── bwilson    │            │    │
│  │  │ └── Sysmon     │ │                │ │                │            │    │
│  │  │                │ │ ├── Sysmon     │ │ ├── Sysmon     │            │    │
│  │  │ Vulnerabilities│ │ │              │ │ │              │            │    │
│  │  │ ├── Weak       │ │ └── Vuln:      │ │ └── Vuln:      │            │    │
│  │  │ │   passwords  │ │     Domain     │ │     AS-REP    │            │    │
│  │  │ ├── Kerber-    │ │     user is    │ │     Roasting  │            │    │
│  │  │ │   oastable   │ │     local      │ │     (bwilson) │            │    │
│  │  │ │   SPN        │ │     admin      │ │                │            │    │
│  │  │ └── svc_sql    │ │                │ │                │            │    │
│  │  └────────────────┘ └────────────────┘ └────────────────┘            │    │
│  │              │                │                │                      │    │
│  │              └────────────────┼────────────────┘                      │    │
│  │                               │                                       │    │
│  │                               ▼ Log Forwarding                        │    │
│  │                     ┌──────────────────────┐                          │    │
│  │                     │    Azure Sentinel    │                          │    │
│  │                     │       (SIEM)         │                          │    │
│  │                     │                      │                          │    │
│  │                     │ ├── Log Analytics    │                          │    │
│  │                     │ ├── Detection Rules  │                          │    │
│  │                     │ ├── Workbooks        │                          │    │
│  │                     │ └── SOAR Playbooks   │                          │    │
│  │                     └──────────────────────┘                          │    │
│  │                                                                       │    │
│  └───────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Domain Structure

```
yourcompany.local (Domain)
│
├── Corp (OU)
│   │
│   ├── Users (OU)
│   │   ├── jsmith (John Smith) - Password123!
│   │   ├── jdoe (Jane Doe) - Summer2024!
│   │   └── bwilson (Bob Wilson) - Welcome1! [ASREP-ROASTABLE]
│   │
│   ├── Admins (OU)
│   │   └── admin.user (Admin User) - AdminP@ss1! [DOMAIN ADMIN]
│   │
│   ├── Service Accounts (OU)
│   │   └── svc_sql (SQL Service) - SQLService123! [KERBEROASTABLE]
│   │       └── SPN: MSSQLSvc/sql.yourcompany.local:1433
│   │
│   ├── Computers (OU)
│   │   ├── WS01
│   │   └── WS02
│   │
│   └── Groups (OU)
│       ├── IT Admins
│       │   └── Member: admin.user
│       ├── HR Team
│       │   └── Member: jsmith
│       └── Finance Team
│           └── Member: jdoe
│
└── Domain Controllers (OU)
    └── DC01
```

---

## Attack Paths

```
                              Attack Path Visualization
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                               │
│  [Kali]                                                                       │
│    │                                                                          │
│    ├──1──► Reconnaissance (nmap, enum4linux, bloodhound)                     │
│    │        └── Discover: users, computers, shares, SPNs                      │
│    │                                                                          │
│    ├──2──► Password Spraying (crackmapexec)                                  │
│    │        └── Compromise: jsmith:Password123!                               │
│    │                                                                          │
│    ├──3──► Kerberoasting (GetUserSPNs)                                       │
│    │        └── Get svc_sql hash → Crack → SQLService123!                    │
│    │                                                                          │
│    ├──4──► AS-REP Roasting (GetNPUsers)                                      │
│    │        └── Get bwilson hash → Crack → Welcome1!                          │
│    │                                                                          │
│    ├──5──► Lateral Movement (psexec, evil-winrm)                             │
│    │        └── jsmith → WS01 (local admin)                                   │
│    │                                                                          │
│    ├──6──► Privilege Escalation                                              │
│    │        └── WS01 → Mimikatz → admin.user hash                            │
│    │                                                                          │
│    ├──7──► Domain Compromise (secretsdump)                                   │
│    │        └── DCSync → All password hashes                                  │
│    │                                                                          │
│    └──8──► Persistence (Golden Ticket)                                       │
│             └── Create persistent access with krbtgt hash                     │
│                                                                               │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Detection Points

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DETECTION COVERAGE MAP                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Attack Technique          │ Event IDs    │ Detection Rule                  │
│  ─────────────────────────┼──────────────┼────────────────────────────────  │
│                            │              │                                  │
│  Network Reconnaissance    │ 4625 (many)  │ port-scanning.kql               │
│                            │              │                                  │
│  Password Spraying         │ 4625 (multi) │ password-spraying.kql           │
│                            │              │                                  │
│  Kerberoasting             │ 4769 (RC4)   │ kerberoasting.kql               │
│                            │              │                                  │
│  AS-REP Roasting           │ 4768 (RC4)   │ asrep-roasting.kql              │
│                            │              │                                  │
│  Pass-the-Hash             │ 4624 (NTLM)  │ pass-the-hash.kql               │
│                            │              │                                  │
│  DCSync                    │ 4662 (Repl)  │ dcsync.kql                      │
│                            │              │                                  │
│  Golden Ticket             │ 4768 (long)  │ golden-ticket.kql               │
│                            │              │                                  │
│  Credential Dumping        │ Sysmon 10    │ credential-access.kql           │
│                            │              │                                  │
│  Lateral Movement          │ 4648, 4624   │ lateral-movement.kql            │
│                            │              │                                  │
│  Privilege Escalation      │ 4672, 4728   │ privilege-escalation.kql        │
│                            │              │                                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Log Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              LOG COLLECTION FLOW                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐                             │
│  │   DC01   │     │   WS01   │     │   WS02   │                             │
│  │          │     │          │     │          │                             │
│  │ ┌──────┐ │     │ ┌──────┐ │     │ ┌──────┐ │                             │
│  │ │Sysmon│ │     │ │Sysmon│ │     │ │Sysmon│ │                             │
│  │ └──┬───┘ │     │ └──┬───┘ │     │ └──┬───┘ │                             │
│  │    │     │     │    │     │     │    │     │                             │
│  │ ┌──┴───┐ │     │ ┌──┴───┐ │     │ ┌──┴───┐ │                             │
│  │ │Event │ │     │ │Event │ │     │ │Event │ │                             │
│  │ │Logs  │ │     │ │Logs  │ │     │ │Logs  │ │                             │
│  │ └──┬───┘ │     │ └──┬───┘ │     │ └──┬───┘ │                             │
│  └────┼─────┘     └────┼─────┘     └────┼─────┘                             │
│       │                │                │                                    │
│       └────────────────┼────────────────┘                                    │
│                        │                                                     │
│                        ▼                                                     │
│              ┌─────────────────────┐                                         │
│              │   Azure Arc Agent   │                                         │
│              │  (Log Forwarding)   │                                         │
│              └─────────┬───────────┘                                         │
│                        │                                                     │
│                        ▼                                                     │
│              ┌─────────────────────┐                                         │
│              │   Log Analytics     │                                         │
│              │     Workspace       │                                         │
│              └─────────┬───────────┘                                         │
│                        │                                                     │
│                        ▼                                                     │
│              ┌─────────────────────┐                                         │
│              │   Azure Sentinel    │                                         │
│              │                     │                                         │
│              │ ┌─────────────────┐ │                                         │
│              │ │ Analytics Rules │ │                                         │
│              │ │  (KQL Queries)  │ │                                         │
│              │ └────────┬────────┘ │                                         │
│              │          │          │                                         │
│              │          ▼          │                                         │
│              │ ┌─────────────────┐ │                                         │
│              │ │    Incidents    │ │                                         │
│              │ └────────┬────────┘ │                                         │
│              │          │          │                                         │
│              │          ▼          │                                         │
│              │ ┌─────────────────┐ │                                         │
│              │ │SOAR Playbooks   │ │                                         │
│              │ │ (Auto Response) │ │                                         │
│              │ └─────────────────┘ │                                         │
│              └─────────────────────┘                                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Ports and Protocols

| Port | Protocol | Service | Description |
|------|----------|---------|-------------|
| 53 | TCP/UDP | DNS | Domain Name System |
| 88 | TCP/UDP | Kerberos | Authentication |
| 135 | TCP | RPC | Remote Procedure Call |
| 139 | TCP | NetBIOS | Session service |
| 389 | TCP/UDP | LDAP | Directory services |
| 445 | TCP | SMB | File sharing |
| 636 | TCP | LDAPS | LDAP over SSL |
| 3268 | TCP | Global Catalog | AD global catalog |
| 3389 | TCP | RDP | Remote Desktop |
| 5985 | TCP | WinRM HTTP | PowerShell remoting |
| 5986 | TCP | WinRM HTTPS | PowerShell remoting (SSL) |

---

*For attack simulations, see [Attack Playbook](attack-playbook.md)*
