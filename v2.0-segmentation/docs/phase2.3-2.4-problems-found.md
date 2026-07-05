# Phase 2.3 / 2.4 — Issues & Problems Found (VPN Remote Access & Site-to-Site)

## Overview

This document covers the issues encountered while implementing **v2.3 (VPN Remote Access)** and **v2.4 (VPN Site-to-Site)** from the project roadmap, built on MikroTik CHR under Oracle VirtualBox. It follows the same format as the companion VLAN problems-found document from v2.1.

Architecture in scope:

- **Router-HQ:** WAN via VirtualBox default NAT (dynamic IP), internal VLAN segments (`vlan10_IT`, `vlan20_Guest`, `vlan30_DMZ`, `vlan50_Security`), WireGuard Remote Access (`wireguard-remote`, port `13231`, subnet `192.168.60.0/24`).
- **Router-Branch:** simulated branch office with its own local LAN (`172.16.0.0/24`), intended to connect back to HQ via a WireGuard Site-to-Site tunnel (port `13232`, tunnel subnet `192.168.70.0/30`).

---

## 1. v2.3 — VPN Remote Access

No significant issues were encountered during this stage. WireGuard on RouterOS v7 has native support with no additional packages required. The interface, peer configuration, IP addressing, and firewall rules for remote access were configured and validated successfully on the first attempt.

---

## 2. v2.4 — VPN Site-to-Site: Initial Build-Out Issues

### 2.1 Router-Branch VM cloned from Router-HQ disk carried over full configuration

Router-Branch was created by cloning the Router-HQ disk. This caused the cloned VM to inherit 100% of the HQ configuration, including MAC addresses and VLAN metadata. As a result, interface naming shifted unpredictably (e.g., interfaces appearing as `ether11` and `ether13` instead of clean `ether1`/`ether2`), and commands referencing interfaces failed with an `ambiguous value of interface` error.

### 2.2 Router-Branch became unreachable via Winbox after adapter changes

At two separate points in the process, Router-Branch became completely undetectable in Winbox:

- **First occurrence:** immediately after the cloned VM's configuration conflict (Section 2.1), before the reset was performed.
- **Second occurrence:** after changing Router-Branch's Adapter 1 from NAT to Internal Network (as part of the WAN-link redesign, see the companion troubleshooting document) — since Internal Network adapters are, by design, completely isolated from the Windows host, no adapter remained through which Winbox could reach the router directly.

### 2.3 Address/interface mapping confusion after adding a new adapter

After adding a Host-only adapter for emergency management access, the IP address that was intended for the Host-only interface (`192.168.56.20/24`) was instead found assigned to `ether1-WAN` (intended for the WAN-link/ISP-Backbone segment), while the newly added interface (`ether3`) had no address at all — indicating the VirtualBox adapter slot mapping and the RouterOS interface naming did not correspond the way expected.

---

## 3. v2.4 — Site-to-Site Handshake Failure

### 3.1 Problem Statement

After WireGuard Site-to-Site parameters (interfaces, key exchange, tunnel IPs, static routes) were configured identically and correctly on both routers, the tunnel failed to establish a working handshake:

- The WireGuard peer statistics on the Branch side showed **Transmit (`tx`) continuously increasing** — meaning handshake packets were actively being sent — while **Receive (`rx`) remained at `0`**, indicating no return traffic was ever received.
- Basic ICMP connectivity testing (`/ping 192.168.70.1`, the HQ tunnel IP) from Branch to HQ consistently resulted in **`packet-loss=100% (timeout)`**.
- All internal RouterOS parameters — public/private keys, tunnel IP addressing, peer `allowed-address` values, and static routing entries — were independently verified as correctly configured on both sides.

### 3.2 Initial Root Cause Hypothesis

The failure was attributed to a structural limitation of VirtualBox's default NAT networking mode, rather than a MikroTik configuration error:

**A. NAT "isolation silo" per VM.** VirtualBox's default **NAT** adapter mode creates a completely isolated network stack for each VM. Even though both Router-HQ and Router-Branch obtained similar-looking WAN IPs from VirtualBox's internal DHCP (e.g., `10.0.2.15`), this interface is designed purely for **outbound-only** connectivity to the internet — not for direct inter-VM communication.

**B. Asymmetric NAT traversal.** WireGuard uses stateless UDP. To work around the isolation, traffic was routed through the shared **virtual gateway** address (`10.0.2.2`). While the outbound handshake packet from Branch could reach HQ (assisted by VirtualBox port forwarding on the host), HQ's own NAT engine had no corresponding translation state to route the reply packet back into Branch's isolated NAT space — so the reply was silently dropped.

**C. WireGuard cryptokey routing rejection.** WireGuard validates incoming packets against each peer's configured `allowed-address` list based on source IP. The double-NAT hairpin path via the virtual gateway altered the effective source address of the reply packet, causing WireGuard's own cryptokey routing to reject it even if it had arrived.

### 3.3 Workarounds Considered and Rejected (at the time)

During initial troubleshooting, two workarounds were deliberately set aside to preserve the existing validated architecture:

- **Changing adapter type (Internal Network / Host-only) for the primary WAN link** — rejected at the time due to concern it would compromise the already-validated Phase 1 design (removing WAN/internet access and disrupting routing/VLAN management).
- **Modifying Windows Host firewall/NAT rules** — rejected in order to preserve homelab isolation and avoid altering the host operating system's own security posture.

### 3.4 Status at Time of Reporting

At the time this problem was documented, the Site-to-Site tunnel was considered blocked by an environment-level limitation:

- MikroTik-side configuration (Phase 1 and Phase 2) was independently verified as **theoretically correct** and left unchanged ("frozen").
- The Site-to-Site link was assessed as blocked purely by VirtualBox's default NAT engine, which does not support symmetric UDP hole-punching between VMs behind separate NAT instances.
- The Site-to-Site experiment within this fully host-isolated VirtualBox architecture was, at that point, marked as tentatively **suspended**, pending either a different environment (e.g., physical hardware or a cloud-hosted lab) or a revised approach to the WAN-link topology.

This is addressed in the companion document, **"Phase 2.3 / 2.4 — Troubleshooting & Resolution."**
