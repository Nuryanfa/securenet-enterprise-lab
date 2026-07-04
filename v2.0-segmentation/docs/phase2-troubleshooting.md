# Phase 2 — Troubleshooting & Resolution (Network Segmentation & VLAN)

## Overview

This document describes the troubleshooting process and resolution for the issues identified in the companion document, **"Phase 2 — Issues & Problems Found."** It covers the diagnostic steps taken, the root causes identified, and the fixes applied to achieve full end-to-end connectivity for the VLAN-segmented network (IT, Guest, DMZ, Security) built on MikroTik CHR (Router + Switch) under Oracle VirtualBox.

---

## 1. Build-Out Issue Resolutions

### 1.1 Switch VM inherited Layer-3 configuration

**Fix:** The switch configuration was reset to a clean RouterOS baseline, removing all inherited Layer-3 elements (IP addressing, NAT, firewall, DHCP, Hotspot). The switch was then rebuilt from scratch strictly as a Layer-2 device.

### 1.2 VirtualBox adapter limitation

**Fix:** A fifth network adapter was added via `VBoxManage`. The resulting boot failure — caused by the switch and router sharing a virtual disk from a linked clone — was resolved by rebuilding the VM as a **Full Clone**, giving each device its own independent virtual disk.

### 1.3 VLAN interface mistakenly created on the switch

**Fix:** The VLAN interface was removed from the switch and recreated correctly on the router, in line with the design principle that Layer-3 VLAN interfaces belong only on the router.

### 1.4 Incorrect PVID values

**Fix:** PVID values were corrected per access port to match the intended design:
- IT → VLAN 10
- Guest → VLAN 20
- DMZ → VLAN 30
- Security → VLAN 50

### 1.5 VLAN 50 (Security) missing gateway IP

**Fix:** Added the missing IP address to the VLAN 50 interface:
```
/ip address add address=192.168.50.1/24 interface=vlan50_Security
```

---

## 2. End-to-End Connectivity Failure — Diagnostic Process

The connectivity failure (DHCP working, but no ping/Internet on any VLAN) required a systematic, layer-by-layer elimination process.

### Step 1 — Verify Layer 2 VLAN/bridge configuration

Checked and confirmed correct on the switch:
```
/interface/bridge/vlan print detail
/interface/bridge/port print
/interface/bridge print
```
Result: trunk tagging, PVID assignment, `vlan-filtering=yes`, and `ingress-filtering=yes` were all correctly configured. **Not the root cause.**

### Step 2 — Verify Layer 3 VLAN interfaces on the router

Checked:
```
/interface/vlan print detail
/ip address print
```
Result: all VLAN interfaces correctly parented to `ether3`, `arp=enabled` on all. Missing IP on VLAN 50 was found and fixed here (see 1.5). **Not the (sole) root cause.**

### Step 3 — Rule out `fast-forward` bridge acceleration

Hypothesis: `fast-forward=yes` combined with VLAN filtering and Hotspot can cause inconsistent forwarding.

**Action:**
```
/interface/bridge set BR-CORE fast-forward=no
```
**Result:** No change — connectivity still failed. Ruled out.

### Step 4 — Rule out firewall filter rules

**Action:** Attempted to disable all firewall filter rules for isolation testing:
```
/ip firewall filter disable [find]
```
This failed with `can't edit dynamic object`, since MikroTik-generated dynamic Hotspot rules cannot be disabled this way. Static rules were disabled individually by index instead:
```
/ip firewall filter disable 0
/ip firewall filter disable 1
/ip firewall filter disable 2
/ip firewall filter disable 15
/ip firewall filter disable 16
```
**Result:** Still RTO on gateway ping. Firewall filter rules ruled out.

### Step 5 — Rule out NAT and Hotspot service

**Action:**
```
/ip firewall nat disable [find]
/ip hotspot disable [find]
```
**Result:** Still RTO on gateway ping, even to the client's own default gateway. This eliminated Layer 3/4 (routing, firewall, NAT, Hotspot) as the cause and pointed the investigation toward Layer 2 or the virtualization layer itself.

### Step 6 — Investigate the hypervisor layer

With all router-side services eliminated as suspects, attention turned to VirtualBox's network adapter configuration — specifically the **Promiscuous Mode** setting on Internal Network adapters.

**Root cause found:** VirtualBox's Internal Network adapters default their Promiscuous Mode to **"Deny."** In a VLAN trunk topology, both the router and switch must forward Ethernet frames whose destination MAC address does not belong to their own virtual NIC — this is fundamental to bridging and 802.1Q trunking. With Promiscuous Mode set to "Deny," the hypervisor silently dropped these frames at the virtual NIC level, before RouterOS ever processed them. This explains why every software-level configuration (VLAN tagging, bridge, trunk, routing, firewall, NAT) could be verified as correct, yet connectivity still failed completely — even for gateway-local ping.

**Fix applied:** Set **Promiscuous Mode = "Allow All"** on every Internal Network adapter involved in the trunk/access topology:
- Router (HQ) — all adapters
- SecureNet-Switch — all adapters
- Windows and Kali client VMs — their respective access adapters

**Result:** Immediately after this change, ping to gateways succeeded, and Internet access (`8.8.8.8`, `google.com`) worked correctly from the IT VLAN.

---

## 3. Hotspot Authentication Anomaly — Diagnostic Process

After fixing the Promiscuous Mode issue, IT VLAN connectivity worked immediately. The Guest VLAN, however, showed a confusing symptom: HTTP/HTTPS browsing worked and reached Google directly without ever showing the MikroTik Hotspot login page, while ICMP ping to the same destinations was actively rejected (`Destination net unreachable`).

### Step 1 — Check for Hotspot bypass

```
/ip hotspot walled-garden print
/ip hotspot walled-garden ip print
```
**Result:** No entries found — ruled out an open walled-garden bypass.

### Step 2 — Check Hotspot active session state

```
/ip hotspot active print
```
**Result:** The Guest client (`guest`, IP 192.168.20.252) was already listed as **authenticated**, with an active session from earlier testing. This explained why the login page did not reappear — the client's session was still valid.

### Step 3 — Trace the firewall logic for authenticated vs. unauthenticated clients

```
/ip firewall filter print detail where chain=hs-input
/ip firewall filter print detail where chain=hs-auth
```
**Finding:** The reject rules under `hs-unauth` are only reached via a jump condition matching `hotspot=!auth` (i.e., only for **unauthenticated** clients). Since the Guest client was already authenticated, this reject path did not apply to it. The `hs-auth` chain itself was empty (default), meaning authenticated traffic simply passes through without additional restriction.

**Conclusion:** No configuration change was required for this issue. The apparent contradiction (HTTP working, ICMP rejected) was a result of testing performed while the router's rules were being repeatedly enabled/disabled during the Layer 2 diagnostic process (Section 2), which produced inconsistent intermediate states. Once Promiscuous Mode was corrected and all firewall/NAT/Hotspot services were restored to their proper enabled state, ping succeeded normally for the already-authenticated Guest client.

---

## 4. Final Restoration Steps

After diagnosis was complete, all temporarily disabled components were restored to their intended production state:

```
/ip hotspot enable [find]
/ip firewall filter enable 0
/ip firewall filter enable 1
/ip firewall filter enable 2
/ip firewall filter enable 15
/ip firewall filter enable 16
/interface/bridge set BR-CORE fast-forward=yes
/interface/bridge set BR-CORE protocol-mode=rstp
```

Promiscuous Mode was left set to **"Allow All"** on all Internal Network adapters, as this is required permanently for the trunk topology to function — it is not a temporary diagnostic setting.

---

## 5. Final Verification Results

| Test | Expected | Result |
|---|---|---|
| IT → ping own gateway (192.168.10.1) | Reply | ✅ Pass |
| Guest → ping own gateway (192.168.20.1), post Hotspot login | Reply | ✅ Pass |
| Guest → Internet (8.8.8.8, google.com), post Hotspot login | Reply | ✅ Pass |
| **Guest → IT (192.168.10.0/24)** | **Blocked (by design)** | ✅ RTO — segmentation enforced correctly |
| IT / DMZ / Security → general connectivity | Reply | ✅ Pass |

All Phase 2 objectives were achieved:

- [x] Switch rebuilt as a pure Layer-2 device
- [x] 802.1Q trunk implemented between router and switch
- [x] VLAN 10 (IT), 20 (Guest), 30 (DMZ), 50 (Security) configured
- [x] Bridge VLAN Filtering (RouterOS v7) configured correctly
- [x] PVID configured per access port
- [x] Layer-3 services (IP addressing, DHCP, Hotspot) migrated to router VLAN interfaces
- [x] Guest VLAN isolated from IT VLAN via firewall segmentation
- [x] Hotspot authentication enforced on Guest VLAN
- [x] End-to-end connectivity validated across all VLANs and to the Internet

---

## Key Lessons Learned

1. **Correct Layer 2/3 configuration does not guarantee connectivity in a virtualized lab.** Hypervisor-level settings — specifically VirtualBox's Promiscuous Mode on Internal Network adapters — are just as critical as RouterOS configuration for trunk-based VLAN topologies, and are easy to overlook since they sit outside RouterOS entirely.
2. **Distinguish "timed out" from "destination unreachable."** ICMP responses carrying an explicit rejection code (e.g., `icmp-net-prohibited`) indicate an active firewall/Hotspot policy decision, whereas silent timeouts point toward a forwarding/Layer 2 problem — these require different troubleshooting paths.
3. **Systematic, layer-by-layer isolation is essential.** Working outward from Layer 2 (bridge/VLAN/trunk) to Layer 3 (routing) to Layer 4+ (firewall/NAT/Hotspot) — and being willing to temporarily disable each layer for isolation testing — was what ultimately narrowed the fault to the hypervisor layer rather than RouterOS configuration.
4. **Dynamic (Hotspot-generated) firewall rules cannot be disabled the same way as static rules.** `disable [find]` will fail against dynamic objects; static and dynamic rules must be managed separately during testing.
