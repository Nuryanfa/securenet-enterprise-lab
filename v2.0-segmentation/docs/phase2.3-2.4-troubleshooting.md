# Phase 2.3 / 2.4 — Troubleshooting & Resolution (VPN Remote Access & Site-to-Site)

## Overview

This document describes how the issues identified in the companion document, **"Phase 2.3 / 2.4 — Issues & Problems Found,"** were diagnosed and resolved. Contrary to the initial assessment that the Site-to-Site handshake failure was an unresolvable limitation of the VirtualBox lab environment, a working solution was found that avoids the NAT hairpin problem entirely, without requiring physical hardware or modifications to the Windows host.

---

## 1. v2.3 — VPN Remote Access (Resolution)

No issues required resolution. Configuration steps:

1. Created `wireguard-remote` interface on Router-HQ (`listen-port=13231`).
2. Assigned tunnel subnet `192.168.60.1/24`.
3. Registered client peer(s) with appropriate `allowed-address`.
4. Opened UDP port `13231` on the input firewall chain.
5. Added forward rule restricting remote-access traffic to the IT VLAN only (`192.168.60.0/24 → 192.168.10.0/24`), and an explicit block rule denying remote access to Guest/DMZ/Security.
6. Verified successful connection and ping from an external client through the tunnel.

---

## 2. v2.4 — Build-Out Issue Resolutions

### 2.1 Router-Branch cloned config conflict

**Fix:** Performed a full configuration reset with `no-defaults=yes` on Router-Branch, clearing all inherited MAC addresses, VLAN metadata, and interface naming carried over from the HQ clone. This restored the router to a clean baseline with standard interface names (`ether1`, `ether2`), later renamed to `ether1-WAN` and `ether2-LAN`.

### 2.2 Router-Branch unreachable via Winbox

**Fix (used twice, same procedure both times):**
1. Shut down Router-Branch.
2. Added a temporary **Host-only Adapter** in VirtualBox (`VirtualBox Host-only Ethernet Adapter`) on an unused adapter slot.
3. Booted the VM, connected via Winbox using the **Neighbors** tab (MAC-based discovery, since the new interface had no IP yet).
4. Assigned a management IP on the Host-only subnet (`192.168.56.20/24`) to the newly added interface.
5. Reconnected via Winbox using this IP directly for all subsequent configuration.

This Host-only adapter was kept in place as a permanent out-of-band management path, separate from the WAN-link and LAN interfaces.

### 2.3 Address/interface mapping confusion

**Fix:** Verified the actual VirtualBox adapter-to-interface mapping using `/interface print` (matching by MAC address) and `/ip address print` (identifying which interface had no address assigned), rather than assuming slot order. The misassigned address was removed from the wrong interface and re-added to the correct one:
```
/ip address remove 0
/ip address add address=192.168.56.20/24 interface=ether3
/ip address add address=203.0.113.2/30 interface=ether1-WAN
```

---

## 3. v2.4 — Site-to-Site Handshake Failure: Resolution

### 3.1 Revised approach: dedicated simulated WAN segment instead of NAT hairpin

Rather than relying on VirtualBox's shared virtual gateway (`10.0.2.2`) for inter-VM communication — which the initial analysis correctly identified as fundamentally unsuited for this purpose — a **dedicated Internal Network segment** was introduced to directly connect Router-HQ and Router-Branch at Layer 3, bypassing NAT entirely for this link.

This required revisiting the earlier decision to avoid changing adapter types: the previous concern was that changing adapter type would disrupt the already-validated WAN/VLAN architecture. The resolution addressed this by adding a **new, additional adapter** dedicated solely to the HQ↔Branch link, rather than repurposing the adapter that had been previously used for genuine internet access — preserving the integrity of the original Phase 1 design while solving the traversal problem.

### 3.2 VirtualBox adapter configuration

**Router-HQ** (adapter slots: 1=NAT, 2=Management, 3=Trunk):
- Added **Adapter 4** → Internal Network, name: `ISP-Backbone`

**Router-Branch** (adapter slots: originally 1=NAT/WAN, 2=Internal LAN):
- Changed **Adapter 1** → Internal Network, name: `ISP-Backbone` (identical name required on both VMs)
- Adapter 2 (Branch LAN) unchanged
- Added **Adapter 3** → Host-only, for out-of-band management (see 2.2)

> Note: this removed Router-Branch's original direct-internet NAT path. Internet access for Branch LAN clients was intentionally deferred at this stage and restored later via a separate dedicated adapter — see Section 7.

### 3.3 RouterOS configuration on the new WAN-link segment

**Router-HQ:**
```
/interface ethernet set [find default-name=ether4] name=ether-WAN-Link
/ip address add address=203.0.113.1/30 interface=ether-WAN-Link
```

**Router-Branch:**
```
/ip address add address=203.0.113.2/30 interface=ether1-WAN
```

### 3.4 Updated WireGuard peer endpoint

The existing WireGuard interfaces and peers (created during initial setup) were **reused without recreation** — only the peer endpoint address was updated to point to the new WAN-link IP instead of the unreachable virtual gateway:

**On Router-Branch:**
```
/interface wireguard peers set [find interface=wg-to-hq] endpoint-address=203.0.113.1 endpoint-port=13232
```

### 3.5 Firewall verification

Checked `/ip firewall filter print` on HQ and confirmed the existing input rule allowing UDP `13232` (`chain=input action=accept protocol=udp dst-port=13232`) was not scoped to a specific interface, so it applied automatically to the new `ether-WAN-Link` interface without requiring any additional rule.

### 3.6 Removed obsolete VirtualBox port forwarding

The UDP port-forwarding rule (`13232 → 13232`) previously configured on Router-HQ's NAT adapter was removed, as it was no longer part of the traffic path.

### 3.7 Verification — WAN link and handshake

**Step 1 — Basic WAN-link reachability:**
```
/ping 203.0.113.1 count=5
```
Result: `0% packet-loss`, confirming the new Internal Network segment provided direct Layer 3 reachability between the two routers, bypassing NAT entirely.

**Step 2 — WireGuard handshake status:**
```
/interface wireguard peers print detail
```
Result: `last-handshake` populated (previously always empty/never), and `rx` began incrementing for the first time (previously `rx=0` while `tx` climbed indefinitely) — confirming a successful bidirectional handshake.

### 3.8 Second issue found during verification: missing static routes

After the tunnel was confirmed to be handshaking correctly, ping to the **remote LAN subnet** still failed — but with a different symptom than before:
```
/ping 192.168.10.1
  no route to host
```
This is a distinct failure mode from the earlier `timeout` — indicating the *tunnel itself was working*, but neither router had a route directing traffic for the other side's internal subnets through the tunnel interface. This is expected WireGuard behavior: an entry in a peer's `allowed-address` list governs cryptokey routing (which packets are permitted through the tunnel), but does **not** automatically populate the router's own routing table.

**Fix — added static routes on both sides:**

On Router-Branch:
```
/ip route add dst-address=192.168.0.0/16 gateway=wg-to-hq
```

On Router-HQ:
```
/ip route add dst-address=172.16.0.0/24 gateway=wg-to-branch
```

### 3.9 Final verification — full bidirectional connectivity

| Test | Direction | Result |
|---|---|---|
| Ping WAN-link IP (`203.0.113.1`) | Branch → HQ | ✅ 0% loss |
| Ping tunnel IP (`192.168.70.1`) | Branch → HQ | ✅ 0% loss |
| Ping local Branch LAN gateway (`172.16.0.1`) | Branch → Branch | ✅ 0% loss |
| Ping HQ VLAN IT gateway (`192.168.10.1`) | Branch → HQ | ✅ 0% loss (after route fix) |
| Ping Branch LAN gateway (`172.16.0.1`) | HQ → Branch | ✅ 0% loss (after route fix) |
| WireGuard handshake, both peers | Bidirectional | ✅ `rx`/`tx` both active, recent `last-handshake` |

---

## 4. Root Cause Summary

Two distinct, independent issues had to be resolved — addressing only one would not have been sufficient:

1. **NAT hairpin / isolation limitation (VirtualBox):** Default NAT-mode adapters on separate VMs cannot reliably relay UDP handshake traffic between each other via the shared virtual gateway, because each VM's NAT engine maintains an isolated translation table. **Resolved by** introducing a dedicated Internal Network segment (`ISP-Backbone`) as a direct Layer 3 link between the two routers, simulating a real point-to-point WAN connection instead of relying on NAT traversal.

2. **Missing static routes for remote subnets:** WireGuard's `allowed-address` peer setting controls cryptographic packet acceptance but does not create routing table entries. **Resolved by** manually adding static routes on both routers pointing to each other's internal subnet(s) via their respective WireGuard interface as gateway.

---

## 5. Restoring Branch Internet Access (Dedicated NAT Adapter) — Resolved

Since Router-Branch's Adapter 1 was repurposed for the `ISP-Backbone` WAN-link (Section 3.2), Branch LAN clients lost their original path to the public internet. This was resolved by adding a **separate, dedicated adapter** purely for internet egress, keeping it fully independent from the WAN-link segment (Option B from the earlier assessment), rather than treating Branch as intentionally air-gapped.

### 5.1 VirtualBox adapter addition

**Router-Branch** (adapter slots: 1=ISP-Backbone, 2=Branch LAN, 3=Host-only management):
- Added **Adapter 4** → **NAT**

### 5.2 RouterOS configuration

```
/interface ethernet set [find default-name=ether4] name=ether4-Internet
/ip dhcp-client add interface=ether4-Internet disabled=no
/ip firewall nat add chain=srcnat out-interface=ether4-Internet action=masquerade
```

The VirtualBox NAT DHCP client automatically installed its own dynamic default route (`0.0.0.0/0` via the NAT gateway) once enabled — a manually added duplicate default route (also `distance=1`, pointing to the same interface) was found redundant and removed:
```
/ip route remove 0
```
(index corresponding to the manually added duplicate `0.0.0.0/0` route — verify with `/ip route print` before removing, since index numbers shift depending on current table state)

### 5.3 Why this coexists cleanly with the Site-to-Site route

No route conflict occurs between the new default route (`0.0.0.0/0 → ether4-Internet`) and the existing Site-to-Site route (`192.168.0.0/16 → wg-to-hq`), because RouterOS selects the most specific matching prefix. Traffic destined for HQ subnets (`192.168.0.0/16`) is matched by the more specific `/16` route and continues through the tunnel; all other traffic (e.g., `8.8.8.8`, `google.com`) falls through to the `/0` default route via the new internet adapter.

### 5.4 Verification

| Test | From | Result |
|---|---|---|
| `/ping 8.8.8.8` | Router-Branch | ✅ 0% loss (~19ms) |
| `ping 8.8.8.8` | Branch LAN client | ✅ 0% loss |
| `ping google.com` (DNS resolution) | Branch LAN client | ✅ 0% loss, resolved correctly |
| `/ping 192.168.10.1` (HQ subnet, via tunnel) | Router-Branch | ✅ 0% loss, unaffected (~2ms) |

Router-Branch is now dual-homed as originally intended by the roadmap: a dedicated NAT path for general internet access, and the WireGuard Site-to-Site tunnel for reaching HQ's internal VLANs — with neither path interfering with the other.

**Note on Promiscuous Mode:** VirtualBox greys out (locks) the Promiscuous Mode setting for adapters in NAT mode. This is expected, not a defect — Promiscuous Mode is a Layer 2 concept relevant only to bridging/trunking adapters (such as `ISP-Backbone`); a pure client-mode NAT adapter has no need for it, and VirtualBox correctly disables the option for this adapter type.

---

## 6. Key Lessons Learned

1. **A limitation in one specific mechanism (NAT hole-punching) does not mean the overall goal is unachievable** — it means the mechanism used to reach that goal needs to change. The original NAT-hairpin approach was correctly diagnosed as broken, but the conclusion that Site-to-Site was impossible in this environment turned out to be premature; a dedicated simulated WAN segment solved it without hardware or host-level changes.
2. **WireGuard `allowed-address` and the router's `/ip route` table are two separate mechanisms.** A successful handshake with correctly scoped `allowed-address` does not guarantee routed connectivity — static routes must still be added explicitly on both ends.
3. **`timeout` and `no route to host` are different signals and should be diagnosed differently.** `timeout` suggests packets are leaving but not returning (transport/NAT-layer issue); `no route to host` means the local router has no forwarding path at all (routing-table issue) — regardless of whether the underlying tunnel is healthy.
4. **When adding new adapters for a specific purpose (e.g., a simulated WAN link), keep them additive rather than repurposing adapters that already serve another function** — this preserves previously validated parts of the architecture and avoids reopening solved problems (e.g., losing Branch's original internet path was a side effect worth flagging rather than an intended architecture change).
5. **Split-tunnel routing (specific subnet via VPN, everything else via a separate default route) requires no special configuration beyond correct route specificity** — RouterOS (like most routers) always prefers the longest matching prefix, so a dedicated internet adapter and a Site-to-Site tunnel route can coexist safely as long as their destination prefixes don't overlap.
6. **Promiscuous Mode is scoped to adapter *purpose*, not the VM as a whole.** A VM can simultaneously have adapters that require Promiscuous Mode set to "Allow All" (bridging/trunking adapters) and adapters where it is correctly locked to "Deny" by VirtualBox (pure NAT client adapters) — this is expected behavior, not an inconsistency to fix.
