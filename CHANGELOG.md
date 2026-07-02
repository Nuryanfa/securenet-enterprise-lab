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

## [v2.0] - Planned — Network Segmentation & Enterprise Services

### Planned
- VLAN implementation with trunking and inter-VLAN routing
- DMZ for publicly-facing services (isolated from internal network)
- Remote access VPN (WireGuard)
- Site-to-site VPN (simulating branch office connectivity)

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
