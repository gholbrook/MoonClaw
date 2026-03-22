# MoonClaw - NemoClaw installation module
# Clones from GitHub, installs deps locally, then copies into npm global dir manually
# to avoid the Unix-only prepublishOnly script.

$script:NemoClawRepo = "https://github.com/NVIDIA/NemoClaw.git"
$script:NemoClawGitRef = "main"

function Write-NemoStep {
    param([string]$Message)
    Write-Host ""
    Write-Host "  [NEMOCLAW] $Message" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * 50)) -ForegroundColor DarkGray
}

function Get-NemoClawInstallDir {
    $npmGlobalPrefix = & npm config get prefix 2>$null
    return $npmGlobalPrefix
}

function Test-NemoClawInstalled {
    $cmd = Get-Command 'nemoclaw' -ErrorAction SilentlyContinue
    if (-not $cmd) { return $false }
    # Also verify the target JS file exists
    $globalPrefix = Get-NemoClawInstallDir
    $binJs = Join-Path (Join-Path (Join-Path $globalPrefix "node_modules") "nemoclaw") "bin"
    return (Test-Path (Join-Path $binJs "nemoclaw.js"))
}

function Install-NemoClaw {
    Write-NemoStep "Installing NemoClaw"

    $npmGlobalPrefix = Get-NemoClawInstallDir
    $globalNemoDir = Join-Path (Join-Path $npmGlobalPrefix "node_modules") "nemoclaw"

    # Clean up any existing (possibly broken) install
    if (Test-Path $globalNemoDir) {
        Write-Host "    Removing existing NemoClaw installation..." -ForegroundColor Yellow
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & npm uninstall -g nemoclaw 2>&1 | Out-Null
        $ErrorActionPreference = $prevEAP
        # Force remove if npm uninstall left remnants
        if (Test-Path $globalNemoDir) {
            Remove-Item -Recurse -Force $globalNemoDir -ErrorAction SilentlyContinue
        }
    }

    # Clone the repo
    $tempDir = Join-Path $env:TEMP "moonclaw-nemoclaw-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Write-Host "    Cloning NemoClaw from GitHub..." -ForegroundColor DarkGray

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    & git clone --depth 1 --branch $script:NemoClawGitRef $script:NemoClawRepo $tempDir 2>&1 | Write-PipedLine

    if ($LASTEXITCODE -ne 0) {
        $ErrorActionPreference = $prevEAP
        throw "Failed to clone NemoClaw repository."
    }

    # Install root dependencies (openclaw etc.) in the cloned repo
    Write-Host "    Installing dependencies..." -ForegroundColor DarkGray
    Push-Location $tempDir
    & npm install --ignore-scripts 2>&1 | Write-PipedLine
    Pop-Location

    # Install nemoclaw sub-package dependencies
    $nemoSubDir = Join-Path $tempDir "nemoclaw"
    if (Test-Path (Join-Path $nemoSubDir "package.json")) {
        Push-Location $nemoSubDir
        & npm install --ignore-scripts 2>&1 | ForEach-Object {
            Write-Host "    $_" -ForegroundColor DarkGray
        }
        Pop-Location
    }

    $ErrorActionPreference = $prevEAP

    # Copy the entire repo into the global node_modules as the nemoclaw package
    Write-Host "    Installing to global node_modules..." -ForegroundColor DarkGray
    Copy-Item -Path $tempDir -Destination $globalNemoDir -Recurse -Force

    # Fix CRLF line endings on shell scripts so they work in WSL/Linux
    Write-Host "    Converting shell scripts to LF line endings..." -ForegroundColor DarkGray
    Get-ChildItem -Path $globalNemoDir -Recurse -Include '*.sh','*.py','Makefile' | ForEach-Object {
        $content = [System.IO.File]::ReadAllText($_.FullName)
        if ($content.Contains("`r`n")) {
            [System.IO.File]::WriteAllText($_.FullName, $content.Replace("`r`n", "`n"))
        }
    }

    # Patch runner.js to use WSL bash instead of native bash (which doesn't exist on Windows)
    Write-Host "    Patching runner.js for Windows/WSL compatibility..." -ForegroundColor DarkGray
    $runnerPath = Join-Path (Join-Path (Join-Path $globalNemoDir "bin") "lib") "runner.js"
    if (Test-Path $runnerPath) {
        # Write a Windows-compatible runner that routes bash calls through WSL
        $patchedRunner = @'
const { execSync, spawnSync } = require("child_process");
const path = require("path");
const { detectDockerHost } = require("./platform");

const ROOT_WIN = path.resolve(__dirname, "..", "..");
const ROOT = ROOT_WIN.replace(/^([A-Z]):\\/i, (m, d) => "/mnt/" + d.toLowerCase() + "/").replace(/\\/g, "/");
const SCRIPTS = ROOT + "/scripts";
const WSL_DISTRO = process.env.MOONCLAW_WSL_DISTRO || "Ubuntu";
const PATH_PREFIX = 'export PATH="$HOME/.local/bin:$PATH" && ';

const dockerHost = detectDockerHost();
if (dockerHost) {
  process.env.DOCKER_HOST = dockerHost.dockerHost;
}

// Convert Windows paths (C:\foo\bar) to WSL paths (/mnt/c/foo/bar) in a command string
// Also fix backslash-mangled WSL paths from path.join() (e.g. \mnt\c\... -> /mnt/c/...)
function winToWslPath(cmd) {
  return cmd
    .replace(/([A-Z]):\\([^\s"']*)/gi, (match, drive, rest) => {
      return "/mnt/" + drive.toLowerCase() + "/" + rest.replace(/\\/g, "/");
    })
    .replace(/\\mnt\\([a-z])\\([^\s"']*)/gi, (match, drive, rest) => {
      return "/mnt/" + drive + "/" + rest.replace(/\\/g, "/");
    });
}

function wslCmd(cmd) {
  return PATH_PREFIX + winToWslPath(cmd);
}

function run(cmd, opts = {}) {
  const stdio = opts.stdio ?? ["ignore", "inherit", "inherit"];
  const result = spawnSync("wsl", ["-d", WSL_DISTRO, "--", "bash", "-c", wslCmd(cmd)], {
    ...opts,
    stdio,
    cwd: ROOT_WIN,
    env: { ...process.env, ...opts.env },
  });
  if (result.status !== 0 && !opts.ignoreError) {
    console.error(`  Command failed (exit ${result.status}): ${cmd.slice(0, 80)}`);
    process.exit(result.status || 1);
  }
  return result;
}

function runInteractive(cmd, opts = {}) {
  const stdio = opts.stdio ?? "inherit";
  const result = spawnSync("wsl", ["-d", WSL_DISTRO, "--", "bash", "-c", wslCmd(cmd)], {
    ...opts,
    stdio,
    cwd: ROOT_WIN,
    env: { ...process.env, ...opts.env },
  });
  if (result.status !== 0 && !opts.ignoreError) {
    console.error(`  Command failed (exit ${result.status}): ${cmd.slice(0, 80)}`);
    process.exit(result.status || 1);
  }
  return result;
}

function runCapture(cmd, opts = {}) {
  try {
    const result = spawnSync("wsl", ["-d", WSL_DISTRO, "--", "bash", "-c", wslCmd(cmd)], {
      ...opts,
      encoding: "utf-8",
      cwd: ROOT_WIN,
      env: { ...process.env, ...opts.env },
      stdio: ["pipe", "pipe", "pipe"],
    });
    if (result.status !== 0 && !opts.ignoreError) {
      throw new Error(`Command failed: ${cmd}`);
    }
    return (result.stdout || "").trim();
  } catch (err) {
    if (opts.ignoreError) return "";
    throw err;
  }
}

function shellQuote(s) {
  if (!/[^a-zA-Z0-9_\-\/\.:=@]/.test(s)) return s;
  return "'" + s.replace(/'/g, "'\\''") + "'";
}

module.exports = { ROOT, ROOT_WIN, SCRIPTS, run, runCapture, runInteractive, shellQuote };
'@
        Set-Content -Path $runnerPath -Value $patchedRunner -Encoding UTF8
        Write-Host "    runner.js patched for WSL." -ForegroundColor DarkGray
    }

    # Patch onboard.js to use ROOT_WIN for Node.js fs operations (Windows paths)
    Write-Host "    Patching onboard.js for Windows path compatibility..." -ForegroundColor DarkGray
    $onboardPath = Join-Path (Join-Path (Join-Path $globalNemoDir "bin") "lib") "onboard.js"
    if (Test-Path $onboardPath) {
        $onboardContent = Get-Content $onboardPath -Raw

        # Import ROOT_WIN alongside ROOT
        $onboardContent = $onboardContent -replace 'const \{ ROOT,([^}]*)\} = require\("\.\/runner"\);', 'const { ROOT, ROOT_WIN,$1} = require("./runner");'

        # Use ROOT_WIN for fs.copyFileSync (line that copies Dockerfile)
        $onboardContent = $onboardContent -replace 'fs\.copyFileSync\(path\.join\(ROOT, "Dockerfile"\)', 'fs.copyFileSync(path.join(ROOT_WIN, "Dockerfile")'

        # Use ROOT_WIN for all path.join(ROOT, ...) used with fs operations or passed to run()
        # path.join on Windows converts forward slashes to backslashes, breaking WSL paths
        # ROOT_WIN gives proper Windows paths that winToWslPath() in run() can convert
        $onboardContent = $onboardContent -replace 'path\.join\(ROOT,', 'path.join(ROOT_WIN,'

        # Add CRLF line-ending fix after build context copies
        $crlfFixLine = '  run(`find $' + '{buildCtx} -type f \\( -name "*.sh" -o -name "*.js" -o -name "*.py" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.ts" -o -name "*.mjs" -o -name "Dockerfile" -o -name "Makefile" \\) -exec sed -i "s/\\r$//" {} +`);'
        $anchor = 'run(`rm -rf "${buildCtx}/nemoclaw/node_modules"`, { ignoreError: true });'
        $replacement = $anchor + "`n`n  // Fix Windows CRLF line endings -- scripts must have LF for Linux/Docker`n" + $crlfFixLine
        $onboardContent = $onboardContent.Replace($anchor, $replacement)

        Set-Content -Path $onboardPath -Value $onboardContent -Encoding UTF8
        Write-Host "    onboard.js patched." -ForegroundColor DarkGray
    }

    # Patch policies.js to use ROOT_WIN for Node.js fs operations
    Write-Host "    Patching policies.js for Windows path compatibility..." -ForegroundColor DarkGray
    $policiesPath = Join-Path (Join-Path (Join-Path $globalNemoDir "bin") "lib") "policies.js"
    if (Test-Path $policiesPath) {
        $policiesContent = Get-Content $policiesPath -Raw
        $policiesContent = $policiesContent -replace 'const \{ ROOT,([^}]*)\} = require\("\.\/runner"\);', 'const { ROOT, ROOT_WIN,$1} = require("./runner");'
        $policiesContent = $policiesContent -replace 'path\.join\(ROOT,', 'path.join(ROOT_WIN,'
        Set-Content -Path $policiesPath -Value $policiesContent -Encoding UTF8
        Write-Host "    policies.js patched." -ForegroundColor DarkGray
    }

    # Create the bin shim (nemoclaw.cmd) in the npm prefix directory
    $binSource = Join-Path (Join-Path $globalNemoDir "bin") "nemoclaw.js"
    if (-not (Test-Path $binSource)) {
        # Clean up and fail
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        throw "NemoClaw bin/nemoclaw.js not found in cloned repo."
    }

    $shimCmd = Join-Path $npmGlobalPrefix "nemoclaw.cmd"
    $shimPs1 = Join-Path $npmGlobalPrefix "nemoclaw.ps1"

    # Write .cmd shim (for cmd.exe)
    $cmdContent = "@ECHO off`r`nGOTO :find_dp0`r`n:find_dp0`r`nSET dp0=%~dp0`r`n:EOF`r`n@SETLOCAL`r`n@SET PATHEXT=%PATHEXT:;.JS;=;%`r`nnode ""%dp0%\node_modules\nemoclaw\bin\nemoclaw.js"" %*"
    [System.IO.File]::WriteAllText($shimCmd, $cmdContent)

    # Write .ps1 shim (for PowerShell)
    $ps1Content = @'
#!/usr/bin/env pwsh
$basedir=Split-Path $MyInvocation.MyCommand.Definition -Parent

$exe=""
if ($PSVersionTable.PSVersion -lt "6.0" -or $IsWindows) {
  $exe=".exe"
}
$ret=0
if (Test-Path "$basedir/node$exe") {
    & "$basedir/node$exe"  "$basedir/node_modules/nemoclaw/bin/nemoclaw.js" $args
    $ret=$LASTEXITCODE
} else {
    & "node$exe"  "$basedir/node_modules/nemoclaw/bin/nemoclaw.js" $args
    $ret=$LASTEXITCODE
}
exit $ret
'@
    [System.IO.File]::WriteAllText($shimPs1, $ps1Content)

    Write-Host "    Created bin shims: nemoclaw.cmd, nemoclaw.ps1" -ForegroundColor DarkGray

    # Clean up temp dir
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                 [System.Environment]::GetEnvironmentVariable('Path', 'User')

    # Verify
    if (Test-NemoClawInstalled) {
        $prevEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $v = & nemoclaw --version 2>$null
        $ErrorActionPreference = $prevEAP
        Write-Host "    NemoClaw $v installed successfully." -ForegroundColor Green
    }
    else {
        Write-Host "    NemoClaw files installed. Restart your terminal if 'nemoclaw' is not found." -ForegroundColor Yellow
    }
}

function Initialize-NemoClawConfig {
    param(
        [string]$SandboxName = 'openclaw'
    )

    Write-NemoStep "Configuring NemoClaw"

    $configDir = Join-Path $env:USERPROFILE '.nemoclaw'
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    $config = @{
        sandboxName       = $SandboxName
        blueprintVersion  = 'latest'
        blueprintRegistry = 'ghcr.io/nvidia/nemoclaw-blueprint'
        inferenceProvider = 'openrouter'
        installedBy       = 'moonclaw'
        installDate       = (Get-Date -Format 'yyyy-MM-dd')
    }

    $configPath = Join-Path $configDir 'config.json'
    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8

    Write-Host "    Config written to $configPath" -ForegroundColor Green
    return $configPath
}
