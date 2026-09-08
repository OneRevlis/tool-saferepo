# security-sandbox-kit

My workflow for safely downloading and running untrusted repos. The rule:
**assume every repo is hostile until proven otherwise.** Look before you run;
run only inside a disposable box that can't see my real machine.

## Setup (any computer)

1. Install [Docker Desktop](https://docker.com/products/docker-desktop) and start it.
2. Copy this folder to the machine, then:
   ```bash
   ./install.sh
   ```
   Restart the terminal. Done.

> **Windows:** run everything inside **WSL2** (Ubuntu) or **Git Bash**. Docker
> Desktop with the WSL2 backend makes the exact same commands work.

## The two commands

### `saferepo add <git-url>` — onboard a repo once, then reuse it
```bash
saferepo add https://github.com/some/repo
saferepo list      # everything you've triaged + where it lives
```
Clones it inside a container (never host git) and checks:
1. **GuardDog** (Datadog) — *malicious* npm dependencies: typosquats, exfil,
   bundled binaries, install-time payloads
2. **Trivy** — known CVEs + leaked secrets
3. **curl|wget → shell** in the repo's own source (the one hard block)
4. **AI triage** (DeepSeek) — explains any GuardDog-flagged package as likely
   false-positive vs suspicious (advisory only, never decides pass/fail)

Passing = **"no known red flags"**, NOT proof. It tells you to build & run in
`sandbox` (install-scripts off), and records the repo + commit so you don't re-vet
every launch. A `curl|bash` in the source → refuses to record.

> **Scope:** the malicious-package scan is **npm-only**. Python/Go/Rust get the
> shell + secret/vuln checks but no dependency-malware scan — treat those extra
> carefully.

### `sandbox <path> [--net|--watch]` — run it isolated (dynamic analysis)
Safe by default: **network OFF**, runs as **non-root**, host repo mounted
**read-only** at `/src` (you work on a throwaway copy in `~/app`, so a hostile
build can't write trojans back to your disk), no home dir / SSH keys / secrets.

```bash
sandbox ~/repos/some-repo            # DEFAULT: network OFF — nothing phones home
sandbox ~/repos/some-repo --net      # network ON (builds that download); host FS still safe
sandbox ~/repos/some-repo --watch    # network ON + every connection LOGGED (tripwire)
```
Inside the box:
```bash
npm ci --ignore-scripts   # install without running install-hooks
npm run build
exit                      # container destroyed, everything gone
```

> **`sandbox` is the load-bearing control; `saferepo` is only triage.** Never let
> "it passed triage" override suspicion — build and run in the sandbox first.
> Docker is not a VM: for genuinely targeted/hostile code, escalate to a
> disposable VM (Lima/UTM) or a throwaway cloud Codespace.

## The method (why this order)

1. **Assume hostile.** Never `npm install` on the host to "try it out."
2. **Triage first** (`saferepo add`): scan, don't execute.
3. **Build & run in a sealed box** (`sandbox`): no host access, install-scripts off, disposable.
4. **Only then native.** A GUI app you've built & trust runs natively — ideally under a separate macOS user.
5. **Destroy.** `--rm` / `exit` throws the environment away.

Honest limit: no scanner catches a novel hand-made backdoor, and Docker is not a
hard VM boundary. That's *why* the sandbox + build-from-source come first —
triage is a filter, isolation is the control.

## Golden rules
- Never pipe to a shell: `curl … | bash` = handing over your machine.
- Always `--ignore-scripts` on first install.
- Keep secrets out of the sandbox; if a build needs a token, it's probably not worth the risk.
