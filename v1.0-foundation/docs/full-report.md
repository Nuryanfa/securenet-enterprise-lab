# v1.0 Full Report — SecureNet Enterprise Lab Foundation

Status: ✅ Complete | Originally built as a university final exam (UAS) project for *Instalasi Jaringan Komputer*, now the foundation of an ongoing independent security lab.

---

## Objective

Design and implement a simulated enterprise network infrastructure for a fictional company, **PT SecureNet Indonesia**, using MikroTik Cloud Hosted Router (CHR) in a fully virtualized environment. The goal was to build a segmented, internet-sharing network with authenticated guest access, traffic management, monitoring, and automated backup — the baseline every later version of this lab extends.

---

## Architecture

```
                    ┌─────────────┐
                    │  Internet   │
                    └──────┬──────┘
                           │ ether1 (DHCP Client)
                    ┌──────┴──────┐
                    │ MikroTik CHR│
                    │  (Router)   │
                    └──────┬──────┘
          ┌────────────────┼────────────────┐
       ether2            ether3            ether4
   ┌──────┴─────┐   ┌──────┴─────┐   ┌──────┴─────┐
   │ Management │   │Departemen  │   │   Guest    │
   │    PC      │   │ IT (Kali)  │   │ (Windows,  │
   │            │   │            │   │  Hotspot)  │
   └────────────┘   └────────────┘   └────────────┘
```

| Interface | Function | Network | DHCP | Hotspot |
|---|---|---|---|---|
| ether1 | WAN | DHCP Client | – | – |
| ether2 | Management | 192.168.100.0/24 | ❌ | ❌ |
| ether3 | Departemen IT | 192.168.10.0/24 | ✅ | ❌ |
| ether4 | Guest | 192.168.20.0/24 | ✅ | ✅ |

Full diagram: [`../../docs/architecture/diagrams/`](../../docs/architecture/diagrams/)

---

## Key Design Decisions

- **Four-interface segmentation instead of a flat network** — separates administrative traffic (Management), internal operational traffic (IT), and untrusted traffic (Guest), so a compromise or misuse on one segment doesn't automatically expose the others.
- **Management interface has no DHCP or Hotspot** — router administration is only reachable via a manually-assigned static IP, reducing the attack surface for the control plane.
- **Guest network requires Hotspot authentication before internet access** — prevents anonymous, unauthenticated use of the network and gives a clear audit point (who logged in, when).
- **Firewall isolates Guest from IT at the Forward chain** — Guest devices can reach the internet but cannot reach any host on the IT segment, enforced by explicit drop rules rather than relying on routing alone.
- **Bandwidth allocation reflects business priority** — IT (20 Mbps) is treated as operational-critical traffic; Guest (5 Mbps) is capped lower since it's non-critical, shared, and transient by nature.

---

## What Was Implemented

| Feature | Status | Notes |
|---|---|---|
| DHCP Server | ✅ | Separate pools for IT (`192.168.10.2–254`) and Guest (`192.168.20.2–254`) |
| NAT (Masquerade) | ✅ | Single rule on WAN interface, shared by both internal segments |
| Firewall Filter | ✅ | Guest↔IT isolation enforced on Forward and Input chains |
| Hotspot | ✅ | Captive portal authentication on Guest segment only |
| QoS (Simple Queue) | ✅ | IT: 20 Mbps / Guest: 5 Mbps |
| Monitoring | ✅ | Real-time traffic inspection via Torch |
| Automated Backup | ✅ | Daily scheduled backup via Scheduler + Script |

Sanitized configuration export: [`../configs/`](../configs/)

---

## Testing & Results

| Test | Result |
|---|---|
| Client receives IP automatically (DHCP) | ✅ Pass |
| Client → Gateway (own segment) | ✅ Pass |
| Client → Internet (IT segment) | ✅ Pass |
| Client → Internet (Guest, after Hotspot login) | ✅ Pass |
| Client → Domain resolution (`ping google.com`) | ✅ Pass |
| Guest → IT segment (should be blocked) | ✅ Blocked as expected |
| Firewall rule counter increments on blocked attempt | ✅ Confirmed (20 packets logged) |
| Bandwidth limit enforced (Speedtest) | ✅ IT: 19/13 Mbps (limit 20) · Guest: 3/3 Mbps (limit 5) |
| Scheduled backup executes and produces a new file | ✅ Confirmed via Run Count + file timestamp |

Full testing methodology and additional test cases: see the academic report (link below).

---

## Key Evidence


1. Network topology diagram
![alt text](<screenshots/topology-networking-implementation.png>)
2. DHCP lease list — clients receiving IPs automatically
![alt text](<screenshots/mikrotik-ip-dhcp-leases.png>)
3. Hotspot login page + successful login
![alt text](<screenshots/hotspot-login.png>)
4. Firewall filter rule counter (packets = 20) proving the block is active
![alt text](<screenshots/firewall.png>)
5. Failed ping from Guest to IT gateway (Input chain block)
![alt text](<screenshots/ping-guest.png>)
6. Failed ping from Guest to IT host directly (Forward chain block)
![alt text](<screenshots/ping-guest2.png>)
7. Simple Queue traffic graph — Guest throughput capped near 5 Mbps
![alt text](<screenshots/simplequeuegraph.png>)
8. Speedtest results — IT vs Guest, both under their configured limits
![alt text](<screenshots/speedtest-it.png>)
![alt text](<screenshots/speedtest-guest.png>)
9. Scheduler Run Count incrementing after manual/automated trigger
![alt text](<screenshots/scheduler.png>)
10. New backup file with post-test timestamp
![alt text](<screenshots/backup.png>)
11. Torch capturing Hotspot login traffic on port 80
![alt text](<screenshots/torch.png>)


## Challenges & Resolutions

| Challenge | Root Cause | Resolution |
|---|---|---|
| Guest not redirected to Hotspot login | Client DNS not pointing to router | Enabled DNS relay, set DHCP-assigned DNS to router gateway |
| Firewall drop rule not blocking traffic | Rule order — drop placed after a general accept rule | Reordered rule chain (drop before accept) |
| Guest had no internet after Hotspot login | NAT rule scoped only to IT subnet | Generalized Masquerade rule to WAN interface, covering all subnets |
| VM-to-VM connectivity unstable | Inconsistent VirtualBox Internal Network naming across adapters | Standardized Internal Network names across all connected VMs |
| Scheduled backup script not executing | Missing required policy permissions on the script | Added full required policy set (`read`, `write`, etc.) |
| Speedtest results far below expected values despite 100 Mbps host connection | **Unlicensed MikroTik CHR hard-capped at 1 Mbps per interface** | Activated MikroTik trial license (`/system license renew`) — removed the artificial cap entirely |

This last issue is worth highlighting specifically: it wasn't a configuration mistake, but a licensing constraint of MikroTik CHR itself. Diagnosing it required distinguishing between "my Queue configuration is wrong" and "the platform is capping me below my Queue limit" — a useful reminder that infrastructure constraints can masquerade as configuration bugs.

---

**Note on Firewall Chain Behavior:** Testing distinguished between two 
firewall chains deliberately. A ping from Guest to the IT gateway 
(192.168.10.1) is evaluated against the **Input chain**, since the 
router itself is the destination — confirmed by the counter on rule 
"Blokir Akses Guest ke Gateway IT" (12 packets). A ping from Guest to 
a host within the IT segment (Kali Linux, not the gateway) is instead 
evaluated against the **Forward chain**, since the traffic passes 
through the router toward another host — confirmed by the counter on 
rule "Blokir Guest ke IT" incrementing only after this second test. 
Both chains were validated independently to confirm complete isolation, 
not just isolation at the gateway level.

## What This Enables Next

This foundation establishes working segmentation, internet sharing, and basic access control — but segmentation here is still done purely at the interface/subnet level, with no VLAN trunking, no isolated DMZ for public-facing services, and no encrypted remote access. **v2.0** builds directly on top of this by introducing VLANs, a proper DMZ, and VPN connectivity, turning this from "a segmented lab" into something closer to real enterprise network architecture.

---

## Full Academic Report

This summary intentionally omits theoretical background, detailed requirements analysis, and step-by-step configuration narration, which are covered in depth in the original academic report submitted for coursework:

📄 [Full Detailed Report (PDF)](./v1.0-detailed-report.pdf)
