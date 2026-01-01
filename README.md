# Active Directory Security Lab — Attack Simulation & Detection

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![MITRE ATT&CK](https://img.shields.io/badge/MITRE%20ATT%26CK-Framework-red)](https://attack.mitre.org/)

A comprehensive Active Directory security lab for simulating real-world attacks and building detection capabilities. Integrated with Azure Sentinel for centralized monitoring and alerting.

## 🎯 Objectives

- Build a realistic enterprise Active Directory environment
- Simulate real-world attack techniques (MITRE ATT&CK mapped)
- Create and validate detection rules (KQL & SIGMA)
- Implement SOAR playbooks for automated response
- Document attack paths and defensive measures

## 🖥️ Lab Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ATTACK NETWORK                           │
│  ┌─────────────┐                                                │
│  │  Kali Linux │ ← Attacker Machine                            │
│  │ 192.168.1.10│                                                │
│  └──────┬──────┘                                                │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              CORPORATE NETWORK (Target)                  │   │
│  │                                                          │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │ Domain      │  │ Windows 10  │  │ Windows 10  │      │   │
│  │  │ Controller  │  │ Workstation │  │ Workstation │      │   │
│  │  │ (DC01)      │  │ (WS01)      │  │ (WS02)      │      │   │
│  │  │ 192.168.1.100  192.168.1.101│  │ 192.168.1.102│      │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘      │   │
│  │         │                │                │              │   │
│  │         └────────────────┼────────────────┘              │   │
│  │                          │                               │   │
│  │                          ▼                               │   │
│  │                 ┌─────────────────┐                      │   │
│  │                 │  Azure Sentinel │                      │   │
│  │                 │  (SIEM)         │                      │   │
│  │                 └─────────────────┘                      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Repository Structure

```
📁 active_directory_security_lab/
├── README.md                          # Project overview (this file)
├── docs/
│   ├── lab-setup-guide.md            # Step-by-step setup instructions
│   ├── architecture-diagram.md       # Detailed network diagrams
│   └── attack-playbook.md            # Attack simulation procedures
├── scripts/
│   ├── setup/
│   │   ├── 01-dc-setup.ps1           # Domain Controller configuration
│   │   ├── 02-create-users.ps1       # User and OU creation
│   │   ├── 03-create-vulns.ps1       # Intentional vulnerabilities
│   │   └── 04-install-sysmon.ps1     # Sysmon deployment
│   └── attacks/
│       ├── recon.sh                  # Reconnaissance commands
│       ├── password-spray.sh         # Password spraying attacks
│       └── lateral-movement.sh       # Lateral movement & Kerberos attacks
├── detections/
│   ├── kql-queries/
│   │   ├── password-spraying.kql     # Password spray detection
│   │   ├── kerberoasting.kql         # Kerberoasting detection
│   │   ├── asrep-roasting.kql        # AS-REP roasting detection
│   │   ├── pass-the-hash.kql         # Pass-the-Hash detection
│   │   ├── dcsync.kql                # DCSync attack detection
│   │   └── golden-ticket.kql         # Golden Ticket detection
│   └── sigma-rules/
│       └── ad-attacks.yml            # SIGMA detection rules
├── playbooks/
│   ├── disable-compromised-user.json # Auto-disable compromised accounts
│   ├── block-malicious-ip.json       # Auto-block malicious IPs
│   └── enrich-with-threat-intel.json # IOC enrichment playbook
├── reports/
│   ├── attack-analysis-report.md     # Attack analysis template
│   └── detection-coverage-matrix.md  # Detection coverage documentation
└── screenshots/
    └── (attack/detection screenshots)
```

## 🚀 Quick Start

### Prerequisites

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 16 GB | 32 GB |
| Storage | 100 GB SSD | 250 GB SSD |
| CPU | 4 cores | 8 cores |
| Hypervisor | VirtualBox | VMware Workstation |

### Setup Steps

1. **Create Virtual Machines**
   ```
   DC01: Windows Server 2019/2022 - 4GB RAM, 60GB Storage
   WS01: Windows 10 Enterprise - 4GB RAM, 50GB Storage
   WS02: Windows 10 Enterprise - 4GB RAM, 50GB Storage
   KALI: Kali Linux 2024 - 4GB RAM, 40GB Storage
   ```

2. **Configure Domain Controller**
   ```powershell
   # Run on DC01 as Administrator
   .\scripts\setup\01-dc-setup.ps1
   # After reboot
   .\scripts\setup\02-create-users.ps1
   .\scripts\setup\03-create-vulns.ps1
   .\scripts\setup\04-install-sysmon.ps1
   ```

3. **Join Workstations to Domain**
   ```powershell
   Add-Computer -DomainName "yourcompany.local" -Credential (Get-Credential) -Restart
   ```

4. **Setup Kali Linux**
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y bloodhound crackmapexec impacket-scripts evil-winrm
   ```

5. **Run Attack Simulations**
   ```bash
   cd scripts/attacks
   ./recon.sh
   ./password-spray.sh
   ./lateral-movement.sh
   ```

## 🔓 Attack Techniques Covered

| Attack | MITRE ATT&CK | Detection Rule | Status |
|--------|--------------|----------------|--------|
| Password Spraying | T1110.003 | password-spraying.kql | ✅ |
| Kerberoasting | T1558.003 | kerberoasting.kql | ✅ |
| AS-REP Roasting | T1558.004 | asrep-roasting.kql | ✅ |
| Pass-the-Hash | T1550.002 | pass-the-hash.kql | ✅ |
| DCSync | T1003.006 | dcsync.kql | ✅ |
| Golden Ticket | T1558.001 | golden-ticket.kql | ✅ |

## 🛡️ Detection Capabilities

### KQL Detection Rules

Located in `detections/kql-queries/`:
- Real-time detection queries for Azure Sentinel
- Mapped to MITRE ATT&CK techniques
- Tested and validated in lab environment

### SIGMA Rules

Located in `detections/sigma-rules/`:
- Platform-agnostic detection rules
- Convertible to multiple SIEM formats
- Community-standard format

## 🤖 SOAR Playbooks

Automated incident response playbooks:

1. **Disable Compromised User** - Automatically disable accounts when high-severity alerts trigger
2. **Block Malicious IP** - Enrich IPs with threat intel and block if malicious
3. **Enrich with Threat Intel** - Auto-enrich IOCs using VirusTotal

## 📊 Key Event IDs

| Event ID | Description | Attack Relevance |
|----------|-------------|------------------|
| 4624 | Successful logon | Lateral movement tracking |
| 4625 | Failed logon | Brute force/spray detection |
| 4768 | Kerberos TGT request | AS-REP Roasting, Golden Ticket |
| 4769 | Kerberos TGS request | Kerberoasting |
| 4662 | Directory service access | DCSync detection |
| 4776 | NTLM authentication | Pass-the-Hash |

## 📚 Documentation

- [Lab Setup Guide](docs/lab-setup-guide.md) - Complete setup instructions
- [Architecture Diagram](docs/architecture-diagram.md) - Network and domain structure
- [Attack Playbook](docs/attack-playbook.md) - Step-by-step attack procedures
- [Detection Coverage Matrix](reports/detection-coverage-matrix.md) - MITRE coverage mapping

## ⚠️ Disclaimer

**This lab is for educational purposes only.** Only use these techniques in authorized environments. Unauthorized access to computer systems is illegal.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

Built for cybersecurity portfolio by [@oznekcyber](https://github.com/oznekcyber)

## 🙏 Acknowledgments

- [MITRE ATT&CK](https://attack.mitre.org/) - Attack framework
- [SwiftOnSecurity](https://github.com/SwiftOnSecurity/sysmon-config) - Sysmon configuration
- [SigmaHQ](https://github.com/SigmaHQ/sigma) - Detection rules
- [Impacket](https://github.com/fortra/impacket) - Attack tools

---

**Happy Hacking! 🎯**
