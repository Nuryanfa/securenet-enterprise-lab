# Architecture Blueprint — v2.0 & v3.0

Status: Design finalized, pending implementation
Supersedes: initial v2.0/v3.0 planning notes in ROADMAP.md

This document is the single source of truth for the network segmentation
(v2.0) and monitoring/automated response (v3.0) architecture. It exists
because these two versions are tightly coupled — the Security VLAN
introduced in v2.0 only makes sense in light of what gets deployed there
in v3.0.

> **Implementation note (updated after v2.1 execution):** two deliberate
> deviations from the original design below were made during hands-on
> implementation, documented here for traceability rather than silently
> editing history:
>
> 1. **DMZ was renumbered from VLAN 99 to VLAN 30** — purely for
>    operational convenience (easier to remember/type consistently
>    across five interfaces during hands-on config), no functional
>    difference in isolation policy.
> 2. **The Finance VLAN (40) was deliberately deferred**, not dropped.
>    With five interfaces already in play across the router and switch
>    (Trunk, IT, Guest, DMZ, Security), adding a sixth to monitor during
>    initial bring-up and troubleshooting was judged to add risk without
>    proportional learning value at this stage. Finance will be added as
>    a follow-up once the current four-VLAN topology is fully stable —
>    the trunk/switch design already supports it without any
>    re-architecture, only a new access port and VLAN sub-interface.
>
> See [`v2.0-segmentation/docs/phase2-problems-found.md`](../../v2.0-segmentation/docs/phase2-problems-found.md)
> and [`v2.0-segmentation/docs/phase2-troubleshooting.md`](../../v2.0-segmentation/docs/phase2-troubleshooting.md)
> for the full implementation and debugging record.

---

## 1. Design Principles

1. **Out-of-band management** — the Management network never joins the
   VLAN trunk. If the trunk or switch is compromised, administrative
   access to the router remains on a physically separate path.
2. **Default-deny between all zones** — no VLAN trusts another by
   default. Access is opened explicitly, only where a real business or
   operational need exists. This follows the segmentation principles
   described in NIST SP 800-207 (Zero Trust Architecture).
3. **DMZ as a containment zone, not a stepping stone** — the DMZ can
   receive inbound connections on specific ports, but can never
   initiate a connection into any internal VLAN. A compromised DMZ host
   should be a dead end for an attacker, not a pivot point.
4. **Security tooling lives in its own isolated zone** — Suricata,
   Wazuh, and the automated response script run in a dedicated VLAN
   (50), reachable only from Management. If a "normal" VLAN is
   compromised, the monitoring stack watching it should not be
   reachable from that same VLAN.
5. **Detection and enforcement are separate concerns** — Suricata only
   detects (IDS mode, passive, via traffic mirror). It does not block
   traffic inline. Blocking is a deliberate, logged, auditable action
   taken by a separate automated response layer. This avoids a single
   inspection point becoming a single point of failure for the whole
   network's availability.
6. **Every design decision anticipates v4.0** — segmentation and
   monitoring placement are chosen so that later attack simulations
   (VLAN hopping, lateral movement, DMZ pivot attempts) have something
   real to test against, not a network that was never designed to be
   attacked in the first place.

---

## 2. Full IP / VLAN Addressing Scheme

| Zone | VLAN ID | Subnet | DHCP | Notes |
|---|---|---|---|---|
| Management | — (out-of-band) | `192.168.100.0/24` | ❌ (static) | Unchanged from v1.0, never joins the trunk |
| IT | 10 | `192.168.10.0/24` | ✅ | Unchanged subnet from v1.0, migrated onto trunk |
| Guest | 20 | `192.168.20.0/24` | ✅ | Unchanged from v1.0, still Hotspot-gated |
| Finance | 40 | `192.168.40.0/24` | ✅ | New department, demonstrates trunk scalability |
| Security / SOC | 50 | `192.168.50.0/24` | ❌ (static) | Suricata, Wazuh manager, automation script host |
| DMZ | 30 | `192.168.30.0/24` | ❌ (static) | Public-facing service(s) |
| VPN Remote Access | — | `192.168.60.0/24` | ✅ (WireGuard-assigned) | Individual remote workers |
| Branch Office (site-to-site) | — | `172.16.0.0/24` | ✅ | Separate CHR instance, own LAN |

IT and Guest subnets are intentionally kept identical to v1.0 — the
migration changes *how* traffic reaches them (trunk instead of a
dedicated physical port), not the addressing itself.

---

## 3. v2.0 — Network Segmentation Architecture

### 3.1 Trunk and switch

A second MikroTik CHR instance is deployed as a dedicated **Layer 2
access switch** with VLAN filtering enabled (`bridge` +
`vlan-filtering=yes`). One port on the HQ router carries all VLANs
tagged (802.1Q trunk) to this switch. The switch exposes untagged
access ports, one per VLAN, toward the client VMs — client operating
systems require no VLAN awareness at all, exactly as in a real access
switch deployment.

Inter-VLAN routing happens exclusively on the HQ router via VLAN
sub-interfaces (`vlan10`, `vlan20`, `vlan40`, `vlan50`, `vlan30`) on
top of the single trunk port. The switch only forwards within a single
VLAN (Layer 2); anything crossing VLANs must pass through the router,
where firewall policy applies.

### 3.2 DMZ

- Inbound: only the specific service port(s) the DMZ host actually
  serves (e.g. 80/443 for a web server) are reachable from the
  Internet — everything else is dropped at the WAN edge.
- Outbound: the DMZ VLAN has **no firewall rule permitting it to
  initiate connections to any internal VLAN** (IT, Guest, Finance,
  Security). It may only respond to connections it did not initiate,
  and reach the Internet for its own operational needs (e.g. package
  updates).
- Administrative access to the DMZ host is one-directional: IT → DMZ
  (e.g. SSH for maintenance) is permitted; DMZ → IT is not.

### 3.3 VPN — Remote Access

- WireGuard interface on the HQ router, remote workers connect from
  outside and land in `192.168.60.0/24`.
- Firewall policy is least-privilege: by default, VPN clients can only
  reach the IT VLAN (the assumption being that remote workers are IT
  staff needing internal tooling access). Access to Guest, Finance,
  DMZ, or Security is not granted by default and must be justified
  per-user if ever needed.

### 3.4 VPN — Site-to-Site

- A second, independent MikroTik CHR instance represents a **Branch
  Office**, with its own LAN (`172.16.0.0/24`).
- Connected back to HQ via a WireGuard site-to-site tunnel, tunnel
  subnet `192.168.70.0/30`.
- Branch LAN access into HQ is scoped to the IT VLAN only, matching the
  same least-privilege principle applied to VPN Remote Access — not
  blanket access to the whole HQ network.

**Implementation note — resolved during v2.4:** VirtualBox's default NAT
adapter mode isolates each VM's network stack, which prevented a direct
WireGuard handshake between HQ and Branch when both routers relied on
their default NAT-mode WAN adapters (the handshake packet could leave
Branch but HQ's reply had no NAT translation state to route back — a
classic NAT hairpin/asymmetric traversal failure, not a WireGuard
configuration error).

This was resolved by introducing a **dedicated point-to-point segment**
(`ISP-Backbone`, `203.0.113.0/30`) — an additional Internal Network
adapter on both routers, separate from their original NAT/internet
adapters — simulating a real point-to-point WAN link between HQ and
Branch and bypassing NAT entirely for this connection. The original
WAN/VLAN adapters on both routers were left untouched, preserving the
already-validated v2.1–v2.3 architecture.

Branch LAN's own internet access (temporarily lost when its original
NAT adapter was reused for troubleshooting) was restored via a
**separate, dedicated NAT adapter**, kept fully independent from the
`ISP-Backbone` link — Branch is dual-homed: one path for general
internet egress, one path (the WireGuard tunnel over `ISP-Backbone`)
for reaching HQ's internal VLANs. RouterOS's longest-prefix-match
routing means both paths coexist without conflict.

Full build-out and diagnostic record:
[`v2.0-segmentation/docs/phase2.3-2.4-problems-found.md`](../../v2.0-segmentation/docs/phase2.3-2.4-problems-found.md) and
[`v2.0-segmentation/docs/phase2.3-2.4-troubleshooting.md`](../../v2.0-segmentation/docs/phase2.3-2.4-troubleshooting.md)

### 3.5 Firewall policy matrix (zone-to-zone)

| From \ To | IT | Guest | Finance | DMZ | Security | Internet |
|---|---|---|---|---|---|---|
| **IT** | – | ❌ | ❌ | ✅ (admin ports only) | ❌ (data-plane) | ✅ |
| **Guest** | ❌ | – | ❌ | ❌ | ❌ | ✅ (post-Hotspot login) |
| **Finance** | ❌ | ❌ | – | ❌ | ❌ | ✅ (scoped) |
| **DMZ** | ❌ | ❌ | ❌ | – | ❌ | ✅ (response only, no initiation) |
| **Security (SOC)** | ❌ (data-plane) | ❌ | ❌ | ❌ | – | ✅ (updates, threat intel feeds) |
| **VPN Remote** | ✅ (scoped) | ❌ | ❌ | ❌ | ❌ | — |
| **Branch (site-to-site)** | ✅ (scoped, TBD resource) | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Management** | ✅ (admin) | ✅ (admin) | ✅ (admin) | ✅ (admin) | ✅ (admin) | ✅ |

Note the one deliberate exception on the control plane: the automation
script running in the Security VLAN needs to call the MikroTik API to
add entries to the firewall address-list. This is a **management-plane**
exception (Security → Router API, a specific port/service), not a
data-plane exception — Security still has no visibility into or access
to actual user traffic on IT/Guest/Finance.

---

## 4. v3.0 — Monitoring & Automated Response Architecture

### 4.1 Suricata placement (decision: Option B — boundary-focused)

Rather than mirroring every VLAN's internal traffic to a single
Suricata instance, Suricata is deployed to monitor the two highest-value
vantage points:

1. **The trunk link** — all inter-VLAN traffic, since anything crossing
   zone boundaries is inherently higher-risk than same-VLAN chatter.
2. **DMZ ingress/egress** — the only zone directly exposed to the
   Internet, and therefore the most realistic target for external
   attack traffic.

This mirrors a common real-world prioritization: IDS coverage is
usually concentrated at boundaries and high-value segments rather than
spread evenly across every internal network, reflecting both resource
constraints and risk concentration in real deployments.

Suricata runs in **IDS mode (passive)** — it inspects a mirrored copy
of traffic and never sits inline. This is a deliberate choice: keeping
detection out of the traffic's live path means a Suricata outage
cannot take down connectivity, and it keeps enforcement as a distinct,
auditable step handled by the automated response layer rather than
Suricata itself.

### 4.2 Centralized logging & SIEM

- MikroTik syslog and Suricata `eve.json` both feed into a **Wazuh**
  deployment (manager + agent), which lives in the Security VLAN.
- Suricata's `eve.json` is the integration point — not `fast.log` —
  since it is structured JSON designed for machine consumption, unlike
  the plain-text log the original mini-project script parsed.
- A custom decoder maps Suricata's `src_ip` field to the `srcip` field
  Wazuh's active response scripts expect, following the documented
  integration pattern between Suricata and Wazuh.

### 4.3 Automated response

This is the most technically important piece, and the one place where
the design deliberately corrects a misconception from initial
planning: **Wazuh's built-in `firewall-drop` Active Response only
manages host-level firewalls (iptables) on the endpoint it runs on —
it does not natively speak to network devices like a MikroTik router.**

The architecture therefore uses Wazuh as the **orchestration layer**,
triggering a **custom Active Response script** (a refactored version of
the original mini-project Python script) as the actual enforcement
action:

```
Suricata (eve.json)
    → Wazuh Agent (reads log, forwards to Manager)
    → Wazuh Manager (custom decoder + custom rule, severity-filtered)
    → Active Response triggered (stateful, timeout-bound)
    → Custom script (Python) — the refactored mini-project script
    → MikroTik API (adds source IP to Blacklist address-list, with
      an expiry timeout, not a permanent block)
    → Firewall Filter (pre-existing rule drops all traffic from
      addresses in Blacklist)
```

Requirements carried over from the code review of the original script:

- Suricata `eve.json` parsing, not `fast.log` string-matching
- Credentials via environment variables, not hardcoded in source
- MikroTik API access over API-SSL (port 8729), using a dedicated
  least-privilege API user — not the full `admin` account
- Severity/SID filtering before triggering a block, not a blanket
  keyword match
- Time-bound blocks (`timeout=`) rather than permanent ones, so a
  false positive self-corrects
- An explicit, externally-maintained allowlist (config file, not
  inline in code) covering all gateway IPs across every VLAN
  introduced in v2.0
- Structured logging of every block action for audit purposes —
  visible in Wazuh, not just a local `print()` statement

### 4.4 Why the custom script still matters

Wazuh alone cannot fulfill the automated response requirement against
a MikroTik target — this was confirmed directly against Wazuh's
documented Active Response behavior. The custom script is not a
redundant, "just for show" component sitting next to a complete
off-the-shelf solution; it is the piece that makes network-level
enforcement possible at all in this stack. This is a meaningful
distinction to be explicit about in the eventual v3.0 documentation and
during interviews — it demonstrates the ability to extend a
industry-standard tool where its out-of-the-box capability stops,
rather than only knowing how to configure existing features.

---

## 5. Implementation Sequencing

**v2.0 — Status: ✅ Complete**
1. v2.1 — VLAN segmentation (trunk, switch, IT/Guest/DMZ/Security VLANs) — ✅ Complete
2. v2.2 — DMZ containment (firewall isolation, port forwarding, reverse proxy) — ✅ Complete
3. v2.3 — VPN Remote Access (WireGuard) — ✅ Complete
4. v2.4 — VPN Site-to-Site (Branch Office, dedicated WAN-link segment) — ✅ Complete

**v3.0**
1. v3.1 — Centralized syslog (MikroTik → log server in Security VLAN)
2. v3.2 — Wazuh manager + agent deployment
3. v3.3 — Suricata deployment (trunk + DMZ mirror), eve.json → Wazuh
4. v3.4 — Baseline traffic profiling (establish "normal" before v4.0)
5. v3.5 — Custom Active Response script (refactored automation),
   integrated with Wazuh's Active Response framework

---

## 6. Traceability to v4.0

Every zone boundary and control introduced here is a deliberate future
test target for the purple team attack simulations in v4.0:

- VLAN hopping attempts against the trunk (T1599)
- Lateral movement attempts across VLAN boundaries (T1021)
- DMZ containment validation — simulate a compromised DMZ host and
  confirm it truly cannot pivot inward
- Automated response validation — confirm the full detection-to-block
  pipeline actually closes the loop end-to-end, with a measured MTTD,
  per the methodology in
  [`docs/methodology/purple-team-workflow.md`](../methodology/purple-team-workflow.md)
