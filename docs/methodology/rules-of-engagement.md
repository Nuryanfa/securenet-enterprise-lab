# Rules of Engagement

This document defines the scope, authorization, and boundaries for all
offensive security testing performed within the SecureNet Enterprise Lab
project. It is written and followed in the same spirit as a real
penetration testing engagement, even though this is a self-contained,
self-authorized lab.

## Purpose

Attack simulation is only meaningful — and only responsible — when its
scope is explicit. This document exists so that anyone reviewing this
repository (recruiters, engineers, or future collaborators) can see
exactly what was tested, where, and under what constraints.

## Scope

**In scope:**
- All virtual machines and network segments within the SecureNet
  Enterprise Lab environment, hosted entirely on infrastructure I own
  and control (local VirtualBox environment, and cloud instances
  provisioned specifically for this project from v6.0 onward)
- The MikroTik CHR router and all its configured services
  (DHCP, Firewall, NAT, Hotspot, QoS)
- Any monitoring/detection tooling deployed as part of v3.0 onward
  (Wazuh, Suricata)

**Out of scope (never tested):**
- Any production system, third-party service, or network I do not own
  or have not explicitly provisioned for this lab
- Any public internet infrastructure
- Any system belonging to my university, employer, or any organization,
  even incidentally reachable from my testing environment

## Environment Isolation

All attack simulation is performed within a network-isolated lab:
- The lab operates on private/NAT-only virtual networking with no
  bridged access to production networks
- Cloud components (v6.0 onward) are provisioned in a dedicated,
  isolated VPC with no connectivity to any other cloud resource I
  may operate

## Authorization

As the sole owner, architect, and operator of this lab, I am the
authorizing party for all testing performed within it. No external
authorization is required because no system outside my direct
ownership is ever in scope.

## Testing Principles

1. **Documented intent before execution** — every attack scenario in
   v4.0 onward is documented (objective, technique, expected outcome)
   before it is executed, not reconstructed afterward.
2. **No destructive testing without rollback plan** — any test with
   potential to disrupt lab availability (e.g. DoS-style scenarios) is
   only run after a known-good snapshot/backup exists.
3. **Full disclosure in documentation** — detection failures are
   documented as thoroughly as detection successes. The goal is
   learning and improving detection coverage, not producing a
   flattering report.
4. **Sanitization before publishing** — before any configuration,
   log, or pcap file is committed to this public repository, it is
   reviewed and sanitized to remove real credentials, license keys,
   or any identifying information beyond the lab itself.

## Data Handling

- No real personal data, production credentials, or third-party
  information is ever used or stored in this lab
- All user accounts, credentials, and sample data used in testing
  scenarios are synthetic and created specifically for this project
