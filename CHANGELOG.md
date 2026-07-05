# Changelog

All notable changes to this project are documented in this file.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning reflects project milestones, not semantic software versioning.

---

## [v1.0] - 2026-07-01 — Foundation

### Added

- MikroTik CHR deployed on Oracle VirtualBox as core router
- Network segmentation into 4 interfaces: WAN, Management, Departemen IT, Guest
- DHCP Server for IT and Guest segments
- NAT (Masquerade) for internet sharing
- Firewall Filter rules isolating Guest from internal IT network
- Hotspot captive portal with authentication for Guest network
- Simple Queue bandwidth management (IT: 20 Mbps, Guest: 5 Mbps)
- Monitoring via Torch (real-time traffic inspection)
- Automated configuration backup via Scheduler

### Notes

- Originally developed as a university final exam (UAS) project for the
  Instalasi Jaringan Komputer course
- All configurations tested and validated in isolated virtual environment
- Full report: [v1.0-foundation/docs/](./v1.0-foundation/docs/)

---

## [v2.0] - 2026-07-05 — Network Segmentation & Enterprise Services

### Added

- 802.1Q VLAN trunk between HQ router and a dedicated access switch
- Four VLANs: IT (10), Guest (20), DMZ (30), Security (50)
- DMZ containment: firewall isolation (Input + Forward chains), port
  forwarding to a public-facing service, Nginx reverse proxy in front
  of the DMZ host
- VPN Remote Access via WireGuard, scoped to the IT VLAN only
- VPN Site-to-Site via WireGuard to a simulated Branch Office router,
  with its own independent LAN and internet path

### Fixed

- VirtualBox Promiscuous Mode ("Deny" by default) silently dropping
  802.1Q trunk frames at the hypervisor layer (v2.1)
- Stateful firewall gap allowing DMZ containment rules to block
  legitimate return traffic for IT-initiated connections (v2.2)
- WireGuard Site-to-Site NAT hairpin preventing handshake completion
  between two NAT-mode VirtualBox routers, resolved via a dedicated
  point-to-point WAN-link segment (v2.4)
- Missing static routes for remote subnets after a successful
  WireGuard handshake (allowed-address governs crypto acceptance, not
  routing) (v2.4)

### Changed

- DMZ renumbered from the originally planned VLAN 99 to VLAN 30
  (operational convenience, no functional impact)

### Deferred

- Finance VLAN (40) — architecture supports it, not yet implemented

### Documentation

- Full architecture blueprint: `docs/architecture/v2-v3-architecture-blueprint.md`
- Implementation logs: `v2.0-segmentation/docs/`

---

## [v3.0] - Planned — Enterprise Security Monitoring

### Planned

- Centralized syslog collection from MikroTik
- Wazuh deployment (manager + agents) as SIEM
- Suricata deployment as network IDS/IPS
- Baseline "normal traffic" profiling before attack simulation phase

---

## [v4.0] - Planned — Attack Simulation & Detection Engineering

### Planned

- MITRE ATT&CK-mapped attack scenarios executed from Kali Linux
- Detection validation against Wazuh/Suricata
- MTTD (Mean Time to Detect) measurement per scenario
- Custom detection rule authoring and iterative re-validation

---

## [v5.0] - Planned — Automation & Infrastructure as Code

### Planned

- Ansible playbooks for reproducible lab provisioning
- Python scripts for log parsing / automated detection support

---

## [v6.0] - Planned — Cloud Hybrid Security Lab

### Planned

- Site-to-site VPN from on-prem lab to cloud VPC
- Wazuh agent deployment on cloud instances
- Hybrid centralized monitoring (on-prem + cloud)
