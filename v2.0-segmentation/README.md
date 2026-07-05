# v2.0 — Network Segmentation & Enterprise Services

Status: ✅ Complete

## Goal

Extend the v1.0 foundation with proper enterprise-grade segmentation
and secure connectivity: VLAN, DMZ, and VPN (remote access + site-to-site).

## Architecture Blueprint

Full architecture blueprint: [../docs/architecture/v2-v3-architecture-blueprint.md](../docs/architecture/v2-v3-architecture-blueprint.md)

> Deviations from the original blueprint made during hands-on
> implementation (DMZ renumbered from VLAN 99 to VLAN 30, Finance VLAN
> deferred, Branch Office WAN-link redesigned around a dedicated
> point-to-point segment) are documented inline in the blueprint and in
> the implementation logs below.

## Sub-Milestones

- [x] v2.1 — VLAN (trunking, inter-VLAN routing, access port policy)
- [x] v2.2 — DMZ (isolated public-facing service segment, reverse proxy)
- [x] v2.3 — VPN Remote Access (WireGuard)
- [x] v2.4 — VPN Site-to-Site (Branch Office)

See [../ROADMAP.md](../ROADMAP.md) for full details.

## Implementation Log

Each stage surfaced real, non-trivial issues — spanning hypervisor
networking quirks, firewall chain ordering, and VPN NAT traversal — that
required systematic, layer-by-layer diagnosis rather than guesswork.
Full records are kept as separate problems-found / troubleshooting
document pairs, following the same format established in v1.0:

- [`docs/phase2-problems-found.md`](./docs/phase2-problems-found.md) /
  [`docs/phase2-troubleshooting.md`](./docs/phase2-troubleshooting.md) —
  VLAN trunk build-out and the VirtualBox Promiscuous Mode root cause
- [`docs/phase2.3-2.4-problems-found.md`](./docs/phase2.3-2.4-problems-found.md) /
  [`docs/phase2.3-2.4-troubleshooting.md`](./docs/phase2.3-2.4-troubleshooting.md) —
  Branch Office build-out and the WireGuard Site-to-Site NAT hairpin
  resolution

### Highlights worth calling out

**v2.1 — Promiscuous Mode.** VLAN tagging, bridge configuration, PVID,
routing, and firewall were all independently verified correct, yet
connectivity failed completely. Root cause: VirtualBox's Internal
Network adapters default Promiscuous Mode to "Deny," silently dropping
trunk frames at the hypervisor layer before RouterOS ever processed
them — a failure mode entirely outside RouterOS configuration.

**v2.2 — Stateful firewall rules.** DMZ containment rules initially
blocked legitimate return traffic for connections IT had itself
initiated into the DMZ (e.g. SSH), because address-based drop rules
don't distinguish new connection attempts from established return
traffic. Fixed by adding an explicit `established,related` accept rule
ahead of the containment drop rules — the isolation policy itself
required no weakening.

**v2.4 — WireGuard NAT hairpin.** Site-to-Site handshake failed
(`tx` climbing, `rx` stuck at 0) due to VirtualBox's per-VM NAT
isolation preventing symmetric UDP traversal between two routers each
behind their own NAT. Resolved by adding a dedicated point-to-point
Internal Network segment (`ISP-Backbone`, `203.0.113.0/30`) as a direct
Layer 3 link between HQ and Branch — simulating a real WAN link instead
of relying on NAT traversal — without altering the already-validated
v2.1–v2.3 architecture.

### Current VLAN scheme (as implemented)

| VLAN | Segment | Subnet | Gateway |
|---|---|---|---|
| 10 | IT | `192.168.10.0/24` | `192.168.10.1` |
| 20 | Guest | `192.168.20.0/24` | `192.168.20.1` |
| 30 | DMZ | `192.168.30.0/24` | `192.168.30.1` |
| 50 | Security | `192.168.50.0/24` | `192.168.50.1` |

### VPN scheme (as implemented)

| Link | Subnet | Notes |
|---|---|---|
| Remote Access (WireGuard) | `192.168.60.0/24` | Scoped to IT VLAN only |
| Site-to-Site tunnel | `192.168.70.0/30` | HQ ↔ Branch point-to-point |
| Site-to-Site WAN-link | `203.0.113.0/30` | Dedicated segment bypassing NAT hairpin |
| Branch LAN | `172.16.0.0/24` | Dual-homed: tunnel to HQ IT + independent NAT for internet |

Finance (VLAN 40) remains deferred — the trunk/switch design already
supports adding it with just a new access port and VLAN sub-interface.

## Contents

- `configs/` — Sanitized configuration exports
- `diagrams/` — Updated network architecture diagrams
- `docs/` — Implementation logs and troubleshooting records
- `screenshots/` — Implementation and testing evidence
