#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs and configures Sysmon for the AD Security Lab.

.DESCRIPTION
    This script downloads, installs, and configures Sysmon using the
    SwiftOnSecurity configuration for comprehensive endpoint logging.

.NOTES
    File Name      : 04-install-sysmon.ps1
    Author         : AD Security Lab
    Prerequisite   : Administrator rights, Internet connectivity
    
.EXAMPLE
    .\04-install-sysmon.ps1
#>

$SysmonPath = "C:\Sysmon"
$SysmonZipUrl = "https://download.sysinternals.com/files/Sysmon.zip"
$SysmonConfigUrl = "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AD Security Lab - Sysmon Installer   " -ForegroundColor Cyan
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

# ============================================
# Step 1: Check if Sysmon is already installed
# ============================================
Write-Host "[*] Step 1: Checking existing Sysmon installation..." -ForegroundColor Yellow

$SysmonService = Get-Service -Name "Sysmon*" -ErrorAction SilentlyContinue

if ($null -ne $SysmonService) {
    Write-Host "[+] Sysmon is already installed: $($SysmonService.Name)" -ForegroundColor Green
    Write-Host "    Status: $($SysmonService.Status)" -ForegroundColor Gray
    
    $UpdateConfig = Read-Host "    Do you want to update the configuration? (y/n)"
    if ($UpdateConfig -ne "y") {
        Write-Host "[*] Exiting without changes" -ForegroundColor Yellow
        exit 0
    }
}

# ============================================
# Step 2: Create Sysmon directory
# ============================================
Write-Host ""
Write-Host "[*] Step 2: Creating Sysmon directory..." -ForegroundColor Yellow

if (-not (Test-Path $SysmonPath)) {
    New-Item -ItemType Directory -Path $SysmonPath -Force | Out-Null
    Write-Host "[+] Created directory: $SysmonPath" -ForegroundColor Green
} else {
    Write-Host "[=] Directory already exists: $SysmonPath" -ForegroundColor Gray
}

# ============================================
# Step 3: Download Sysmon
# ============================================
Write-Host ""
Write-Host "[*] Step 3: Downloading Sysmon..." -ForegroundColor Yellow

$SysmonZip = "$SysmonPath\Sysmon.zip"

try {
    # Use TLS 1.2 for download
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Invoke-WebRequest -Uri $SysmonZipUrl -OutFile $SysmonZip -UseBasicParsing
    Write-Host "[+] Downloaded Sysmon to $SysmonZip" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Failed to download Sysmon: $_" -ForegroundColor Red
    Write-Host "[*] Please download manually from: https://docs.microsoft.com/sysinternals/downloads/sysmon" -ForegroundColor Yellow
    exit 1
}

# ============================================
# Step 4: Extract Sysmon
# ============================================
Write-Host ""
Write-Host "[*] Step 4: Extracting Sysmon..." -ForegroundColor Yellow

try {
    Expand-Archive -Path $SysmonZip -DestinationPath $SysmonPath -Force
    Write-Host "[+] Extracted Sysmon files" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Failed to extract Sysmon: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# Step 5: Download Sysmon configuration
# ============================================
Write-Host ""
Write-Host "[*] Step 5: Downloading Sysmon configuration (SwiftOnSecurity)..." -ForegroundColor Yellow

$SysmonConfig = "$SysmonPath\sysmonconfig.xml"

try {
    Invoke-WebRequest -Uri $SysmonConfigUrl -OutFile $SysmonConfig -UseBasicParsing
    Write-Host "[+] Downloaded configuration to $SysmonConfig" -ForegroundColor Green
}
catch {
    Write-Host "[!] Warning: Failed to download config. Creating basic config..." -ForegroundColor Yellow
    
    # Create a basic Sysmon config if download fails
    $BasicConfig = @"
<Sysmon schemaversion="4.90">
    <HashAlgorithms>md5,sha256,IMPHASH</HashAlgorithms>
    <EventFiltering>
        <!-- Log all process creations -->
        <ProcessCreate onmatch="exclude" />
        
        <!-- Log network connections -->
        <NetworkConnect onmatch="exclude" />
        
        <!-- Log file creation -->
        <FileCreate onmatch="exclude" />
        
        <!-- Log registry events -->
        <RegistryEvent onmatch="exclude" />
        
        <!-- Log process access (for Mimikatz detection) -->
        <ProcessAccess onmatch="include">
            <TargetImage condition="is">C:\Windows\system32\lsass.exe</TargetImage>
        </ProcessAccess>
        
        <!-- Log image loads -->
        <ImageLoad onmatch="include">
            <ImageLoaded condition="contains">mimikatz</ImageLoaded>
            <ImageLoaded condition="contains">kiwi</ImageLoaded>
        </ImageLoad>
    </EventFiltering>
</Sysmon>
"@
    $BasicConfig | Out-File -FilePath $SysmonConfig -Encoding UTF8
    Write-Host "[+] Created basic Sysmon configuration" -ForegroundColor Green
}

# ============================================
# Step 6: Install/Update Sysmon
# ============================================
Write-Host ""
Write-Host "[*] Step 6: Installing/Updating Sysmon..." -ForegroundColor Yellow

# Determine architecture
$SysmonExe = if ([Environment]::Is64BitOperatingSystem) {
    "$SysmonPath\Sysmon64.exe"
} else {
    "$SysmonPath\Sysmon.exe"
}

if (-not (Test-Path $SysmonExe)) {
    Write-Host "[ERROR] Sysmon executable not found: $SysmonExe" -ForegroundColor Red
    exit 1
}

try {
    if ($null -ne $SysmonService) {
        # Update existing installation
        Write-Host "[*] Updating Sysmon configuration..." -ForegroundColor Yellow
        & $SysmonExe -c $SysmonConfig 2>&1 | Out-Null
        Write-Host "[+] Sysmon configuration updated" -ForegroundColor Green
    } else {
        # Fresh installation
        Write-Host "[*] Installing Sysmon..." -ForegroundColor Yellow
        & $SysmonExe -accepteula -i $SysmonConfig 2>&1 | Out-Null
        Write-Host "[+] Sysmon installed successfully" -ForegroundColor Green
    }
}
catch {
    Write-Host "[ERROR] Failed to install/update Sysmon: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# Step 7: Verify Installation
# ============================================
Write-Host ""
Write-Host "[*] Step 7: Verifying installation..." -ForegroundColor Yellow

Start-Sleep -Seconds 2

$SysmonService = Get-Service -Name "Sysmon*" -ErrorAction SilentlyContinue

if ($null -ne $SysmonService -and $SysmonService.Status -eq "Running") {
    Write-Host "[+] Sysmon service is running" -ForegroundColor Green
    
    # Check for recent events
    try {
        $Events = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5 -ErrorAction SilentlyContinue
        
        if ($null -ne $Events) {
            Write-Host "[+] Sysmon is logging events (found $($Events.Count) recent events)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "[!] Waiting for first events to be generated..." -ForegroundColor Yellow
    }
} else {
    Write-Host "[!] Warning: Sysmon service may not be running properly" -ForegroundColor Yellow
}

# ============================================
# Step 8: Configure Additional Audit Policies
# ============================================
Write-Host ""
Write-Host "[*] Step 8: Configuring Windows Audit Policies..." -ForegroundColor Yellow

# Enable advanced audit policies for better detection
$AuditPolicies = @(
    @{ Subcategory = "Logon"; Success = "enable"; Failure = "enable" },
    @{ Subcategory = "Logoff"; Success = "enable"; Failure = "disable" },
    @{ Subcategory = "Kerberos Authentication Service"; Success = "enable"; Failure = "enable" },
    @{ Subcategory = "Kerberos Service Ticket Operations"; Success = "enable"; Failure = "enable" },
    @{ Subcategory = "Directory Service Access"; Success = "enable"; Failure = "enable" },
    @{ Subcategory = "Directory Service Changes"; Success = "enable"; Failure = "enable" },
    @{ Subcategory = "Process Creation"; Success = "enable"; Failure = "disable" },
    @{ Subcategory = "Sensitive Privilege Use"; Success = "enable"; Failure = "enable" }
)

foreach ($Policy in $AuditPolicies) {
    try {
        $Cmd = "auditpol /set /subcategory:`"$($Policy.Subcategory)`" /success:$($Policy.Success) /failure:$($Policy.Failure)"
        Invoke-Expression $Cmd 2>&1 | Out-Null
        Write-Host "[+] Configured audit policy: $($Policy.Subcategory)" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Could not configure: $($Policy.Subcategory)" -ForegroundColor Yellow
    }
}

# Enable command line logging in process creation events
try {
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit"
    if (-not (Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $RegPath -Name "ProcessCreationIncludeCmdLine_Enabled" -Value 1 -Type DWord
    Write-Host "[+] Enabled command line logging in process creation events" -ForegroundColor Green
}
catch {
    Write-Host "[!] Could not enable command line logging" -ForegroundColor Yellow
}

# Enable PowerShell Script Block Logging
try {
    $PSLogPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
    if (-not (Test-Path $PSLogPath)) {
        New-Item -Path $PSLogPath -Force | Out-Null
    }
    Set-ItemProperty -Path $PSLogPath -Name "EnableScriptBlockLogging" -Value 1 -Type DWord
    Write-Host "[+] Enabled PowerShell Script Block Logging" -ForegroundColor Green
}
catch {
    Write-Host "[!] Could not enable PowerShell logging" -ForegroundColor Yellow
}

# ============================================
# Summary
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Sysmon Installation Completed        " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installed Components:" -ForegroundColor Yellow
Write-Host "  [+] Sysmon64 with SwiftOnSecurity config" -ForegroundColor White
Write-Host "  [+] Windows Audit Policies configured" -ForegroundColor White
Write-Host "  [+] Command line logging enabled" -ForegroundColor White
Write-Host "  [+] PowerShell Script Block Logging enabled" -ForegroundColor White
Write-Host ""
Write-Host "Log Locations:" -ForegroundColor Yellow
Write-Host "  - Sysmon: Microsoft-Windows-Sysmon/Operational" -ForegroundColor Gray
Write-Host "  - Security: Windows Logs\Security" -ForegroundColor Gray
Write-Host "  - PowerShell: Microsoft-Windows-PowerShell/Operational" -ForegroundColor Gray
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Yellow
Write-Host "  Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' -MaxEvents 10" -ForegroundColor Gray
Write-Host "  Get-Service Sysmon*" -ForegroundColor Gray
Write-Host "  C:\Sysmon\Sysmon64.exe -c  (show current config)" -ForegroundColor Gray
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Run this script on WS01 and WS02" -ForegroundColor White
Write-Host "2. Configure Azure Sentinel log collection" -ForegroundColor White
Write-Host "3. Import KQL detection rules" -ForegroundColor White
Write-Host ""
