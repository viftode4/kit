# kit

One command brings your Claude Code + Codex setup to a new machine. This public
repo installs Git, GitHub CLI, chezmoi, uv, and Node.js, signs in to GitHub, then
applies your private `<user>/hq` repo. hq installs Claude Code, Codex, and the
`kit` CLI and restores your configuration and encrypted vault.

**Mac / Linux: open Terminal, paste, Enter:**

```sh
curl -fsSL https://raw.githubusercontent.com/viftode4/kit/main/install.sh | sh
```

**Windows: open PowerShell, paste, Enter:**

```powershell
irm https://raw.githubusercontent.com/viftode4/kit/main/install.ps1 | iex
```

Approve GitHub access in your browser (a headless server prints a device code),
then enter your vault password once when hq asks. Package installation may also
require administrator approval or your sudo password. macOS uses Homebrew;
Debian/Ubuntu support root or sudo; Fedora is best effort. A minimal Linux image
needs curl installed to run the one-liner.

Rerun the same command to update and apply an existing
`~/.local/share/chezmoi` checkout. Existing tools are reused; the Unix installer
upgrades Node.js below 20 (NodeSource 22 on Debian/Ubuntu, LTS 24 on macOS).

**Bring your own setup — template coming soon.** Create a private `<you>/hq`
from the forthcoming template and configure your own encrypted vault. The default
owner is `viftode4`; override it before running the installer:

```powershell
$env:KIT_USER = 'your-github-user' # then run the Windows one-liner
```

```sh
curl -fsSL https://raw.githubusercontent.com/viftode4/kit/main/install.sh | KIT_USER=your-github-user sh
```

`KIT_SERVER`, if set, is passed through to hq for its server-specific setup.
Changing `KIT_USER` does not switch an existing chezmoi checkout.
This repo contains no vault, credentials, or private configuration.
