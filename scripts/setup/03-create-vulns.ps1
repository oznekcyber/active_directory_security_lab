#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Configures intentional vulnerabilities for the AD Security Lab.

.DESCRIPTION
    This script sets up common misconfigurations and vulnerabilities
    that are often found in enterprise AD environments for testing
    detection capabilities.

.NOTES
    File Name      : 03-create-vulns.ps1
    Author         : AD Security Lab
    Prerequisite   : Must run on Domain Controller after user creation
    WARNING        : This creates intentional vulnerabilities - LAB USE ONLY!
    
.EXAMPLE
    .\03-create-vulns.ps1
#>

# Import Active Directory module
Import-Module ActiveDirectory -ErrorAction Stop

$DomainName = (Get-ADDomain).DNSRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AD Security Lab - Vulnerability Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING: This script creates intentional vulnerabilities!" -ForegroundColor Red
Write-Host "         FOR LAB/TESTING PURPOSES ONLY!" -ForegroundColor Red
Write-Host ""

# ============================================
# Vulnerability 1: AS-REP Roasting
# ============================================
Write-Host "[*] Configuring Vulnerability 1: AS-REP Roasting..." -ForegroundColor Yellow

try {
    # Set "Do not require Kerberos preauthentication" for bwilson
    Set-ADAccountControl -Identity "bwilson" -DoesNotRequirePreAuth $true
    
    Write-Host "[+] Enabled 'Do not require Kerberos preauthentication' for bwilson" -ForegroundColor Green
    Write-Host "    Attack: impacket-GetNPUsers $DomainName/ -usersfile users.txt -dc-ip <DC_IP>" -ForegroundColor Gray
}
catch {
    Write-Host "[!] Error configuring AS-REP Roasting: $_" -ForegroundColor Red
}

# ============================================
# Vulnerability 2: Kerberoasting (already done with SPN)
# ============================================
Write-Host ""
Write-Host "[*] Verifying Vulnerability 2: Kerberoasting (SPN on svc_sql)..." -ForegroundColor Yellow

try {
    $SvcUser = Get-ADUser -Identity "svc_sql" -Properties ServicePrincipalNames
    
    if ($SvcUser.ServicePrincipalNames.Count -gt 0) {
        Write-Host "[+] svc_sql has SPN configured: $($SvcUser.ServicePrincipalNames -join ', ')" -ForegroundColor Green
        Write-Host "    Attack: impacket-GetUserSPNs $DomainName/jsmith:Password123! -dc-ip <DC_IP>" -ForegroundColor Gray
    } else {
        # Add SPN if missing
        Set-ADUser -Identity "svc_sql" -ServicePrincipalNames @{Add="MSSQLSvc/sql.$($DomainName):1433"}
        Write-Host "[+] Added SPN to svc_sql" -ForegroundColor Green
    }
}
catch {
    Write-Host "[!] Error verifying Kerberoasting setup: $_" -ForegroundColor Red
}

# ============================================
# Vulnerability 3: Weak Passwords (already set)
# ============================================
Write-Host ""
Write-Host "[*] Vulnerability 3: Weak Passwords configured during user creation" -ForegroundColor Yellow
Write-Host "[+] Weak passwords in use:" -ForegroundColor Green
Write-Host "    - jsmith: Password123!" -ForegroundColor Gray
Write-Host "    - jdoe: Summer2024!" -ForegroundColor Gray
Write-Host "    - bwilson: Welcome1!" -ForegroundColor Gray
Write-Host "    - svc_sql: SQLService123!" -ForegroundColor Gray

# ============================================
# Vulnerability 4: Password Never Expires
# ============================================
Write-Host ""
Write-Host "[*] Verifying Vulnerability 4: Password Never Expires..." -ForegroundColor Yellow

$Users = @("jsmith", "jdoe", "bwilson", "admin.user", "svc_sql")

foreach ($User in $Users) {
    try {
        Set-ADUser -Identity $User -PasswordNeverExpires $true
        Write-Host "[+] Password never expires: $User" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error setting password policy for ${User}: $_" -ForegroundColor Red
    }
}

# ============================================
# Vulnerability 5: Constrained Delegation (Optional)
# ============================================
Write-Host ""
Write-Host "[*] Configuring Vulnerability 5: Unconstrained Delegation..." -ForegroundColor Yellow

try {
    # Enable unconstrained delegation on service account
    # This is a high-risk vulnerability
    Set-ADAccountControl -Identity "svc_sql" -TrustedForDelegation $true
    
    Write-Host "[+] Enabled Unconstrained Delegation for svc_sql" -ForegroundColor Green
    Write-Host "    Risk: Any service running as svc_sql can impersonate any user" -ForegroundColor Gray
}
catch {
    Write-Host "[!] Error configuring delegation: $_" -ForegroundColor Red
}

# ============================================
# Vulnerability 6: Reversible Encryption
# ============================================
Write-Host ""
Write-Host "[*] Configuring Vulnerability 6: Reversible Encryption Storage..." -ForegroundColor Yellow

try {
    # Enable reversible encryption for one user (bad practice)
    Set-ADUser -Identity "jsmith" -AllowReversiblePasswordEncryption $true
    
    # Need to reset password to take effect
    $NewPassword = ConvertTo-SecureString "Password123!" -AsPlainText -Force
    Set-ADAccountPassword -Identity "jsmith" -NewPassword $NewPassword -Reset
    
    Write-Host "[+] Enabled reversible encryption for jsmith" -ForegroundColor Green
    Write-Host "    Risk: Password can be retrieved in plaintext from DC" -ForegroundColor Gray
}
catch {
    Write-Host "[!] Error configuring reversible encryption: $_" -ForegroundColor Red
}

# ============================================
# Vulnerability 7: Guest Account Enabled
# ============================================
Write-Host ""
Write-Host "[*] Configuring Vulnerability 7: Guest Account..." -ForegroundColor Yellow

try {
    # Enable guest account (common misconfiguration)
    Enable-ADAccount -Identity "Guest"
    
    Write-Host "[+] Enabled Guest account" -ForegroundColor Green
    Write-Host "    Risk: Anonymous access to domain resources" -ForegroundColor Gray
}
catch {
    Write-Host "[!] Guest account configuration: $_" -ForegroundColor Yellow
}

# ============================================
# Vulnerability 8: AdminSDHolder Weakness
# ============================================
Write-Host ""
Write-Host "[*] Note: Additional vulnerabilities to configure manually:" -ForegroundColor Yellow
Write-Host "    - GPP Passwords (Group Policy Preferences)" -ForegroundColor Gray
Write-Host "    - LLMNR/NBT-NS enabled (default on Windows)" -ForegroundColor Gray
Write-Host "    - SMB Signing not required (default in many environments)" -ForegroundColor Gray
Write-Host "    - PrintNightmare vulnerable services" -ForegroundColor Gray

# ============================================
# Vulnerability 9: Create Honey Tokens
# ============================================
Write-Host ""
Write-Host "[*] Creating Honey Token accounts for detection..." -ForegroundColor Yellow

$DomainDN = (Get-ADDomain).DistinguishedName

try {
    # Create a fake admin account as a honey token
    $HoneyUser = Get-ADUser -Filter "SamAccountName -eq 'svc_backup'" -ErrorAction SilentlyContinue
    
    if ($null -eq $HoneyUser) {
        $SecurePassword = ConvertTo-SecureString "H0n3yT0k3n!" -AsPlainText -Force
        
        New-ADUser `
            -Name "Backup Service" `
            -SamAccountName "svc_backup" `
            -UserPrincipalName "svc_backup@$DomainName" `
            -Path "OU=Service Accounts,OU=Corp,$DomainDN" `
            -AccountPassword $SecurePassword `
            -Enabled $true `
            -PasswordNeverExpires $true `
            -Description "HONEY TOKEN - Backup Service Account" `
            -ChangePasswordAtLogon $false
        
        Write-Host "[+] Created honey token: svc_backup" -ForegroundColor Green
        Write-Host "    Any login attempt to this account should trigger an alert!" -ForegroundColor Gray
    } else {
        Write-Host "[=] Honey token already exists: svc_backup" -ForegroundColor Gray
    }
}
catch {
    Write-Host "[!] Error creating honey token: $_" -ForegroundColor Red
}

# ============================================
# Summary
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Vulnerability Setup Completed        " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configured Vulnerabilities:" -ForegroundColor Yellow
Write-Host "  [1] AS-REP Roasting: bwilson" -ForegroundColor White
Write-Host "  [2] Kerberoasting: svc_sql (SPN configured)" -ForegroundColor White
Write-Host "  [3] Weak Passwords: All test users" -ForegroundColor White
Write-Host "  [4] Password Never Expires: All test users" -ForegroundColor White
Write-Host "  [5] Unconstrained Delegation: svc_sql" -ForegroundColor White
Write-Host "  [6] Reversible Encryption: jsmith" -ForegroundColor White
Write-Host "  [7] Guest Account: Enabled" -ForegroundColor White
Write-Host "  [8] Honey Token: svc_backup" -ForegroundColor White
Write-Host ""
Write-Host "REMINDER: These vulnerabilities are for TESTING ONLY!" -ForegroundColor Red
Write-Host "          Never deploy in production environments!" -ForegroundColor Red
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Run 04-install-sysmon.ps1 to enable detection logging" -ForegroundColor White
Write-Host "2. Configure Azure Sentinel for log collection" -ForegroundColor White
Write-Host "3. Test detection rules from Kali Linux" -ForegroundColor White
Write-Host ""
