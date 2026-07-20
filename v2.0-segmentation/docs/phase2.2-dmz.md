mkdir v3.0-monitoring\docs# Phase 2.2 — DMZ Implementation

## Overview

Following VLAN segmentation in Phase 2.1, the next step was building a
**Demilitarized Zone (DMZ)** — a dedicated area for services that need
to be reachable from the internet, without exposing the internal network
directly.

The DMZ's purpose is to separate public-facing servers from internal
assets, so that if a public server is compromised, the attacker cannot
pivot directly into the organization's internal network.

In SecureNet Enterprise Lab, the DMZ is implemented using **MikroTik
RouterOS** as the edge router/firewall, with **Nginx Reverse Proxy** as
the single entry point into the application server behind it.

## Objectives

- Separate public-facing services from the internal network
- Reduce the attack surface exposed to the LAN
- Restrict inter-zone access via firewall policy
- Use a reverse proxy as a single, controlled entry point
- Establish an enterprise-style foundation for the monitoring and
  threat detection work in Phase 3

## Initial Architecture

```
Internet
  │
  ISP
  │
MikroTik Router
  │
LAN Server
```

In the original flat design, all servers sat on the same network, with
no separation between internal and public-facing services. This had
several weaknesses: every server shared the same broadcast domain, a
public-facing server could talk directly to the LAN, and a successfully
exploited web server would give an attacker a direct path for lateral
movement into internal systems.

## Target Architecture

```
Internet
  │
  ISP
  │
MikroTik RouterOS
  ├───────────────┐
  │               │
 LAN             DMZ
  │               │
 PC        Nginx Reverse Proxy
                   │
           Application Server
```

Only the reverse proxy is reachable from the internet. The application
server itself sits behind it and is never exposed directly.

## MikroTik Firewall Policy

The firewall follows a **default-deny** posture. Core rules:

| Rule                  | Action                                   |
| --------------------- | ---------------------------------------- |
| Internet → DMZ        | Allow, restricted to required ports only |
| Internet → LAN        | Deny                                     |
| DMZ → LAN             | Deny                                     |
| LAN → DMZ             | Allow, scoped to administrative access   |
| Established & Related | Allow                                    |

This follows a Zero Trust approach — inter-zone communication must be
explicitly permitted, never assumed.

## Reverse Proxy

Nginx serves as the reverse proxy. Its role:

- Accepts requests from the internet
- Forwards requests to the internal web server
- Hides the backend server's real IP address
- Simplifies future SSL/TLS implementation

With this in place, the backend application is never directly exposed
to the internet.

## Port Forwarding

MikroTik uses Destination NAT (dst-nat) to route inbound traffic:

```
Internet → Public IP → MikroTik dst-nat → Nginx Reverse Proxy → Backend Application
```

Only HTTP/HTTPS traffic is forwarded to the reverse proxy; all other
ports remain closed at the firewall.

## Problems Encountered

### Problem 1 — SSH sessions frequently disconnected

**Symptoms:** SSH connections to the server dropped repeatedly, even
with no configuration changes.

**Root cause:** The firewall had not been configured to allow
**Established** and **Related** connection states, so return traffic
was silently dropped.

**Resolution:** Added explicit firewall rules accepting `established`
and `related` traffic. SSH connections became stable afterward.

### Problem 2 — Web service unreachable from the internet

**Symptoms:** Port forwarding was configured, but the site could not
be reached from outside the network.

**Root cause:** Destination NAT existed, but the firewall filter had
not been updated to permit traffic toward the DMZ.

**Resolution:** Added a firewall filter rule explicitly allowing
HTTP/HTTPS traffic to reach the reverse proxy.

### Problem 3 — Backend server directly accessible

**Symptoms:** The backend could still be reached directly via its own
IP address, bypassing the reverse proxy entirely.

**Root cause:** The firewall had not been configured to block direct
access to the backend.

**Resolution:** All public access was routed exclusively through the
reverse proxy; direct access to the backend was explicitly blocked at
the firewall.

## Security Validation

| Test                             | Result                           |
| -------------------------------- | -------------------------------- |
| Access website from the internet | ✅ Successful, via reverse proxy |
| Access backend server directly   | ✅ Rejected by firewall          |
| Access internal network from DMZ | ✅ Rejected by firewall          |
| Administer DMZ from LAN          | ✅ Successful                    |

## Security Benefits

- Isolation of public-facing servers from the internal network
- Reduced likelihood of lateral movement
- Easier traffic monitoring
- Foundation for IDS/IPS integration in the next phase
- Alignment with enterprise security practice

## Lessons Learned

- Network segmentation alone provides no real protection without strict
  firewall policy behind it.
- A reverse proxy adds a meaningful layer of protection by hiding the
  backend server entirely.
- Established/Related rules are essential for stable connections —
  address-based rules alone don't distinguish new connection attempts
  from legitimate return traffic.
- Least privilege should be applied to every inter-zone communication
  path from the start, not retrofitted later.

## Outcome

- DMZ network established
- MikroTik firewall segmentation in place
- Reverse proxy architecture implemented
- Secure port forwarding configured
- Public services fully isolated from internal assets

**Status: Complete**
