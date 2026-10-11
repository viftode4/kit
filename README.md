# kit

**Your dev environment, everywhere. For you and your agents.**

Sit down at any machine, paste one line, approve GitHub, type your password —
and you're back in your workspace: Claude Code and Codex logged in and configured
your way, every project one sentence away, secrets in place, and the session you
left on your other machine ready to `/resume`.

**Mac / Linux: open Terminal, paste, Enter:**

```sh
curl -fsSL https://raw.githubusercontent.com/viftode4/kit/main/install.sh | sh
```

**Windows: open PowerShell, paste, Enter:**

```powershell
irm https://raw.githubusercontent.com/viftode4/kit/main/install.ps1 | iex
```

## What you get

- **Same setup on every machine.** Claude Code + Codex config, skills, instructions — synced.
- **Pick up where you left off.** Close a session on your laptop, `/resume` it on your desktop.
  Unsaved code follows you too (as a private `wip/<machine>` branch — your branches are never touched).
- **Projects on demand.** Ask your agent *"get polymarket"* — cloned, secrets in place, ready.
- **Always current.** On every session start: clean projects fast-forward from GitHub; anything
  behind, diverged, or changed on another machine is reported to you and your agent.
- **Secrets without the copy-paste.** `.env` files live encrypted in your private repo and merge
  key-by-key across machines — no `.env` ever lands in a project repo.
- **Agents use it themselves.** You just talk to Claude or Codex; they call `kit` when they need a
  project, a secret, or to save. Nothing to memorize.

## How it works

Two repos on your GitHub:

| | |
|---|---|
| `kit` (this one, public) | the one-line installers |
| `<you>/hq` (private) | your config, encrypted vault, synced sessions, and the `kit` CLI — via [chezmoi](https://chezmoi.io) + [age](https://age-encryption.org) |

GitHub login gates access; your vault password unlocks the secrets. Nothing secret is ever public.

## Make your own

Template for your own `hq` is coming soon. Then: create `<you>/hq` from it and run the
one-liner with `KIT_USER=<you>`.
