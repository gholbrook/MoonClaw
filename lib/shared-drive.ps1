# MoonClaw - Shared drive setup

$script:DefaultShareName = "MoonClaw"
$script:DefaultFolderName = "MoonClaw Shared"

function Write-ShareStep {
    param([string]$Message)
    Write-Host ""
    Write-Host "  [SHARE] $Message" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * 50)) -ForegroundColor DarkGray
}

function Test-IsAdmin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function New-SharedDrive {
    param(
        [string]$ShareName = $script:DefaultShareName,
        [string]$FolderName = $script:DefaultFolderName
    )

    Write-ShareStep "Creating shared folder"

    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    $sharePath = Join-Path $desktopPath $FolderName

    # Create the folder
    if (-not (Test-Path $sharePath)) {
        New-Item -ItemType Directory -Path $sharePath -Force | Out-Null
        Write-Host "    Created folder: $sharePath" -ForegroundColor Green
    }
    else {
        Write-Host "    Folder already exists: $sharePath" -ForegroundColor Yellow
    }

    # Create subdirectories
    $subDirs = @('models', 'data', 'logs', 'config', 'exports')
    foreach ($dir in $subDirs) {
        $subPath = Join-Path $sharePath $dir
        if (-not (Test-Path $subPath)) {
            New-Item -ItemType Directory -Path $subPath -Force | Out-Null
        }
    }
    Write-Host "    Created subdirectories: $($subDirs -join ', ')" -ForegroundColor DarkGray

    # Set up SMB sharing (requires admin)
    $shareCreated = $false
    if (Test-IsAdmin) {
        try {
            $existingShare = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
            if ($existingShare) {
                Write-Host "    SMB share '$ShareName' already exists." -ForegroundColor Yellow
                $shareCreated = $true
            }
            else {
                New-SmbShare -Name $ShareName -Path $sharePath -FullAccess "$env:USERDOMAIN\$env:USERNAME" -Description "MoonClaw shared workspace" | Out-Null
                Write-Host "    SMB share created: \\$env:COMPUTERNAME\$ShareName" -ForegroundColor Green
                $shareCreated = $true
            }
        }
        catch {
            Write-Host "    Could not create SMB share: $_" -ForegroundColor Yellow
            Write-Host "    The folder is still usable locally." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "    Skipping SMB share (requires admin). Folder created locally." -ForegroundColor Yellow
        Write-Host "    Re-run as Administrator to enable network sharing." -ForegroundColor Yellow
    }

    # Write a readme
    $readmePath = Join-Path $sharePath "README.txt"
    if (-not (Test-Path $readmePath)) {
        $readmeContent = @"
MoonClaw Shared Workspace
==========================

This folder is managed by MoonClaw and shared on your local network.

Subdirectories:
  models/   - Downloaded and cached model files
  data/     - Working data and datasets
  logs/     - Application and inference logs
  config/   - Shared configuration files
  exports/  - Exported results and outputs

Network path: \\$env:COMPUTERNAME\$ShareName
"@
        $readmeContent | Set-Content -Path $readmePath -Encoding UTF8
    }

    # Store share info in NemoClaw config
    $configDir = Join-Path $env:USERPROFILE '.nemoclaw'
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    $shareConfig = @{
        shareName   = $ShareName
        localPath   = $sharePath
        networkPath = "\\$env:COMPUTERNAME\$ShareName"
        smbEnabled  = $shareCreated
        subdirs     = $subDirs
    }

    $shareConfigPath = Join-Path $configDir 'shared-drive.json'
    $shareConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $shareConfigPath -Encoding UTF8
    Write-Host "    Share config written to $shareConfigPath" -ForegroundColor DarkGray

    return $shareConfig
}
