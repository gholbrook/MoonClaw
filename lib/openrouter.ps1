# MoonClaw - OpenRouter inference profile setup

$script:OpenRouterEndpoint = "https://openrouter.ai/api/v1"
$script:DefaultModel = "anthropic/claude-sonnet-4"
$script:CredentialEnv = "OPENROUTER_API_KEY"

$script:ModelOptions = @(
    @{ id = "anthropic/claude-sonnet-4";     label = "Claude Sonnet 4" }
    @{ id = "anthropic/claude-haiku-4";      label = "Claude Haiku 4" }
    @{ id = "openai/gpt-4.1";               label = "GPT-4.1" }
    @{ id = "openai/gpt-4.1-mini";          label = "GPT-4.1 Mini" }
    @{ id = "google/gemini-2.5-pro";         label = "Gemini 2.5 Pro" }
    @{ id = "google/gemini-2.5-flash";       label = "Gemini 2.5 Flash" }
    @{ id = "meta-llama/llama-4-maverick";   label = "Llama 4 Maverick" }
    @{ id = "meta-llama/llama-4-scout";      label = "Llama 4 Scout" }
    @{ id = "deepseek/deepseek-r1";          label = "DeepSeek R1" }
    @{ id = "mistralai/mistral-large";       label = "Mistral Large" }
    @{ id = "qwen/qwen3-235b-a22b";         label = "Qwen3 235B" }
)

function Write-RouterStep {
    param([string]$Message)
    Write-Host ""
    Write-Host "  [OPENROUTER] $Message" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * 50)) -ForegroundColor DarkGray
}

function Get-OpenRouterApiKey {
    param([switch]$NonInteractive)

    $existing = [System.Environment]::GetEnvironmentVariable($script:CredentialEnv, 'User')
    if ($existing) {
        Write-Host "    Found existing OpenRouter API key in environment." -ForegroundColor Green
        return $existing
    }

    if ($NonInteractive) {
        $envVal = $env:OPENROUTER_API_KEY
        if ($envVal) { return $envVal }
        throw "OPENROUTER_API_KEY not set. Set it in your environment for non-interactive mode."
    }

    Write-Host ""
    Write-Host "    Get your API key from: https://openrouter.ai/keys" -ForegroundColor Yellow
    $key = Read-Host "    Enter your OpenRouter API key"

    if ([string]::IsNullOrWhiteSpace($key)) {
        throw "OpenRouter API key is required."
    }

    return $key
}

function Select-OpenRouterModel {
    param([switch]$NonInteractive)

    if ($NonInteractive) {
        Write-Host "    Using default model: $script:DefaultModel" -ForegroundColor DarkGray
        return $script:DefaultModel
    }

    Write-Host ""
    Write-Host "    Available models:" -ForegroundColor White
    for ($i = 0; $i -lt $script:ModelOptions.Count; $i++) {
        $m = $script:ModelOptions[$i]
        $marker = ""
        if ($m.id -eq $script:DefaultModel) { $marker = " (default)" }
        Write-Host "    $($i + 1). $($m.label)$marker" -ForegroundColor Gray
    }

    Write-Host ""
    $choice = Read-Host "    Select model [1-$($script:ModelOptions.Count), default=1]"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        return $script:DefaultModel
    }

    $idx = [int]$choice - 1
    if ($idx -lt 0 -or $idx -ge $script:ModelOptions.Count) {
        Write-Host "    Invalid selection, using default." -ForegroundColor Yellow
        return $script:DefaultModel
    }

    $selected = $script:ModelOptions[$idx]
    Write-Host "    Selected: $($selected.label)" -ForegroundColor Green
    return $selected.id
}

function Install-OpenRouterProfile {
    param([switch]$NonInteractive)

    Write-RouterStep "Configuring OpenRouter inference provider"

    $apiKey = Get-OpenRouterApiKey -NonInteractive:$NonInteractive
    $model = Select-OpenRouterModel -NonInteractive:$NonInteractive

    # Store API key in user environment
    [System.Environment]::SetEnvironmentVariable($script:CredentialEnv, $apiKey, 'User')
    $env:OPENROUTER_API_KEY = $apiKey
    Write-Host "    API key stored in user environment variable: $script:CredentialEnv" -ForegroundColor Green

    # Write provider config
    $configDir = Join-Path $env:USERPROFILE '.nemoclaw'
    $providerConfig = @{
        provider      = 'openrouter'
        providerType  = 'openai'
        providerName  = 'openrouter'
        endpoint      = $script:OpenRouterEndpoint
        model         = $model
        credentialEnv = $script:CredentialEnv
        providerLabel = 'OpenRouter'
    }

    $providerPath = Join-Path $configDir 'openrouter-provider.json'
    $providerConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $providerPath -Encoding UTF8
    Write-Host "    Provider config written to $providerPath" -ForegroundColor Green

    # Copy profile YAML
    $profileSource = Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'config') 'openrouter-profile.yaml'
    if (Test-Path $profileSource) {
        $profileDest = Join-Path $configDir 'openrouter-profile.yaml'
        Copy-Item $profileSource $profileDest -Force
        Write-Host "    Profile YAML copied to $profileDest" -ForegroundColor DarkGray
    }

    # Register with openshell if available
    if (Get-Command 'openshell' -ErrorAction SilentlyContinue) {
        Write-Host "    Registering OpenRouter provider with OpenShell..." -ForegroundColor DarkGray
        try {
            $configJson = @{
                endpoint = $script:OpenRouterEndpoint
                model    = $model
            } | ConvertTo-Json -Compress

            & openshell provider create --name "openrouter" --type "openai" --credential "env:$script:CredentialEnv" --config $configJson 2>&1 | Out-Null

            Write-Host "    OpenRouter registered with OpenShell." -ForegroundColor Green
        }
        catch {
            Write-Host "    Could not register with OpenShell (will be configured on first run)." -ForegroundColor Yellow
        }
    }

    return $providerConfig
}
