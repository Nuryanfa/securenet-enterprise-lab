# Phase 3.4 — Windows Sysmon Integration

## Overview

With Linux host monitoring established via Auditd, the next step
extended endpoint visibility to Windows using Microsoft Sysinternals'
**Sysmon**. Sysmon provides significantly richer telemetry than the
default Windows Event Log — process creation, network connections,
file creation, registry modification, and process injection can all be
recorded in detail. The Wazuh Agent collects Sysmon events via the
Windows Event Channel and forwards them to the Wazuh Manager on
Oracle Cloud.

## Objectives

- Improve visibility on Windows endpoints
- Detect suspicious activity
- Monitor user-initiated processes
- Identify persistence mechanisms
- Centralize endpoint telemetry collection

## Architecture

```
Windows Endpoint
  │
Microsoft Sysmon
  │
Windows Event Channel
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

**Microsoft Sysmon** — part of the Sysinternals Suite, runs as a
Windows service. Captures events including process creation, process
termination, network connections, driver loads, DLL loads, registry
modifications, file creation, image loads, and process access.

**Sysmon Configuration** — an XML file defining which events get
recorded. The configuration used here is focused on events with high
security value, keeping log volume manageable rather than capturing
everything indiscriminately.

**Wazuh Agent** — reads the Sysmon Windows Event Channel and forwards
events to Oracle Cloud. No additional parser was needed, since Wazuh
already ships with a built-in decoder for Sysmon.

## Problems Encountered

### Problem 1 — Sysmon service not running

**Symptoms:** No Sysmon events appeared in Event Viewer.

**Root cause:** Sysmon was either not installed or the service was not
active.

**Resolution:** Installed Sysmon and confirmed the service was running
correctly.

### Problem 2 — Events not appearing in Wazuh

**Symptoms:** Event Viewer showed Sysmon logs, but the Wazuh Dashboard
remained empty.

**Root cause:** The Windows Event Channel monitor for Sysmon had not
been enabled in the Wazuh Agent configuration.

**Resolution:** Enabled monitoring for
`Microsoft-Windows-Sysmon/Operational` in the agent configuration and
restarted the Wazuh Agent.

### Problem 3 — Excessive log volume

**Symptoms:** The Dashboard was flooded with low-value, informational
events.

**Root cause:** The Sysmon configuration was too permissive, capturing
nearly all activity indiscriminately.

**Resolution:** Switched to a more selective Sysmon configuration
focused on security-relevant events only.

### Problem 4 — Network connections not being recorded

**Symptoms:** Process creation events appeared, but network
connections did not.

**Root cause:** The Network Connection event ID was not enabled in the
Sysmon configuration.

**Resolution:** Adjusted the Sysmon configuration to include network
connection events.

## Validation

| Test               | Expected Result                           | Status     |
| ------------------ | ----------------------------------------- | ---------- |
| Run Command Prompt | Process creation appears in the Dashboard | ✅ Success |
| Run PowerShell     | PowerShell execution logged               | ✅ Success |
| Visit a website    | Network connection event captured         | ✅ Success |
| Create a new file  | File creation event recorded              | ✅ Success |

## Security Benefits

- Endpoint visibility
- Process monitoring
- Command execution logging
- Network connection monitoring
- Malware investigation support
- Threat hunting capability

## Lessons Learned

- The default Windows Event Log alone isn't sufficient for meaningful
  security monitoring.
- Sysmon provides substantially richer telemetry suited for SOC-level
  visibility.
- Wazuh's built-in Sysmon decoder made integration straightforward.
- Sysmon configuration needs to be tuned deliberately — broad enough to
  catch meaningful activity, but not so broad that signal is lost in
  noise.

## Outcome

- Windows endpoint monitoring established
- Process visibility confirmed
- Network activity monitoring in place
- Centralized event collection via Oracle Cloud Wazuh integration

**Status: Complete**
