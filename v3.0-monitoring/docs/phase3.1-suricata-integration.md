# Phase 3.1 — Suricata IDS Integration

## Overview

With Phase 3, SecureNet Enterprise Lab's focus shifted from
infrastructure build-out to **security monitoring**. The first
component integrated was **Suricata**, a network-based intrusion
detection system (IDS).

Rather than relying solely on endpoint-level analysis, Suricata adds
real-time network detection — port scanning, exploit attempts, malware
communication, and other suspicious traffic patterns. All Suricata
alerts are forwarded to **Wazuh SIEM**, running on Oracle Cloud, so
that network and host security events can be reviewed from a single
centralized dashboard.

## Objectives

- Add network IDS capability to the homelab
- Forward IDS alerts to the Wazuh SIEM
- Centralize monitoring on the cloud
- Provide network traffic visibility
- Lay the groundwork for threat detection work in later phases

## Architecture

```
Internet
  │
MikroTik
  │
SPAN / Mirror Port
  │
Ubuntu IDS Node
  Suricata
  │
eve.json
  │
Wazuh Agent
  │
Encrypted Channel (1514/TCP)
  │
Oracle Cloud
  Wazuh Manager
  │
  Dashboard
```

Suricata is purely a monitoring component in this architecture — all
correlation and visualization happen on the Wazuh side, in Oracle Cloud.

## Components

**Suricata** — functions as the network IDS. Its primary output types
include alerts, flow records, DNS, HTTP, TLS, and file info events, all
written as JSON to `/var/log/suricata/eve.json`.

**Wazuh Agent** — reads `eve.json` in real time via a `localfile`
monitor and forwards every event to the Wazuh Manager.

**Wazuh Manager** — running on Oracle Cloud, receives events from all
agents and performs decoding, rule matching, indexing, and
visualization. For Suricata specifically, **Wazuh's built-in decoder**
already supports the `eve.json` structure — no custom decoder was
required.

## Problems Encountered

### Problem 1 — Suricata not generating alerts

**Symptoms:** Traffic was passing through the monitored interface, but
no alerts appeared.

**Root cause:** The Suricata rule set had not been fully loaded.

**Resolution:** Ran `suricata-update` to pull the current ruleset, then
restarted the Suricata service.

### Problem 2 — Alerts not appearing in the Wazuh Dashboard

**Symptoms:** Suricata was generating alerts in `eve.json`, but nothing
appeared in the Wazuh Dashboard.

**Root cause:** The Wazuh Agent was not yet configured to monitor
`eve.json`.

**Resolution:** Added the corresponding `localfile` monitoring block to
the agent configuration and restarted the agent. Events began arriving
at the Manager immediately after.

### Problem 3 — Verifying decoder coverage

**Symptoms:** Needed to confirm whether Wazuh could correctly parse
Suricata's JSON structure end to end.

**Investigation:** Tested using several ET Open ruleset alerts. Wazuh
correctly extracted signature, severity, source IP, destination IP,
protocol, and timestamp — all using the **built-in decoder**.

**Resolution:** No custom decoder or custom rule was required. The
integration works out of the box using Wazuh's official decoder support
for Suricata's `eve.json` format.

## Validation

| Test | Result |
|---|---|
| Generate ICMP traffic | ✅ Recorded in `eve.json` |
| Generate a port scan | ✅ Suricata generated an ET Scan alert |
| Alert delivery to Wazuh | ✅ Alert appeared in the Wazuh Dashboard |
| Field verification | ✅ Rule name, rule level, source/destination IP, signature, and timestamp all correctly populated |

## Security Benefits

- Network-level visibility
- Real-time IDS monitoring
- Centralized SIEM correlation
- Historical event storage
- Threat investigation capability

## Lessons Learned

- Suricata's role is limited to generating network events — Wazuh is
  what collects and correlates them into actionable security context.
- Wazuh's built-in decoder already supports `eve.json`, which
  significantly simplifies the integration.
- Separating IDS (local) from SIEM (cloud) improves overall system
  scalability without sacrificing detection fidelity.

## Outcome

- Suricata IDS operational
- Network threat detection in place
- Centralized monitoring via Oracle Cloud SIEM
- Real-time security alerting confirmed end to end

**Status: Complete**
