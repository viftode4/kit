# Safe to evaluate with irm | iex: options come from the environment.
& {
    $ErrorActionPreference = 'Stop'
    $PSNativeCommandUseErrorActionPreference = $false
    $User = if ($env:KIT_USER) { $env:KIT_USER } else { 'viftode4' }
    if ($User -notmatch '^[A-Za-z0-9][A-Za-z0-9-]{0,38}$') {
        throw 'KIT_USER must be a GitHub username.'
    }
    # KIT_SERVER is inherited by hq; its meaning belongs to the private setup.
    $Server = $env:KIT_SERVER
    if ($Server) { $env:KIT_SERVER = $Server }

    function Update-KitPath {
        # Keep session-only paths, including version-manager shims.
        $paths = @(
            [Environment]::GetEnvironmentVariable('Path', 'Machine')
            [Environment]::GetEnvironmentVariable('Path', 'User')
            "$HOME\.local\bin"
            "$env:LOCALAPPDATA\Microsoft\WinGet\Links"
            $env:Path
        )
        $env:Path = ($paths | Where-Object { $_ }) -join ';'
    }

    function Install-KitDependency([string]$Command, [string]$Package) {
        if (Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue) {
            return
        }
        if (-not (Get-Command winget -CommandType Application -ErrorAction SilentlyContinue)) {
            throw 'winget is required. Install Microsoft App Installer, then rerun this command.'
        }
        Write-Host "Installing $Package..."
        & winget install --id $Package --exact --source winget --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
            throw "winget could not install $Package (exit $LASTEXITCODE)."
        }
        Update-KitPath
        if (-not (Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue)) {
            throw "$Package was installed but $Command is unavailable. Open a new terminal and rerun."
        }
    }

    Update-KitPath
    Install-KitDependency git Git.Git
    Install-KitDependency gh GitHub.cli
    Install-KitDependency chezmoi twpayne.chezmoi
    Install-KitDependency uv astral-sh.uv
    Install-KitDependency node OpenJS.NodeJS.LTS

    & gh auth status --hostname github.com
    if ($LASTEXITCODE -ne 0) {
        & gh auth login --web --git-protocol https --hostname github.com
        if ($LASTEXITCODE -ne 0) { throw 'GitHub authentication failed.' }
    }
    & gh auth setup-git --hostname github.com
    if ($LASTEXITCODE -ne 0) { throw 'GitHub Git credential setup failed.' }

    if (Test-Path -LiteralPath "$HOME/.local/share/chezmoi" -PathType Container) {
        # Re-run = fresh, clean copy of hq (old one kept aside); never merges a stale or stuck copy.
        Move-Item "$HOME/.local/share/chezmoi" "$HOME/.local/share/chezmoi.old-$(Get-Date -Format yyyyMMddHHmmss)"
    }
    & chezmoi init --apply --force "https://github.com/$User/hq.git"
    if ($LASTEXITCODE -ne 0) { throw 'chezmoi setup failed; fix the reported error and rerun.' }
    Write-Host 'kit setup complete.'
}
