# MoonClaw - Lossless-Claw plugin installer
# Installs via OpenClaw's plugin system: openclaw plugins install @martian-engineering/lossless-claw

$script:LosslessClawPackage = "@martian-engineering/lossless-claw"

function Write-PluginStep {
    param([string]$Message)
    Write-Host ""
    Write-Host "  [PLUGIN] $Message" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * 50)) -ForegroundColor DarkGray
}

function Test-OpenClawAvailable {
    $null -ne (Get-Command 'openclaw' -ErrorAction SilentlyContinue)
}

function Install-LosslessClaw {
    Write-PluginStep "Installing lossless-claw plugin"

    if (-not (Test-OpenClawAvailable)) {
        Write-Host "    openclaw CLI not found. Will configure plugin for post-install setup." -ForegroundColor Yellow
        Write-LosslessClawConfig
        return
    }

    # Install via OpenClaw plugin system
    Write-Host "    Running: openclaw plugins install $script:LosslessClawPackage" -ForegroundColor DarkGray
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & openclaw plugins install $script:LosslessClawPackage 2>&1 | Write-PipedLine
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP

    if ($exitCode -ne 0) {
        Write-Host "    Plugin install command failed. Writing config for manual setup." -ForegroundColor Yellow
        Write-LosslessClawConfig
        return
    }

    # Register as the context engine
    Register-LosslessClawPlugin

    Write-Host "    lossless-claw plugin installed successfully." -ForegroundColor Green
}

function Register-LosslessClawPlugin {
    Write-Host "    Registering lossless-claw as context engine..." -ForegroundColor DarkGray

    $openclawConfigDir = Join-Path $env:USERPROFILE ".openclaw"
    if (-not (Test-Path $openclawConfigDir)) {
        New-Item -ItemType Directory -Path $openclawConfigDir -Force | Out-Null
    }

    $configPath = Join-Path $openclawConfigDir "config.json"

    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
    }
    else {
        $config = [PSCustomObject]@{}
    }

    # Add plugins.slots.contextEngine = "lossless-claw"
    if (-not $config.PSObject.Properties['plugins']) {
        $config | Add-Member -NotePropertyName 'plugins' -NotePropertyValue ([PSCustomObject]@{})
    }
    if (-not $config.plugins.PSObject.Properties['slots']) {
        $config.plugins | Add-Member -NotePropertyName 'slots' -NotePropertyValue ([PSCustomObject]@{})
    }
    $config.plugins.slots | Add-Member -NotePropertyName 'contextEngine' -NotePropertyValue 'lossless-claw' -Force

    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
    Write-Host "    Registered as context engine in $configPath" -ForegroundColor DarkGray
}

function Write-LosslessClawConfig {
    <#
    .SYNOPSIS
        Writes LCM environment defaults and a setup script for later installation.
    #>

    $configDir = Join-Path $env:USERPROFILE '.nemoclaw'
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    # Write recommended environment defaults
    $lcmConfig = @{
        package          = $script:LosslessClawPackage
        installCommand   = "openclaw plugins install $script:LosslessClawPackage"
        envDefaults      = @{
            LCM_FRESH_TAIL_COUNT     = "32"
            LCM_INCREMENTAL_MAX_DEPTH = "-1"
            LCM_CONTEXT_THRESHOLD    = "0.75"
            LCM_ENABLED              = "true"
        }
        contextEngine    = "lossless-claw"
        status           = "pending-install"
    }

    $lcmConfigPath = Join-Path $configDir 'lossless-claw.json'
    $lcmConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $lcmConfigPath -Encoding UTF8
    Write-Host "    Plugin config saved to $lcmConfigPath" -ForegroundColor Green
    Write-Host "    Run 'openclaw plugins install $script:LosslessClawPackage' after sandbox setup." -ForegroundColor Yellow

    # Set recommended env vars for the user
    $lcmConfig.envDefaults.GetEnumerator() | ForEach-Object {
        [System.Environment]::SetEnvironmentVariable($_.Key, $_.Value, 'User')
    }
    Write-Host "    LCM environment defaults set (LCM_FRESH_TAIL_COUNT=32, LCM_CONTEXT_THRESHOLD=0.75, etc.)" -ForegroundColor DarkGray
}
