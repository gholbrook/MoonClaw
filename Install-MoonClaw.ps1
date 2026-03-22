#Requires -Version 5.1
<#
.SYNOPSIS
    MoonClaw Installer - NemoClaw for Windows with batteries included.

.DESCRIPTION
    Installs NemoClaw with:
    - lossless-claw plugin
    - OpenRouter inference provider (full model selection)
    - Local shared drive on your desktop
    - Improved monitoring dashboard

.PARAMETER NonInteractive
    Skip all interactive prompts. Uses environment variables and defaults.

.PARAMETER SkipDashboard
    Skip dashboard installation.

.PARAMETER SkipShare
    Skip shared drive creation.

.PARAMETER SandboxName
    Name for the OpenClaw sandbox. Default: 'openclaw'.

.EXAMPLE
    .\Install-MoonClaw.ps1

.EXAMPLE
    $env:OPENROUTER_API_KEY = "sk-or-..."
    $env:NVIDIA_API_KEY = "nvapi-..."
    .\Install-MoonClaw.ps1 -NonInteractive
#>

param(
    [switch]$NonInteractive,
    [switch]$SkipDashboard,
    [switch]$SkipShare,
    [string]$SandboxName = 'my-assistant'
)

$ErrorActionPreference = 'Stop'
$script:StartTime = Get-Date
$script:ScriptRoot = $PSScriptRoot

# -- Helpers --

# Proxy Write-Host to always reset cursor to column 0 first.
# External commands (npm, next build, git) write progress bars with \r that
# leave the cursor at a non-zero column, causing all subsequent output to drift right.
function Write-Host {
    param(
        [Parameter(Position=0)] $Object = '',
        [switch]$NoNewline,
        [System.ConsoleColor]$ForegroundColor,
        [System.ConsoleColor]$BackgroundColor,
        [string]$Separator
    )
    try { [Console]::CursorLeft = 0 } catch {}
    Microsoft.PowerShell.Utility\Write-Host @PSBoundParameters
}

function Write-PipedLine {
    param(
        [Parameter(ValueFromPipeline)] $Line,
        [string]$ForegroundColor = 'DarkGray',
        [string]$Prefix = '    '
    )
    process {
        # Strip carriage returns and ANSI escape sequences from external command output
        $text = "$Line" -replace "`r", '' -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
        if ($text.Trim()) {
            Write-Host "$Prefix$text" -ForegroundColor $ForegroundColor
        }
    }
}

# -- Load modules --

. "$script:ScriptRoot\lib\prerequisites.ps1"
. "$script:ScriptRoot\lib\nemoclaw.ps1"
. "$script:ScriptRoot\lib\lossless-claw.ps1"
. "$script:ScriptRoot\lib\openrouter.ps1"
. "$script:ScriptRoot\lib\nvidia-nim.ps1"
. "$script:ScriptRoot\lib\shared-drive.ps1"

# -- Banner --

function Show-Banner {
    Write-Host ""
    Write-Host "    __  ___                   ________              " -ForegroundColor Magenta
    Write-Host "   /  |/  /___  ____  ____  / ____/ /___ _      __ " -ForegroundColor Magenta
    Write-Host "  / /|_/ / __ \/ __ \/ __ \/ /   / / __ \ | /| / / " -ForegroundColor Magenta
    Write-Host " / /  / / /_/ / /_/ / / / / /___/ / /_/ / |/ |/ /  " -ForegroundColor Magenta
    Write-Host "/_/  /_/\____/\____/_/ /_/\____/_/\__/_/|__/|__/   " -ForegroundColor Magenta
    Write-Host ""
    Write-Host "    NemoClaw for Windows -- batteries included." -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Version:  0.1.0" -ForegroundColor DarkGray
    Write-Host "  Date:     $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Summary {
    param(
        [hashtable]$Results
    )

    $elapsed = (Get-Date) - $script:StartTime

    Write-Host ""
    Write-Host "  ========================================" -ForegroundColor Magenta
    Write-Host "    MoonClaw Installation Complete" -ForegroundColor Magenta
    Write-Host "  ========================================" -ForegroundColor Magenta
    Write-Host ""

    if ($Results.NemoClaw) {
        Write-Host "    NemoClaw .............. installed" -ForegroundColor Green
    }
    if ($Results.LosslessClaw) {
        Write-Host "    lossless-claw ......... installed" -ForegroundColor Green
    }
    if ($Results.OpenRouter) {
        $model = $Results.OpenRouter.model
        Write-Host "    OpenRouter ............ configured ($model)" -ForegroundColor Green
    }
    if ($Results.NvidiaNim) {
        $nimModel = $Results.NvidiaNim.model
        Write-Host "    NVIDIA NIM ............ configured ($nimModel)" -ForegroundColor Green
    }
    if ($Results.SharedDrive) {
        Write-Host "    Shared drive .......... $($Results.SharedDrive.localPath)" -ForegroundColor Green
        Write-Host "    Sandbox path .......... /shared" -ForegroundColor Green
        if ($Results.SharedDrive.smbEnabled) {
            Write-Host "    Network path .......... $($Results.SharedDrive.networkPath)" -ForegroundColor Green
        }
    }
    if ($Results.Dashboard) {
        Write-Host "    Dashboard ............. http://localhost:3200" -ForegroundColor Green
    }
    if ($Results.Onboard) {
        Write-Host "    Sandbox ............... onboarded" -ForegroundColor Green
    }
    else {
        Write-Host "    Sandbox ............... pending (run 'nemoclaw onboard')" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "    Time elapsed: $([math]::Round($elapsed.TotalSeconds))s" -ForegroundColor DarkGray
    Write-Host ""

    $stepNum = 1
    if (-not $Results.Onboard) {
        Write-Host "  Next steps:" -ForegroundColor White
        Write-Host "    $stepNum. Run 'nemoclaw onboard' to complete sandbox setup" -ForegroundColor Gray
        $stepNum++
    }
    else {
        Write-Host "  Next steps:" -ForegroundColor White
    }
    Write-Host "    $stepNum. Run 'nemoclaw launch' to start the sandbox" -ForegroundColor Gray
    $stepNum++
    if ($Results.Dashboard) {
        Write-Host "    $stepNum. Open http://localhost:3200 for the dashboard" -ForegroundColor Gray
    }
    Write-Host ""
}

# -- Main --

function Invoke-MoonClawInstall {
    Show-Banner

    $results = @{}
    $totalSteps = 5
    if (-not $SkipDashboard) { $totalSteps++ }
    if (-not $SkipShare) { $totalSteps++ }
    $currentStep = 0

    # -- Step 1: Prerequisites --
    $currentStep++
    Write-Host ""
    Write-Host "  [$currentStep/$totalSteps] Checking prerequisites..." -ForegroundColor White
    Write-Host ("  " + ("=" * 50)) -ForegroundColor DarkGray

    $prereqOk = Assert-Prerequisites
    if (-not $prereqOk) {
        Write-Host ""
        Write-Host "  Installation aborted. Fix prerequisites and try again." -ForegroundColor Red
        return
    }

    # -- Step 2: Install NemoClaw --
    $currentStep++
    Write-Host ""
    Write-Host "  [$currentStep/$totalSteps] Installing NemoClaw..." -ForegroundColor White
    Write-Host ("  " + ("=" * 50)) -ForegroundColor DarkGray

    Install-NemoClaw
    $configPath = Initialize-NemoClawConfig -SandboxName $SandboxName
    $results.NemoClaw = $true

    # -- Step 3: Install lossless-claw --
    $currentStep++
    Write-Host ""
    Write-Host "  [$currentStep/$totalSteps] Installing lossless-claw plugin..." -ForegroundColor White
    Write-Host ("  " + ("=" * 50)) -ForegroundColor DarkGray

    Install-LosslessClaw
    $results.LosslessClaw = $true

    # -- Step 4: Configure credentials & providers --
    $currentStep++
    Write-Host ""
    Write-Host "  [$currentStep/$totalSteps] Configuring credentials & providers..." -ForegroundColor White
    Write-Host ("  " + ("=" * 50)) -ForegroundColor DarkGray

    $providerConfig = Install-OpenRouterProfile -NonInteractive:$NonInteractive
    $results.OpenRouter = $providerConfig

    $nimConfig = Get-NvidiaCredentials -NonInteractive:$NonInteractive -SandboxName $SandboxName
    $results.NvidiaNim = $nimConfig

    # -- Step 5: Shared drive --
    if (-not $SkipShare) {
        $currentStep++
        Write-Host ""
        Write-Host "  [$currentStep/$totalSteps] Setting up shared drive..." -ForegroundColor White
        Write-Host ("  " + ("=" * 50)) -ForegroundColor DarkGray

        $shareConfig = New-SharedDrive
        $results.SharedDrive = $shareConfig
    }

    # -- Step 6: Dashboard --
    if (-not $SkipDashboard) {
        $currentStep++
        Write-Host ""
        Write-Host "  [$currentStep/$totalSteps] Installing dashboard..." -ForegroundColor White
        Write-Host ("  " + ("=" * 50)) -ForegroundColor DarkGray

        $dashboardDir = Join-Path $script:ScriptRoot 'dashboard'
        if (Test-Path (Join-Path $dashboardDir 'package.json')) {
            Push-Location $dashboardDir
            try {
                $prevEAP = $ErrorActionPreference
                $ErrorActionPreference = 'Continue'

                Write-Host "    Installing dashboard dependencies..." -ForegroundColor DarkGray
                & npm install 2>&1 | Write-PipedLine

                Write-Host "    Building dashboard..." -ForegroundColor DarkGray
                & npm run build 2>&1 | Write-PipedLine

                $ErrorActionPreference = $prevEAP

                $results.Dashboard = $true
                Write-Host "    Dashboard installed. Run 'npm start' in dashboard/ to launch." -ForegroundColor Green
            }
            catch {
                Write-Host "    Dashboard build failed: $_" -ForegroundColor Yellow
                Write-Host "    You can install it later with 'cd dashboard && npm install && npm run build'" -ForegroundColor Yellow
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Host "    Dashboard package not found. Skipping." -ForegroundColor Yellow
        }
    }

    # -- Step: Onboard NemoClaw --
    $currentStep++
    Write-Host ""
    Write-Host "  [$currentStep/$totalSteps] Running NemoClaw onboard..." -ForegroundColor White
    Write-Host ("  " + ("=" * 50)) -ForegroundColor DarkGray

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    # Always run non-interactive -- we already collected all credentials above
    Write-Host "    Running non-interactive onboard..." -ForegroundColor DarkGray
    $env:NEMOCLAW_NON_INTERACTIVE = '1'
    $env:NEMOCLAW_SANDBOX_NAME = $nimConfig.sandboxName
    $env:NVIDIA_API_KEY = $nimConfig.apiKey
    $env:NEMOCLAW_PROVIDER = 'cloud'
    $env:NEMOCLAW_MODEL = $nimConfig.model
    $env:NEMOCLAW_RECREATE_SANDBOX = '1'
    & nemoclaw onboard --non-interactive 2>&1 | Write-PipedLine

    $onboardExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP

    # Clean up onboard env vars
    Remove-Item Env:\NEMOCLAW_NON_INTERACTIVE -ErrorAction SilentlyContinue
    Remove-Item Env:\NEMOCLAW_SANDBOX_NAME -ErrorAction SilentlyContinue
    Remove-Item Env:\NEMOCLAW_PROVIDER -ErrorAction SilentlyContinue
    Remove-Item Env:\NEMOCLAW_MODEL -ErrorAction SilentlyContinue
    Remove-Item Env:\NEMOCLAW_RECREATE_SANDBOX -ErrorAction SilentlyContinue

    if ($onboardExit -eq 0) {
        $results.Onboard = $true
        Write-Host ""
        Write-Host "    Onboard completed successfully." -ForegroundColor Green

        # Sync shared folder into sandbox so OpenClaw can access user files
        Write-Host "    Syncing shared folder to sandbox..." -ForegroundColor DarkGray
        $onboardSandboxName = $nimConfig.sandboxName
        $sharePath = Join-Path ([System.Environment]::GetFolderPath('Desktop')) 'MoonClaw Shared'
        if (Test-Path $sharePath) {
            $resolvedShare = (Resolve-Path $sharePath).Path
            $wslSharePath = "/mnt/$($resolvedShare.Substring(0,1).ToLower())/$($resolvedShare.Substring(3).Replace('\','/'))"
            $prevEAP2 = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            & wsl -d Ubuntu -- /home/moon/.local/bin/openshell sandbox upload $onboardSandboxName $wslSharePath /sandbox/shared 2>&1 | Write-PipedLine
            $ErrorActionPreference = $prevEAP2
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    Shared folder synced to /sandbox/shared in sandbox." -ForegroundColor Green
            }
            else {
                Write-Host "    Shared folder sync failed. Run '.\moonclaw-share.ps1 push' later." -ForegroundColor Yellow
            }
        }

        # Install openshell CLI inside the container so 'openshell sandbox connect' works
        Write-Host "    Installing openshell CLI in container..." -ForegroundColor DarkGray
        $containerName = (docker ps --filter "name=openshell-cluster" --format "{{.Names}}" 2>$null) | Select-Object -First 1
        if ($containerName) {
            $prevEAP2 = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            docker exec $containerName bash -c 'mkdir -p /root/.local/bin && curl -LsSf https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | OPENSHELL_INSTALL_DIR=/root/.local/bin sh' 2>&1 | ForEach-Object {
                Write-Host "    $_" -ForegroundColor DarkGray
            }
            $ErrorActionPreference = $prevEAP2
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    openshell CLI installed in container." -ForegroundColor Green
            }
            else {
                Write-Host "    openshell CLI install failed. You can install it manually later." -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "    Container not found. openshell CLI will need to be installed manually." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host ""
        Write-Host "    Onboard exited with errors. You can retry later with 'nemoclaw onboard'." -ForegroundColor Yellow
    }

    # -- Summary --
    Show-Summary -Results $results
}

# Run it
Invoke-MoonClawInstall
