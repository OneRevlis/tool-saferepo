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

### `vet <git-url>` — scan, run NOTHING (static analysis)
```bash
vet https://github.com/some/repo
```
Clones to a temp dir and checks:
1. Install/build hooks — code that auto-runs on `npm install` / `pip install`
2. Remote-exec & obfuscation patterns (`curl|bash`, `eval`, base64 blobs)
3. Trivy scan — known CVEs in dependencies + leaked secrets/keys

Reading a repo never executes it, so this stage cannot hurt you.

### `sandbox <path> [--no-net|--watch]` — run it isolated (dynamic analysis)
The container sees **only the repo** at `/repo` — no home dir, no SSH keys, no
secrets — and is deleted on exit.

```bash
sandbox /tmp/vet.XXXX/repo --no-net   # safest: network OFF, nothing can phone home
sandbox /tmp/vet.XXXX/repo --watch    # network ON but every connection is LOGGED
sandbox /tmp/vet.XXXX/repo            # network ON (needed by builds that download)
```
Inside the box:
```bash
npm install --ignore-scripts   # install without running install-hooks
npm run build
exit                           # container destroyed, everything gone
```

## The method (why this order)

1. **Assume hostile.** Never `npm install` on the host to "try it out."
2. **Static first** (`vet`): look, don't execute.
3. **Dynamic in a sealed box** (`sandbox`): no host access, no/monitored network, disposable.
4. **Watch** (`--watch`): if it tries to connect somewhere weird, that's the tell.
5. **Destroy.** `--rm` / `exit` throws the environment away.

Honest limit: no scanner catches a novel hand-made backdoor. That's *why* the
sandbox exists — isolation protects you when scanning misses something.

## Golden rules
- Never pipe to a shell: `curl … | bash` = handing over your machine.
- Always `--ignore-scripts` on first install.
- Keep secrets out of the sandbox; if a build needs a token, it's probably not worth the risk.
