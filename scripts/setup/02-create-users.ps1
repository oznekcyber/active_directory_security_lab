#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Creates Organizational Units, Users, and Groups for the AD Security Lab.

.DESCRIPTION
    This script creates the OU structure, user accounts with various
    vulnerability configurations, and security groups for testing.

.NOTES
    File Name      : 02-create-users.ps1
    Author         : AD Security Lab
    Prerequisite   : Must run on Domain Controller after AD DS promotion
    
.EXAMPLE
    .\02-create-users.ps1
#>

# Import Active Directory module
Import-Module ActiveDirectory -ErrorAction Stop

# Configuration
$DomainDN = (Get-ADDomain).DistinguishedName
$DomainName = (Get-ADDomain).DNSRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AD Security Lab - User Setup Script  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Domain: $DomainName" -ForegroundColor Gray
Write-Host "Domain DN: $DomainDN" -ForegroundColor Gray
Write-Host ""

# ============================================
# Step 1: Create Organizational Units
# ============================================
Write-Host "[*] Step 1: Creating Organizational Units..." -ForegroundColor Yellow

$OUs = @(
    @{ Name = "Corp"; Path = $DomainDN },
    @{ Name = "Users"; Path = "OU=Corp,$DomainDN" },
    @{ Name = "Computers"; Path = "OU=Corp,$DomainDN" },
    @{ Name = "Groups"; Path = "OU=Corp,$DomainDN" },
    @{ Name = "Admins"; Path = "OU=Corp,$DomainDN" },
    @{ Name = "Service Accounts"; Path = "OU=Corp,$DomainDN" }
)

foreach ($OU in $OUs) {
    $OUPath = "OU=$($OU.Name),$($OU.Path)"
    
    try {
        $ExistingOU = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OUPath'" -ErrorAction SilentlyContinue
        
        if ($null -eq $ExistingOU) {
            New-ADOrganizationalUnit -Name $OU.Name -Path $OU.Path -ProtectedFromAccidentalDeletion $false
            Write-Host "[+] Created OU: $($OU.Name)" -ForegroundColor Green
        } else {
            Write-Host "[=] OU already exists: $($OU.Name)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "[!] Error creating OU $($OU.Name): $_" -ForegroundColor Red
    }
}

# ============================================
# Step 2: Create Regular Users
# ============================================
Write-Host ""
Write-Host "[*] Step 2: Creating Regular Users..." -ForegroundColor Yellow

$RegularUsers = @(
    @{
        Name = "John Smith"
        SamAccountName = "jsmith"
        Password = "Password123!"
        Description = "HR Team Member"
        Title = "HR Specialist"
        Department = "Human Resources"
    },
    @{
        Name = "Jane Doe"
        SamAccountName = "jdoe"
        Password = "Summer2024!"
        Description = "Finance Team Member"
        Title = "Financial Analyst"
        Department = "Finance"
    },
    @{
        Name = "Bob Wilson"
        SamAccountName = "bwilson"
        Password = "Welcome1!"
        Description = "IT Support - AS-REP Roastable"
        Title = "IT Support Specialist"
        Department = "IT"
    }
)

$UsersPath = "OU=Users,OU=Corp,$DomainDN"

foreach ($User in $RegularUsers) {
    try {
        $ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$($User.SamAccountName)'" -ErrorAction SilentlyContinue
        
        if ($null -eq $ExistingUser) {
            $SecurePassword = ConvertTo-SecureString $User.Password -AsPlainText -Force
            
            New-ADUser `
                -Name $User.Name `
                -SamAccountName $User.SamAccountName `
                -UserPrincipalName "$($User.SamAccountName)@$DomainName" `
                -Path $UsersPath `
                -AccountPassword $SecurePassword `
                -Enabled $true `
                -PasswordNeverExpires $true `
                -Description $User.Description `
                -Title $User.Title `
                -Department $User.Department `
                -ChangePasswordAtLogon $false
            
            Write-Host "[+] Created user: $($User.SamAccountName) (Password: $($User.Password))" -ForegroundColor Green
        } else {
            Write-Host "[=] User already exists: $($User.SamAccountName)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "[!] Error creating user $($User.SamAccountName): $_" -ForegroundColor Red
    }
}

# ============================================
# Step 3: Create Admin User
# ============================================
Write-Host ""
Write-Host "[*] Step 3: Creating Admin User..." -ForegroundColor Yellow

$AdminsPath = "OU=Admins,OU=Corp,$DomainDN"

try {
    $AdminUser = Get-ADUser -Filter "SamAccountName -eq 'admin.user'" -ErrorAction SilentlyContinue
    
    if ($null -eq $AdminUser) {
        $SecurePassword = ConvertTo-SecureString "AdminP@ss1!" -AsPlainText -Force
        
        New-ADUser `
            -Name "Admin User" `
            -SamAccountName "admin.user" `
            -UserPrincipalName "admin.user@$DomainName" `
            -Path $AdminsPath `
            -AccountPassword $SecurePassword `
            -Enabled $true `
            -PasswordNeverExpires $true `
            -Description "IT Administrator - Domain Admin" `
            -Title "IT Administrator" `
            -Department "IT" `
            -ChangePasswordAtLogon $false
        
        # Add to Domain Admins
        Add-ADGroupMember -Identity "Domain Admins" -Members "admin.user"
        
        Write-Host "[+] Created admin user: admin.user (Password: AdminP@ss1!)" -ForegroundColor Green
        Write-Host "[+] Added admin.user to Domain Admins group" -ForegroundColor Green
    } else {
        Write-Host "[=] Admin user already exists: admin.user" -ForegroundColor Gray
    }
}
catch {
    Write-Host "[!] Error creating admin user: $_" -ForegroundColor Red
}

# ============================================
# Step 4: Create Service Account (Kerberoastable)
# ============================================
Write-Host ""
Write-Host "[*] Step 4: Creating Service Account (Kerberoastable)..." -ForegroundColor Yellow

$ServiceAccountsPath = "OU=Service Accounts,OU=Corp,$DomainDN"

try {
    $SvcUser = Get-ADUser -Filter "SamAccountName -eq 'svc_sql'" -ErrorAction SilentlyContinue
    
    if ($null -eq $SvcUser) {
        $SecurePassword = ConvertTo-SecureString "SQLService123!" -AsPlainText -Force
        
        New-ADUser `
            -Name "SQL Service" `
            -SamAccountName "svc_sql" `
            -UserPrincipalName "svc_sql@$DomainName" `
            -Path $ServiceAccountsPath `
            -AccountPassword $SecurePassword `
            -Enabled $true `
            -PasswordNeverExpires $true `
            -Description "SQL Server Service Account - Kerberoastable" `
            -ServicePrincipalNames "MSSQLSvc/sql.$($DomainName):1433" `
            -ChangePasswordAtLogon $false
        
        Write-Host "[+] Created service account: svc_sql (Password: SQLService123!)" -ForegroundColor Green
        Write-Host "[+] Set SPN: MSSQLSvc/sql.$($DomainName):1433 (Kerberoastable)" -ForegroundColor Green
    } else {
        # Ensure SPN is set
        Set-ADUser -Identity "svc_sql" -ServicePrincipalNames @{Add="MSSQLSvc/sql.$($DomainName):1433"}
        Write-Host "[=] Service account already exists: svc_sql" -ForegroundColor Gray
    }
}
catch {
    Write-Host "[!] Error creating service account: $_" -ForegroundColor Red
}

# ============================================
# Step 5: Create Groups
# ============================================
Write-Host ""
Write-Host "[*] Step 5: Creating Security Groups..." -ForegroundColor Yellow

$GroupsPath = "OU=Groups,OU=Corp,$DomainDN"

$Groups = @(
    @{ Name = "IT Admins"; Description = "IT Administrators Group"; Members = @("admin.user") },
    @{ Name = "HR Team"; Description = "Human Resources Team"; Members = @("jsmith") },
    @{ Name = "Finance Team"; Description = "Finance Department"; Members = @("jdoe") },
    @{ Name = "IT Support"; Description = "IT Support Team"; Members = @("bwilson") }
)

foreach ($Group in $Groups) {
    try {
        $ExistingGroup = Get-ADGroup -Filter "Name -eq '$($Group.Name)'" -ErrorAction SilentlyContinue
        
        if ($null -eq $ExistingGroup) {
            New-ADGroup `
                -Name $Group.Name `
                -GroupScope Global `
                -GroupCategory Security `
                -Path $GroupsPath `
                -Description $Group.Description
            
            Write-Host "[+] Created group: $($Group.Name)" -ForegroundColor Green
            
            # Add members
            foreach ($Member in $Group.Members) {
                Add-ADGroupMember -Identity $Group.Name -Members $Member -ErrorAction SilentlyContinue
                Write-Host "    [+] Added $Member to $($Group.Name)" -ForegroundColor Gray
            }
        } else {
            Write-Host "[=] Group already exists: $($Group.Name)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "[!] Error creating group $($Group.Name): $_" -ForegroundColor Red
    }
}

# ============================================
# Summary
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  User Setup Script Completed          " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Created Users:" -ForegroundColor Yellow
Write-Host "  - jsmith:Password123! (Regular user, HR)" -ForegroundColor White
Write-Host "  - jdoe:Summer2024! (Regular user, Finance)" -ForegroundColor White
Write-Host "  - bwilson:Welcome1! (Regular user, IT - AS-REP Roastable)" -ForegroundColor White
Write-Host "  - admin.user:AdminP@ss1! (Domain Admin)" -ForegroundColor White
Write-Host "  - svc_sql:SQLService123! (Service Account - Kerberoastable)" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Run 03-create-vulns.ps1 to configure vulnerabilities" -ForegroundColor White
Write-Host "2. Run 04-install-sysmon.ps1 to install Sysmon" -ForegroundColor White
Write-Host ""
