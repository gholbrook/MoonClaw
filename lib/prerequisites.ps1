# MoonClaw - Prerequisite checks and installation
# Ensures Node.js >= 20, npm >= 10, Docker, and OpenShell are available.
# OpenShell has no native Windows build, so we install it via pip in a Docker container
# and create a shim script that proxies commands through Docker.

$script:MinNodeMajor = 20
$script:MinNpmMajor = 10
$script:RecommendedNodeMajor = 22
$script:OpenShellShimDir = Join-Path (Join-Path $env:LOCALAPPDATA "MoonClaw") "bin"

function Write-PrereqStep {
    param([string]$Message)
    Write-Host ""
    Write-Host "  [PREREQ] $Message" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * 50)) -ForegroundColor DarkGray
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Get-VersionMajor {
    param([string]$VersionString)
    $clean = $VersionString -replace '^v', ''
    [int]($clean.Split('.')[0])
}

function Install-NodeJS {
    Write-PrereqStep "Installing Node.js $script:RecommendedNodeMajor via winget"

    if (Test-CommandExists 'winget') {
        & winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements --silent
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install Node.js via winget. Install Node.js $script:RecommendedNodeMajor+ manually from https://nodejs.org"
        }
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                     [System.Environment]::GetEnvironmentVariable('Path', 'User')
    }
    else {
        throw "winget not found. Install Node.js $script:RecommendedNodeMajor+ manually from https://nodejs.org"
    }
}

function Install-OpenShell {
    Write-Host "    OpenShell has no native Windows build." -ForegroundColor Yellow
    Write-Host "    Installing OpenShell in WSL2 via official install script..." -ForegroundColor DarkGray

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    # Check if a real Linux distro (not docker-desktop) is available
    $distro = $null
    $wslOutput = & wsl --list --quiet 2>$null
    if ($wslOutput) {
        foreach ($line in $wslOutput) {
            $name = $line.Trim() -replace '\x00', ''
            if ($name -and $name -notmatch 'docker-desktop' -and $name.Length -gt 0) {
                $distro = $name
                break
            }
        }
    }

    if (-not $distro) {
        Write-Host "    No Linux distro found in WSL (only docker-desktop)." -ForegroundColor Yellow
        Write-Host "    Installing Ubuntu in WSL2..." -ForegroundColor DarkGray
        & wsl --install Ubuntu --no-launch 2>&1 | Write-PipedLine
        $distro = "Ubuntu"

        # Initialize Ubuntu (set default user to root to avoid interactive user setup)
        Write-Host "    Initializing Ubuntu..." -ForegroundColor DarkGray
        & wsl -d Ubuntu -- bash -c "echo 'Ubuntu initialized'" 2>&1 | Write-PipedLine
    }

    Write-Host "    Using WSL distro: $distro" -ForegroundColor DarkGray

    # Run the official NVIDIA install script inside the distro
    & wsl -d $distro -- bash -c "curl -fsSL https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | bash" 2>&1 | ForEach-Object {
        Write-Host "    $_" -ForegroundColor DarkGray
    }
    $installExit = $LASTEXITCODE

    if ($installExit -ne 0) {
        $ErrorActionPreference = $prevEAP
        throw "Failed to install OpenShell in WSL ($distro)."
    }

    # Add to PATH in WSL bashrc so it persists
    & wsl -d $distro -- bash -c 'grep -q "/.local/bin" ~/.bashrc 2>/dev/null || echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc' 2>$null

    # Detect the WSL user's home directory for the openshell binary path
    $wslHome = (& wsl -d $distro -- bash -c 'echo $HOME' 2>$null).Trim()
    if (-not $wslHome) { $wslHome = '/root' }
    $openshellBin = "$wslHome/.local/bin/openshell"

    # Verify it works using absolute path
    $wslCheck = & wsl -d $distro -- $openshellBin --version 2>$null
    $ErrorActionPreference = $prevEAP

    if (-not $wslCheck) {
        throw "OpenShell installed in WSL but version check failed."
    }

    Write-Host "    OpenShell $wslCheck installed in WSL ($distro)." -ForegroundColor Green

    # Store the distro name for shims
    $script:WslDistro = $distro

    # Create shim directory
    if (-not (Test-Path $script:OpenShellShimDir)) {
        New-Item -ItemType Directory -Path $script:OpenShellShimDir -Force | Out-Null
    }

    # Create openshell.cmd shim that proxies through WSL
    $shimCmd = Join-Path $script:OpenShellShimDir "openshell.cmd"
    $cmdLines = @(
        '@ECHO OFF'
        "wsl -d $distro -- $openshellBin %*"
    )
    [System.IO.File]::WriteAllLines($shimCmd, $cmdLines)

    # Create openshell.ps1 shim for PowerShell
    $shimPs1 = Join-Path $script:OpenShellShimDir "openshell.ps1"
    $ps1Lines = @(
        '#!/usr/bin/env pwsh'
        "wsl -d $distro -- $openshellBin @args"
        'exit $LASTEXITCODE'
    )
    [System.IO.File]::WriteAllLines($shimPs1, $ps1Lines)

    # Add shim dir to user PATH
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$($script:OpenShellShimDir)*") {
        [System.Environment]::SetEnvironmentVariable('Path', "$userPath;$($script:OpenShellShimDir)", 'User')
    }
    $env:Path = "$($script:OpenShellShimDir);$env:Path"

    Write-Host "    OpenShell Docker image built: moonclaw/openshell:latest" -ForegroundColor Green
    Write-Host "    Shim created at $shimCmd" -ForegroundColor DarkGray
}

function Test-NodeVersion {
    if (-not (Test-CommandExists 'node')) {
        return $false
    }
    $version = & node --version 2>$null
    $major = Get-VersionMajor $version
    return $major -ge $script:MinNodeMajor
}

function Test-NpmVersion {
    if (-not (Test-CommandExists 'npm')) {
        return $false
    }
    $version = & npm --version 2>$null
    $major = Get-VersionMajor $version
    return $major -ge $script:MinNpmMajor
}

function Test-DockerRunning {
    if (-not (Test-CommandExists 'docker')) {
        return $false
    }
    try {
        & docker info 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Assert-Prerequisites {
    $allGood = $true

    # -- Node.js --
    Write-PrereqStep "Checking Node.js"
    if (-not (Test-NodeVersion)) {
        if (Test-CommandExists 'node') {
            $currentVersion = & node --version 2>$null
            Write-Host "    Node.js $currentVersion found but >= $script:MinNodeMajor required." -ForegroundColor Yellow
        }
        else {
            Write-Host "    Node.js not found." -ForegroundColor Yellow
        }

        Write-Host "    Attempting to install Node.js..." -ForegroundColor Yellow
        try {
            Install-NodeJS
            if (-not (Test-NodeVersion)) {
                Write-Host "    Node.js installation completed but version check failed." -ForegroundColor Red
                Write-Host "    You may need to restart your terminal." -ForegroundColor Red
                $allGood = $false
            }
            else {
                $v = & node --version
                Write-Host "    Node.js $v installed successfully." -ForegroundColor Green
            }
        }
        catch {
            Write-Host "    $_" -ForegroundColor Red
            $allGood = $false
        }
    }
    else {
        $v = & node --version
        Write-Host "    Node.js $v -- OK" -ForegroundColor Green
    }

    # -- npm --
    Write-PrereqStep "Checking npm"
    if (-not (Test-NpmVersion)) {
        Write-Host "    npm not found or version is below $script:MinNpmMajor." -ForegroundColor Red
        Write-Host "    npm ships with Node.js -- try reinstalling Node.js." -ForegroundColor Red
        $allGood = $false
    }
    else {
        $v = & npm --version
        Write-Host "    npm $v -- OK" -ForegroundColor Green
    }

    # -- Docker --
    Write-PrereqStep "Checking Docker"
    if (-not (Test-CommandExists 'docker')) {
        Write-Host "    Docker not found. Install Docker Desktop from https://docker.com/products/docker-desktop" -ForegroundColor Red
        $allGood = $false
    }
    elseif (-not (Test-DockerRunning)) {
        Write-Host "    Docker is installed but not running. Please start Docker Desktop." -ForegroundColor Yellow
        $allGood = $false
    }
    else {
        $v = & docker --version
        Write-Host "    $v -- OK" -ForegroundColor Green
    }

    # -- OpenShell (requires Docker) --
    Write-PrereqStep "Checking OpenShell"
    if (-not (Test-CommandExists 'openshell')) {
        if (-not (Test-DockerRunning)) {
            Write-Host "    OpenShell requires Docker. Fix Docker first." -ForegroundColor Red
            $allGood = $false
        }
        else {
            Write-Host "    OpenShell not found. Attempting to install..." -ForegroundColor Yellow
            try {
                Install-OpenShell
                Write-Host "    OpenShell (via Docker) -- OK" -ForegroundColor Green
            }
            catch {
                Write-Host "    Failed to install OpenShell: $_" -ForegroundColor Red
                Write-Host "    Install manually from https://github.com/NVIDIA/OpenShell/releases" -ForegroundColor Red
                $allGood = $false
            }
        }
    }
    else {
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $v = & openshell --version 2>$null
        $ErrorActionPreference = $prevEAP
        Write-Host "    OpenShell $v -- OK" -ForegroundColor Green
    }

    if (-not $allGood) {
        Write-Host ""
        Write-Host "  Some prerequisites are missing. Please fix the issues above and re-run the installer." -ForegroundColor Red
    }

    return $allGood
}
