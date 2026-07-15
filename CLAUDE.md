# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A workspace for monitoring and performance-tuning an **HP Slim Desktop S01-pF2xxx** (Intel Core i3-12100, 16GB RAM, ~238GB NVMe, Ubuntu 22.04 LTS — the user's primary Go dev machine). All changes require measured before/after evidence and must be reversible.

## Key commands

```bash
# Scan machine state → health/<timestamp>-<label>/report.md (no sudo needed)
bin/health-check.sh [label]

# Load benchmarks for before/after measurement (no sudo needed)
bin/bench.sh cpu               # 8-thread 15s sustained freq/temp/throttle
bin/bench.sh ram               # safe RAM pressure → swap/PSI observation
bin/bench.sh disk              # seq + random direct I/O
bin/bench.sh go <dir>          # cold & warm Go build time in <dir>

# Verify all tweaks survived reboot (no sudo needed)
bin/verify-after-reboot.sh

# Apply/rollback individual tweaks (all require sudo)
sudo bash tweaks/tier1a-zram.sh [--rollback]
sudo bash tweaks/tier1b-sysctl.sh [--rollback]
sudo bash tweaks/tier2a-inotify.sh [--rollback]
sudo bash tweaks/tier3a-cleanup-user.sh   # disk cleanup (run as user, not sudo)
sudo bash tweaks/tier3a-cleanup-sudo.sh [--rollback]
sudo bash tweaks/tier3b-noatime.sh [--rollback]

# Update machine-specs.md after hardware changes
sudo bash bin/probe-specs.sh
```

## Architecture

**Health gating:** `bin/health-check.sh` always runs first and determines whether optimization is needed. It is the only fully automatic step. Everything in `tweaks/` requires user approval to run.

**Directory layout by lifecycle:**
- `bin/` — read-only diagnostic tools (safe to run anytime, no system changes)
- `tweaks/` — reusable apply/rollback scripts scoped to one tier each; all require `sudo` and have a `--rollback` flag
- `docs/` — persistent cross-session documentation (hardware spec, threshold guide, living optimization log)
- `health/<timestamp>-<label>/` — one directory per health run; if optimization follows, it lives *inside* that run's directory as `health/<timestamp>-<label>/optimization/`
- `_templates/` — copy-on-demand templates for new health runs and optimization sessions

**Starting a new optimization session from a health run:**
```bash
cp -r _templates/optimization health/<run-dir>/optimization
# then fill in design.md → run tweaks → record steps/ → update tracker.md and docs/machine-optimization.md
```

## Rules for working with this user

1. **No unsolicited sudo.** The machine has no passwordless sudo. Always write sudo commands into a `tweaks/` script and ask the user to run it. Diagnostic reads (`bin/`) you can run directly.
2. **One step at a time with checkpoints.** Apply one tier → measure → report → wait for user approval before proceeding.
3. **All claims need numbers.** "Faster/better" requires actual before/after measurements from `bench.sh` or `/proc` snapshots.
4. **Every tweak must have `--rollback`.** No irreversible changes without explicit user agreement.
5. **Ignore battery.** This is a desktop machine with no battery. Pin 🔴 in health-check output is expected and meaningless — never flag it.

## Current baseline (2026-07-15, post first fix)

| Setting | Value | Mechanism |
|---|---|---|
| zram | lz4, ~7.7GB (PERCENT=50), prio 100 | `/etc/default/zramswap` + `zramswap.service` |
| swappiness | 180 | `/etc/sysctl.d/99-workstation-ram.conf` |
| vfs_cache_pressure | 50 | same file |
| dirty_ratio / dirty_background_ratio | 10 / 5 | same file |
| inotify max_user_watches | 524288 | `/etc/sysctl.d/99-workstation-ide.conf` |
| Mount `/` | noatime (live) | fstab **belum ditulis** — pending 1 command (see machine-optimization.md) |
| Power profile | performance | `powerprofilesctl` (persistence after reboot unconfirmed) |
| GOCACHE | `~/.cache/go-build` | **never delete** — warm cache critical |
| GoLand heap | default (no override) | no `goland64.vmoptions` yet |
| Weekly health timer | **not set up** | pending |

Disk baseline: ~81% (floor — large user data directory ~51G). Pin 🔴 = normal (desktop, no battery).

## Key reference files

- `docs/health-check-guide.md` — threshold table (🟢/🟡/🔴 cutoffs), the AI onboarding section, and full flow diagram
- `docs/machine-specs.md` — immutable hardware reference (read this before asking about CPU/RAM/SSD capabilities)
- `docs/machine-optimization.md` — living doc: current standard config + rollback commands for every applied tweak
- `health/demo/report.md` — example of what a clean health report looks like
