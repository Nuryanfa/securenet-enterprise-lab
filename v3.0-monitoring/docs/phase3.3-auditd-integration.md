# Phase 3.3 — Linux Auditd Integration

## Overview

With network (Suricata) and container (Docker) monitoring in place, the
next step was improving visibility into Linux operating system activity
using the **Linux Audit Framework (auditd)**. Auditd records
security-relevant activity at the kernel level — file changes, specific
command executions, privilege changes, and authentication events. Audit
logs are collected by the Wazuh Agent and forwarded to the Wazuh
Manager on Oracle Cloud, centralizing host-level activity monitoring.

## Objectives

- Monitor important activity on Linux systems
- Detect changes to sensitive files
- Identify privilege escalation attempts
- Track administrator activity
- Extend host visibility within Wazuh

## Architecture

```
Linux Host
  │
auditd
  │
audit.log (/var/log/audit/)
  │
Wazuh Agent
  │
Secure TLS Connection
  │
Oracle Cloud Wazuh Manager
  │
Wazuh Dashboard
```

## Components

**Linux Audit Framework (auditd)** — a kernel-level subsystem that
records security events including file access, file modification, user
authentication, privilege escalation, command execution, and permission
changes.

**Audit Rules** — define exactly which activities get recorded, for
example changes to `/etc/passwd`, `/etc/shadow`, `/etc/sudoers`, SSH
configuration, user management actions, and permission changes.

**Wazuh Agent** — reads `audit.log` and forwards events to the Wazuh
Manager. No additional parser was needed, since Wazuh already ships
with a built-in decoder for auditd.

## Problems Encountered

### Problem 1 — Auditd not generating logs

**Symptoms:** The Wazuh Dashboard showed no auditd events.

**Root cause:** The `auditd` service was not running.

**Resolution:**
```bash
sudo systemctl enable auditd
sudo systemctl start auditd
```

### Problem 2 — Audit rules not active

**Symptoms:** File system changes were not producing alerts.

**Root cause:** No rules had been defined to specify which objects to
monitor.

**Resolution:** Added audit rules and reloaded the configuration.

### Problem 3 — Events not appearing in the Dashboard

**Symptoms:** `audit.log` was growing, but the Dashboard remained
empty.

**Root cause:** The Wazuh Agent was not yet reading the audit log.

**Resolution:** Confirmed the `localfile` configuration for auditd was
active, then restarted the Wazuh Agent.

### Problem 4 — Duplicate events

**Symptoms:** A single activity produced multiple alerts.

**Root cause:** The audit rules were too broad, causing the same event
to be logged repeatedly.

**Resolution:** Simplified the audit rules so only meaningful activity
is recorded.

## Validation

| Test | Expected Result | Status |
|---|---|---|
| Modify `/etc/passwd` | Wazuh generates a file integrity alert | ✅ Success |
| Add a new user | Auditd logs the user-management activity | ✅ Success |
| Change file permissions | Permission change appears in the Dashboard | ✅ Success |
| Attempt `sudo` | Privilege escalation attempt is logged | ✅ Success |

## Security Benefits

- User activity monitoring
- Privilege escalation detection
- Sensitive file monitoring
- Compliance-relevant logging
- Improved incident investigation capability

## Lessons Learned

- Not every important activity can be captured through File Integrity
  Monitoring alone.
- Auditd provides kernel-level visibility, capturing more detail than
  FIM by itself.
- Wazuh's built-in auditd decoder made integration straightforward.
- Audit rules need careful scoping — overly broad rules generate
  excessive, low-value event volume.

## Outcome

- Linux audit monitoring in place
- User activity logging established
- Privilege monitoring confirmed
- Centralized log collection via Oracle Cloud Wazuh integration

**Status: Complete**
