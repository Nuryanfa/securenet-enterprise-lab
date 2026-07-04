# Phase 2 — Issues & Problems Found (Network Segmentation & VLAN)

## Overview

During **Phase 2: Network Segmentation & Enterprise Services**, the network architecture was migrated from a flat topology to a VLAN-based architecture (802.1Q) using MikroTik CHR (Router + Switch) on Oracle VirtualBox. The goal was to isolate four network segments — **IT**, **Guest**, **DMZ**, and **Security** — into separate VLANs, connected via a trunk link between the router and switch.

| VLAN | Segment | Subnet | Gateway |
|------|---------|--------|---------|
| 10 | IT | 192.168.10.0/24 | 192.168.10.1 |
| 20 | Guest | 192.168.20.0/24 | 192.168.20.1 |
| 30 | DMZ | 192.168.30.0/24 | 192.168.30.1 |
| 50 | Security | 192.168.50.0/24 | 192.168.50.1 |

Several issues were encountered throughout the implementation process, requiring step-by-step troubleshooting. This document lists the problems as they were found, without describing their eventual resolution.

---

## 1. Build-Out & Configuration Issues

### 1.1 Switch VM inherited Layer-3 configuration from cloning

The virtual switch was created by cloning an already-configured router VM. This caused Layer-3 configuration — IP addressing, NAT, firewall, DHCP server, Hotspot, and other settings — to be carried over into what was supposed to be a pure Layer-2 device. As a result, the switch no longer functioned as a clean Layer-2 device: interfaces unexpectedly became "slaves," and several firewall rules became invalid.

### 1.2 VirtualBox adapter limitation

VirtualBox's graphical interface only exposes four network adapters, while the lab design required five interfaces on the switch (Trunk, IT, Guest, DMZ, Security). Adding a fifth adapter via `VBoxManage` caused the virtual machine to fail to boot, because the cloning process had left the switch and router sharing the same virtual disk.

### 1.3 VLAN interface mistakenly created on the switch

While applying VLAN configuration, a VLAN interface was accidentally created on the switch, when according to the intended architecture, Layer-3 VLAN interfaces should exist only on the router.

### 1.4 Incorrect PVID values on access ports

During Bridge VLAN Filtering configuration (RouterOS v7), incorrect PVID (Port VLAN ID) values were found on several access ports, causing client packets to be placed into the wrong VLAN.

### 1.5 VLAN 50 (Security) missing a gateway IP address

While reviewing the router's Layer-3 configuration, it was found that although the `vlan50_Security` interface existed and was running, it had not been assigned an IP address — unlike VLAN 10, 20, and 30, which each had a properly configured gateway address.

---

## 2. End-to-End Connectivity Failure

After VLAN, bridge, and trunk configuration were completed, connectivity testing revealed a critical problem:

> Client devices successfully obtained IP addresses via DHCP, but could not communicate with their own VLAN gateway, could not reach other VLANs, and had no Internet access at all — pings to `8.8.8.8` and `google.com` also failed.

Specific symptoms observed:

- **ARP table inspection** on the router showed that client MAC addresses did not appear on the corresponding VLAN interface, while the switch's bridge host table had already learned MAC addresses from connected devices.
- Ping from the **IT** VLAN client to its own gateway (192.168.10.1) failed.
- Ping from the **Guest** VLAN client to its own gateway (192.168.20.1) failed.
- Ping between clients on **different VLANs** (e.g., Windows on Guest, Kali on IT) failed.
- Ping between clients that were **expected to communicate** (i.e., not covered by any intentional blocking rule) also failed.
- Internet access testing (`ping 8.8.8.8`, `ping google.com`) failed entirely from all VLANs.
- This behavior persisted even after:
  - Disabling `fast-forward` on the switch bridge.
  - Disabling the router's firewall filter rules.
  - Disabling NAT rules.
  - Disabling the Hotspot service.
- Attempting to disable all firewall rules via `disable [find]` failed with a `can't edit dynamic object` error, since MikroTik-generated dynamic Hotspot rules cannot be disabled using a blanket selector.

This indicated that, despite VLAN tagging, bridge configuration, PVID assignment, routing tables, firewall rules, and NAT all appearing correctly configured, the underlying frame forwarding between client devices and the router/switch was still failing at a more fundamental level.

---

## 3. Hotspot-Related Anomaly

A separate anomaly was found on the **Guest VLAN**, related to MikroTik Hotspot behavior:

- When opening a browser on the Guest client and navigating to a site such as `google.com`, the browser was expected to be redirected to the MikroTik Hotspot login page before Internet access was granted.
- Instead, the browser connected directly to Google without ever showing the Hotspot login page, even though the walled-garden configuration did not appear to contain any bypass rules.
- At the same time, ICMP (ping) traffic from the same Guest client to its own gateway and to the Internet was actively **rejected** — the client received explicit `Destination net unreachable` responses rather than silent timeouts, indicating the router was returning an ICMP rejection (`icmp-net-prohibited`) rather than dropping the packets.
- This created a confusing and seemingly contradictory symptom: HTTP/HTTPS traffic appeared to work without authentication, while ICMP traffic to the exact same destinations was being explicitly blocked.

---

## Summary of Problems Identified

| # | Problem | Layer |
|---|---------|-------|
| 1 | Switch VM inherited router's Layer-3 config after cloning | Build-out |
| 2 | VirtualBox adapter limit (4 vs. 5 required) causing VM boot failure | Build-out |
| 3 | VLAN interface mistakenly created on switch instead of router | Build-out |
| 4 | Incorrect PVID values on access ports | Build-out |
| 5 | VLAN 50 (Security) missing gateway IP address | Build-out |
| 6 | Clients receive DHCP IP but cannot ping their own gateway | Connectivity |
| 7 | No inter-VLAN or Internet connectivity for any client | Connectivity |
| 8 | Client MAC addresses not appearing correctly in router ARP table despite being learned by switch bridge table | Connectivity |
| 9 | Problem persisted even with fast-forward, firewall, NAT, and Hotspot all disabled | Connectivity |
| 10 | Dynamic Hotspot firewall rules cannot be disabled via `disable [find]` | Operational |
| 11 | Guest client bypasses Hotspot login page for HTTP/HTTPS but is rejected for ICMP | Hotspot |

These problems are addressed in the companion document, **"Phase 2 — Troubleshooting & Resolution."**
