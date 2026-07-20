# Phase 3.2 — Docker Monitoring

## Overview

With network IDS (Suricata) integrated, the next step extended
monitoring coverage down to the container layer. Docker is used as the
containerization platform for several homelab services. To centralize
visibility into container activity, the Wazuh Agent was configured to
collect Docker Engine information and forward it to the Wazuh Manager
on Oracle Cloud — allowing container state to be monitored without
manually checking each host individually.

## Objectives

- Centrally monitor container status
- Collect container inventory
- Detect container lifecycle changes
- Surface Docker information in the Wazuh Dashboard
- Extend visibility to running workloads, not just the host OS

## Architecture

```
Docker Host
  │
Docker Engine
  │
Docker API
  │
Wazuh Agent (Docker Module)
  │
Encrypted Channel
  │
Oracle Cloud
  Wazuh Manager
  │
  Dashboard
```

## Components

**Docker Engine** — runs all containers on the homelab server. Tracked
metadata includes container name, container ID, image, status, runtime,
and creation time.

**Wazuh Agent** — uses its Docker module to read information directly
from the Docker Engine, collecting data periodically and forwarding it
to the Wazuh Manager.

**Wazuh Manager** — receives Docker information as part of each
endpoint's inventory, indexing it so it can be visualized through the
Dashboard.

## Problems Encountered

### Problem 1 — Docker module not collecting inventory

**Symptoms:** The Wazuh Dashboard showed no Docker information despite
Docker running normally.

**Root cause:** The Docker listener had not been enabled in the Wazuh
Agent configuration.

**Resolution:** Enabled the Docker module in the agent configuration
and restarted the Wazuh Agent.

### Problem 2 — Permission denied

**Symptoms:** The Wazuh Agent failed to read the Docker daemon.

**Root cause:** The user running the agent lacked access to the Docker
socket.

**Resolution:** Granted the appropriate permissions on the Docker
socket, allowing the agent to read container information correctly.

### Problem 3 — Inventory not appearing immediately

**Symptoms:** A container was running, but had not yet appeared in the
Dashboard.

**Root cause:** Inventory collection runs on a periodic cycle rather
than in real time.

**Resolution:** Waited for the next inventory cycle, or restarted the
agent to trigger synchronization sooner.

## Validation

| Test | Result |
|---|---|
| Start a new container | ✅ Detected correctly |
| Stop a container | ✅ Status updated in the Dashboard |
| Remove a container | ✅ Inventory updated accordingly |
| Metadata verification | ✅ Container name, ID, image, runtime, and status all displayed correctly |

## Security Benefits

- Asset visibility across containerized workloads
- Container inventory tracking
- Lifecycle monitoring (start/stop/remove)
- Centralized monitoring alongside host-level data
- Faster incident investigation when container-related activity is
  involved

## Lessons Learned

- Containers are part of the attack surface and need monitoring just
  like any other workload.
- Container inventory helps establish what's actually running on a
  given host at any point in time.
- Docker integration with Wazuh is relatively straightforward thanks to
  the built-in module — no custom tooling was required.
- Container-level monitoring complements host-level monitoring rather
  than replacing it, improving overall visibility.

## Outcome

- Docker inventory monitoring in place
- Container visibility established
- Centralized monitoring via Oracle Cloud integration

**Status: Complete**
