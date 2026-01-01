# Active Directory Security Lab - Setup Guide

This comprehensive guide covers the complete setup of the AD Attack & Defense Lab environment.

## Table of Contents
1. [Hardware/Software Requirements](#hardwaresoftware-requirements)
2. [Virtual Machines Overview](#virtual-machines-overview)
3. [Network Configuration](#network-configuration)
4. [Domain Controller Setup (DC01)](#domain-controller-setup-dc01)
5. [Workstation Setup (WS01, WS02)](#workstation-setup-ws01-ws02)
6. [Sysmon Installation](#sysmon-installation)
7. [Kali Linux Setup](#kali-linux-setup)
8. [Azure Sentinel Integration](#azure-sentinel-integration)

---

## Hardware/Software Requirements

| Component   | Minimum Specs     | Recommended        |
|-------------|-------------------|--------------------|
| RAM         | 16 GB             | 32 GB              |
| Storage     | 100 GB SSD        | 250 GB SSD         |
| CPU         | 4 cores           | 8 cores            |
| Hypervisor  | VirtualBox (free) | VMware Workstation Pro |

---

## Virtual Machines Overview

| VM Name | OS                       | Role                  | RAM   | Storage |
|---------|--------------------------|----------------------|-------|---------|
| DC01    | Windows Server 2019/2022 | Domain Controller    | 4 GB  | 60 GB   |
| WS01    | Windows 10 Enterprise    | Workstation (Admin)  | 4 GB  | 50 GB   |
| WS02    | Windows 10 Enterprise    | Workstation (User)   | 4 GB  | 50 GB   |
| KALI    | Kali Linux 2024          | Attacker Machine     | 4 GB  | 40 GB   |

---

## Network Configuration

```
Network Type: NAT Network or Internal Network
Network Name: AD-Lab
Subnet: 192.168.1.0/24
Gateway: 192.168.1.1

Static IPs:
- DC01: 192.168.1.100
- WS01: 192.168.1.101
- WS02: 192.168.1.102
- KALI: 192.168.1.10
```

### VirtualBox Network Setup
1. Open VirtualBox → File → Host Network Manager
2. Create a new Host-Only Network or NAT Network
3. Set subnet to 192.168.1.0/24
4. Assign this network to all VMs

---

## Domain Controller Setup (DC01)

### Step 1: Install Windows Server 2019/2022
1. Download evaluation ISO from [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/)
2. Create VM with 4GB RAM, 60GB storage
3. Install Windows Server 2019/2022 Standard (Desktop Experience)
4. Set administrator password during installation

### Step 2: Configure Static IP
```powershell
# Open PowerShell as Administrator
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.100 -PrefixLength 24 -DefaultGateway 192.168.1.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 127.0.0.1
```

### Step 3: Rename Computer
```powershell
Rename-Computer -NewName "DC01" -Restart
```

### Step 4: Install AD DS and Promote to Domain Controller
Run the setup script: `scripts/setup/01-dc-setup.ps1`

Or manually:
```powershell
# Install AD DS Role
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Promote to Domain Controller
Install-ADDSForest `
    -DomainName "yourcompany.local" `
    -DomainNetbiosName "YOURCOMPANY" `
    -InstallDNS:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
    -Force:$true
```

### Step 5: Create Organizational Units
After reboot, run: `scripts/setup/02-create-users.ps1`

---

## Workstation Setup (WS01, WS02)

### Step 1: Install Windows 10
1. Use evaluation ISO or your own license
2. Create VM with 4GB RAM, 50GB storage
3. Install Windows 10 Enterprise

### Step 2: Configure Network
```powershell
# On WS01
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.101 -PrefixLength 24 -DefaultGateway 192.168.1.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.1.100

# On WS02
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.102 -PrefixLength 24 -DefaultGateway 192.168.1.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.1.100
```

### Step 3: Rename Computers
```powershell
# On WS01
Rename-Computer -NewName "WS01" -Restart

# On WS02
Rename-Computer -NewName "WS02" -Restart
```

### Step 4: Join Domain
```powershell
Add-Computer -DomainName "yourcompany.local" -Credential (Get-Credential) -Restart
```

### Step 5: Configure Local Admin (WS01 only)
This simulates a common misconfiguration:
```powershell
# On WS01, add domain user as local admin
Add-LocalGroupMember -Group "Administrators" -Member "YOURCOMPANY\jsmith"
```

---

## Sysmon Installation

Install Sysmon on all Windows machines (DC01, WS01, WS02) using `scripts/setup/04-install-sysmon.ps1`

Or manually:
```powershell
# Download Sysmon
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "C:\Sysmon.zip"
Expand-Archive -Path "C:\Sysmon.zip" -DestinationPath "C:\Sysmon"

# Download SwiftOnSecurity Sysmon config
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "C:\Sysmon\sysmonconfig.xml"

# Install Sysmon with config
C:\Sysmon\Sysmon64.exe -accepteula -i C:\Sysmon\sysmonconfig.xml
```

### Verify Sysmon Installation
```powershell
Get-Service Sysmon64
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5
```

---

## Kali Linux Setup

### Step 1: Install Kali Linux
1. Download from [Kali Downloads](https://www.kali.org/get-kali/)
2. Create VM with 4GB RAM, 40GB storage
3. Install Kali Linux (default installation)

### Step 2: Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### Step 3: Install Attack Tools
```bash
sudo apt install -y \
    bloodhound \
    neo4j \
    crackmapexec \
    evil-winrm \
    impacket-scripts \
    responder \
    seclists \
    nmap \
    enum4linux
```

### Step 4: Configure Static IP
Edit `/etc/network/interfaces`:
```
auto eth0
iface eth0 inet static
    address 192.168.1.10
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 192.168.1.100
```

Or using NetworkManager:
```bash
sudo nmcli connection modify "Wired connection 1" \
    ipv4.addresses 192.168.1.10/24 \
    ipv4.gateway 192.168.1.1 \
    ipv4.dns 192.168.1.100 \
    ipv4.method manual
```

### Step 5: Verify Connectivity
```bash
ping 192.168.1.100  # Should reach DC01
nslookup yourcompany.local 192.168.1.100
```

---

## Azure Sentinel Integration

### Step 1: Prerequisites
- Azure subscription
- Log Analytics workspace
- Azure Arc (for on-premises servers)

### Step 2: Install Azure Arc Agent
On DC01 and workstations, download and install the Azure Connected Machine agent:
```powershell
# Download from Azure Portal or use the automated script
# Navigate to: Azure Portal → Azure Arc → Servers → Add
```

### Step 3: Configure Windows Event Collection
Create Data Collection Rules in Azure Sentinel to collect:
- Security events (4624, 4625, 4648, 4672, 4768, 4769, 4776)
- System events
- Sysmon/Operational
- PowerShell/Operational
- Windows Defender/Operational

### Step 4: Verify Log Ingestion
```kql
SecurityEvent
| where TimeGenerated > ago(1h)
| summarize count() by EventID
```

---

## Verification Checklist

- [ ] DC01 is running as Domain Controller
- [ ] DNS is functioning (nslookup works from workstations)
- [ ] WS01 and WS02 are domain-joined
- [ ] All machines have Sysmon installed and running
- [ ] Kali can reach all Windows machines
- [ ] Logs are appearing in Azure Sentinel (if configured)

---

## Troubleshooting

### Common Issues

**Domain join fails:**
- Verify DNS is pointing to DC01 (192.168.1.100)
- Ensure time sync is correct
- Check firewall rules

**Sysmon not logging:**
- Verify service is running: `Get-Service Sysmon64`
- Check Event Viewer: Applications and Services Logs → Microsoft → Windows → Sysmon

**Network connectivity issues:**
- Verify all VMs are on the same virtual network
- Check Windows Firewall settings
- Ping test between machines

---

*Next: See [Attack Playbook](attack-playbook.md) for attack simulations*
