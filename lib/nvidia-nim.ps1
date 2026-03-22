# MoonClaw - NVIDIA NIM credential and model collection
# Collects NVIDIA API key, sandbox name, and NIM model selection upfront
# so that nemoclaw onboard can run fully non-interactive.

$script:NimDefaultModel = "nvidia/nemotron-3-super-120b-a12b"

$script:NimModelOptions = @(
    @{ id = "nvidia/nemotron-3-super-120b-a12b"; label = "Nemotron 3 Super 120B" }
    @{ id = "moonshotai/kimi-k2.5";             label = "Kimi K2.5" }
    @{ id = "z-ai/glm5";                        label = "GLM-5" }
    @{ id = "minimaxai/minimax-m2.5";           label = "MiniMax M2.5" }
    @{ id = "qwen/qwen3.5-397b-a17b";          label = "Qwen3.5 397B A17B" }
    @{ id = "openai/gpt-oss-120b";             label = "GPT-OSS 120B" }
)

function Write-NimStep {
    param([string]$Message)
    Write-Host ""
    Write-Host "  [NVIDIA] $Message" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * 50)) -ForegroundColor DarkGray
}

function Get-NvidiaApiKey {
    param([switch]$NonInteractive)

    # Check existing credentials file
    $credsFile = Join-Path (Join-Path $env:USERPROFILE '.nemoclaw') 'credentials.json'
    if (Test-Path $credsFile) {
        try {
            $creds = Get-Content $credsFile -Raw | ConvertFrom-Json
            if ($creds.NVIDIA_API_KEY) {
                Write-Host "    Found existing NVIDIA API key in credentials." -ForegroundColor Green
                return $creds.NVIDIA_API_KEY
            }
        }
        catch { }
    }

    # Check environment
    $existing = [System.Environment]::GetEnvironmentVariable('NVIDIA_API_KEY', 'User')
    if ($existing) {
        Write-Host "    Found existing NVIDIA API key in environment." -ForegroundColor Green
        return $existing
    }

    if ($env:NVIDIA_API_KEY) {
        Write-Host "    Found NVIDIA API key in session environment." -ForegroundColor Green
        return $env:NVIDIA_API_KEY
    }

    if ($NonInteractive) {
        throw "NVIDIA_API_KEY not set. Set it in your environment for non-interactive mode."
    }

    Write-Host ""
    Write-Host "    Get your API key from: https://build.nvidia.com/settings/api-keys" -ForegroundColor Yellow
    Write-Host "    (Sign in, click 'Generate API Key', paste below)" -ForegroundColor Yellow
    Write-Host ""
    $key = Read-Host "    Enter your NVIDIA API key (starts with nvapi-)"

    if ([string]::IsNullOrWhiteSpace($key)) {
        throw "NVIDIA API key is required."
    }

    if (-not $key.StartsWith('nvapi-')) {
        Write-Host "    Warning: key doesn't start with 'nvapi-' -- proceeding anyway." -ForegroundColor Yellow
    }

    return $key
}

function Select-NimModel {
    param([switch]$NonInteractive)

    if ($NonInteractive) {
        Write-Host "    Using default NIM model: $script:NimDefaultModel" -ForegroundColor DarkGray
        return $script:NimDefaultModel
    }

    Write-Host ""
    Write-Host "    Available NIM cloud models:" -ForegroundColor White
    for ($i = 0; $i -lt $script:NimModelOptions.Count; $i++) {
        $m = $script:NimModelOptions[$i]
        $marker = ""
        if ($m.id -eq $script:NimDefaultModel) { $marker = " (default)" }
        Write-Host "    $($i + 1). $($m.label)$marker" -ForegroundColor Gray
    }

    Write-Host ""
    $choice = Read-Host "    Select NIM model [1-$($script:NimModelOptions.Count), default=1]"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        return $script:NimDefaultModel
    }

    $idx = [int]$choice - 1
    if ($idx -lt 0 -or $idx -ge $script:NimModelOptions.Count) {
        Write-Host "    Invalid selection, using default." -ForegroundColor Yellow
        return $script:NimDefaultModel
    }

    $selected = $script:NimModelOptions[$idx]
    Write-Host "    Selected: $($selected.label)" -ForegroundColor Green
    return $selected.id
}

function Get-SandboxName {
    param(
        [switch]$NonInteractive,
        [string]$Default = 'my-assistant'
    )

    if ($NonInteractive) {
        Write-Host "    Using sandbox name: $Default" -ForegroundColor DarkGray
        return $Default
    }

    Write-Host ""
    $name = Read-Host "    Sandbox name (lowercase, numbers, hyphens) [default: $Default]"

    if ([string]::IsNullOrWhiteSpace($name)) {
        return $Default
    }

    $name = $name.Trim().ToLower()

    if ($name -notmatch '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$') {
        Write-Host "    Invalid name. Using default: $Default" -ForegroundColor Yellow
        return $Default
    }

    return $name
}

function Get-NvidiaCredentials {
    param(
        [switch]$NonInteractive,
        [string]$SandboxName = 'my-assistant'
    )

    Write-NimStep "Configuring NVIDIA NIM & sandbox"

    $apiKey = Get-NvidiaApiKey -NonInteractive:$NonInteractive
    $model = Select-NimModel -NonInteractive:$NonInteractive
    $sandbox = Get-SandboxName -NonInteractive:$NonInteractive -Default $SandboxName

    # Store API key in user environment
    [System.Environment]::SetEnvironmentVariable('NVIDIA_API_KEY', $apiKey, 'User')
    $env:NVIDIA_API_KEY = $apiKey
    Write-Host "    NVIDIA API key stored in user environment." -ForegroundColor Green

    # Save to nemoclaw credentials file
    $configDir = Join-Path $env:USERPROFILE '.nemoclaw'
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    $credsFile = Join-Path $configDir 'credentials.json'
    $creds = @{}
    if (Test-Path $credsFile) {
        try { $creds = Get-Content $credsFile -Raw | ConvertFrom-Json -AsHashtable } catch { $creds = @{} }
    }
    $creds['NVIDIA_API_KEY'] = $apiKey
    $creds | ConvertTo-Json -Depth 5 | Set-Content -Path $credsFile -Encoding UTF8
    Write-Host "    Credentials saved to $credsFile" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "    Sandbox:  $sandbox" -ForegroundColor White
    Write-Host "    Model:    $model" -ForegroundColor White

    return @{
        apiKey      = $apiKey
        model       = $model
        sandboxName = $sandbox
    }
}
