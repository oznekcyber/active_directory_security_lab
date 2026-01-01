#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Domain Controller setup script for AD Security Lab.

.DESCRIPTION
    This script installs Active Directory Domain Services and promotes the server
    to a Domain Controller for the yourcompany.local domain.

.NOTES
    File Name      : 01-dc-setup.ps1
    Author         : AD Security Lab
    Prerequisite   : Windows Server 2019/2022, Administrator rights
    
.EXAMPLE
    .\01-dc-setup.ps1
#>

# Configuration Variables
$DomainName = "yourcompany.local"
$DomainNetBIOSName = "YOURCOMPANY"
$SafeModePassword = "P@ssw0rd123!"
$DCIPAddress = "192.168.1.100"
$DCSubnetMask = 24
$Gateway = "192.168.1.1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AD Security Lab - DC Setup Script    " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if running as admin
function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

# Step 1: Configure Static IP
Write-Host "[*] Step 1: Configuring Static IP Address..." -ForegroundColor Yellow

try {
    # Get the first active network adapter
    $Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    
    if ($null -eq $Adapter) {
        Write-Host "[ERROR] No active network adapter found!" -ForegroundColor Red
        exit 1
    }

    # Remove existing IP configuration
    $Adapter | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
    $Adapter | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

    # Set static IP
    New-NetIPAddress -InterfaceIndex $Adapter.ifIndex `
        -IPAddress $DCIPAddress `
        -PrefixLength $DCSubnetMask `
        -DefaultGateway $Gateway -ErrorAction Stop

    # Set DNS to localhost (required for AD DS)
    Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses "127.0.0.1"

    Write-Host "[+] Static IP configured: $DCIPAddress" -ForegroundColor Green
}
catch {
    Write-Host "[!] Warning: Could not configure IP. May already be set." -ForegroundColor Yellow
    Write-Host "    Error: $_" -ForegroundColor Yellow
}

# Step 2: Rename Computer
Write-Host "[*] Step 2: Checking computer name..." -ForegroundColor Yellow

if ($env:COMPUTERNAME -ne "DC01") {
    Write-Host "[*] Renaming computer to DC01..." -ForegroundColor Yellow
    Rename-Computer -NewName "DC01" -Force
    Write-Host "[+] Computer renamed to DC01. A restart is required." -ForegroundColor Green
    $RestartRequired = $true
} else {
    Write-Host "[+] Computer name is already DC01" -ForegroundColor Green
}

# Step 3: Install AD DS Role
Write-Host "[*] Step 3: Installing AD Domain Services role..." -ForegroundColor Yellow

try {
    $ADDSFeature = Get-WindowsFeature -Name AD-Domain-Services
    
    if (-not $ADDSFeature.Installed) {
        Install-WindowsFeature AD-Domain-Services -IncludeManagementTools -ErrorAction Stop
        Write-Host "[+] AD Domain Services installed successfully" -ForegroundColor Green
    } else {
        Write-Host "[+] AD Domain Services already installed" -ForegroundColor Green
    }
}
catch {
    Write-Host "[ERROR] Failed to install AD DS: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Promote to Domain Controller
Write-Host "[*] Step 4: Promoting server to Domain Controller..." -ForegroundColor Yellow
Write-Host "    Domain: $DomainName" -ForegroundColor Gray
Write-Host "    NetBIOS: $DomainNetBIOSName" -ForegroundColor Gray

try {
    # Check if already a DC
    $DCCheck = Get-ADDomainController -ErrorAction SilentlyContinue
    
    if ($null -ne $DCCheck) {
        Write-Host "[+] Server is already a Domain Controller for $($DCCheck.Domain)" -ForegroundColor Green
    } else {
        # Promote to DC
        $SecureSafeModePassword = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
        
        Install-ADDSForest `
            -DomainName $DomainName `
            -DomainNetbiosName $DomainNetBIOSName `
            -InstallDNS:$true `
            -SafeModeAdministratorPassword $SecureSafeModePassword `
            -Force:$true `
            -NoRebootOnCompletion:$false
        
        Write-Host "[+] Domain Controller promotion initiated" -ForegroundColor Green
        Write-Host "[!] Server will restart automatically" -ForegroundColor Yellow
    }
}
catch {
    # If AD cmdlets not available yet, use Import-Module
    if ($_.Exception.Message -like "*ActiveDirectory*") {
        Import-Module ADDSDeployment -ErrorAction SilentlyContinue
        
        $SecureSafeModePassword = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
        
        Install-ADDSForest `
            -DomainName $DomainName `
            -DomainNetbiosName $DomainNetBIOSName `
            -InstallDNS:$true `
            -SafeModeAdministratorPassword $SecureSafeModePassword `
            -Force:$true
    } else {
        Write-Host "[ERROR] Failed to promote to DC: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DC Setup Script Completed            " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Wait for server to restart" -ForegroundColor White
Write-Host "2. Log in as YOURCOMPANY\Administrator" -ForegroundColor White
Write-Host "3. Run 02-create-users.ps1 to create users and OUs" -ForegroundColor White
Write-Host ""
