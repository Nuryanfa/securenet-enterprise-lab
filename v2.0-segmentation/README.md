# v2.0 — Network Segmentation & Enterprise Services

Status: 🟡 In Progress (v2.1 — VLAN implemented, v2.2-v2.4 pending)

## Goal

Extend the v1.0 foundation with proper enterprise-grade segmentation
and secure connectivity: VLAN, DMZ, and VPN (remote access + site-to-site).

## Architecture Blueprint

Full architecture blueprint: [../docs/architecture/v2-v3-architecture-blueprint.md](../docs/architecture/v2-v3-architecture-blueprint.md)

> Two deviations from the original blueprint were made during hands-on
> implementation (DMZ renumbered from VLAN 99 to VLAN 30, Finance VLAN
> deferred) — see the note at the top of the blueprint and the
> implementation log below for details.

## Planned Sub-Milestones

- [x] v2.1 — VLAN (trunking, inter-VLAN routing, access port policy) — **implemented**
- [ ] v2.2 — DMZ (isolated public-facing service segment) — VLAN created, service deployment pending
- [ ] v2.3 — VPN Remote Access (WireGuard)
- [ ] v2.4 — VPN Site-to-Site (simulated branch office)

See [../ROADMAP.md](../ROADMAP.md) for full details.

## v2.1 Implementation Log

Getting a working 802.1Q trunk between a router and a switch running
entirely inside Oracle VirtualBox surfaced a chain of issues spanning
build-out mistakes, Layer 2/3 misconfiguration, and — ultimately — a
hypervisor-level setting that silently broke connectivity despite every
RouterOS configuration being correct. The full diagnostic process is
documented in two companion documents rather than folded into a single
"it works now" summary, since the debugging process itself is a
meaningful part of what this project demonstrates:

- [`docs/phase2-problems-found.md`](./docs/phase2-problems-found.md) —
  every issue encountered, documented as found, without resolutions
- [`docs/phase2-troubleshooting.md`](./docs/phase2-troubleshooting.md) —
  the systematic layer-by-layer diagnostic process, root causes, and
  fixes applied for each issue

**Root cause worth highlighting:** the network-wide connectivity failure
(VLAN tagging, bridge, PVID, routing, firewall, and NAT all verified
correct, yet nothing could reach even its own gateway) turned out to be
caused by VirtualBox's Internal Network adapters defaulting **Promiscuous
Mode to "Deny"** — silently dropping frames at the hypervisor level
before RouterOS ever processed them. This is the kind of failure that
software-level configuration review alone cannot catch, and is a useful
reminder that virtualized lab environments introduce failure modes that
don't exist on physical hardware.

### Current VLAN scheme (as implemented)

| VLAN | Segment | Subnet | Gateway |
|---|---|---|---|
| 10 | IT | `192.168.10.0/24` | `192.168.10.1` |
| 20 | Guest | `192.168.20.0/24` | `192.168.20.1` |
| 30 | DMZ | `192.168.30.0/24` | `192.168.30.1` |
| 50 | Security | `192.168.50.0/24` | `192.168.50.1` |

Finance (VLAN 40) is deferred, not dropped — the trunk/switch design
already supports adding it later with just a new access port and VLAN
sub-interface, no re-architecture required.

## Contents (once complete)

- `configs/` — Sanitized configuration exports
- `diagrams/` — Updated network architecture diagrams
- `docs/` — Implementation logs and troubleshooting records
- `screenshots/` — Implementation and testing evidence
