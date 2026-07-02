# SecureNet Enterprise Lab

> Purple Team-focused enterprise network security lab — built, attacked, defended, and continuously hardened by a single engineer as a long-term hands-on portfolio project.

![Status](https://img.shields.io/badge/status-in--progress-yellow)
![Current Version](https://img.shields.io/badge/version-v1.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## What This Is

SecureNet Enterprise Lab is a self-hosted, fully virtualized enterprise network — designed, built, attacked, and defended entirely by me as a long-term (6-month) portfolio project targeting a **Purple Team / Security Engineer** role.

Unlike a typical "follow the tutorial" home lab, this project is built iteratively as **versioned releases**, the same way a real product would be developed. Each version adds a layer of enterprise capability, is fully documented, and — starting at v4 — includes actual attack simulations mapped to MITRE ATT&CK, with measured detection outcomes and iterative detection tuning.

**Why this exists:** to demonstrate, with evidence (not just claims), that I can design secure network architecture, operate enterprise security tooling, think like an attacker, and close the loop by turning what I learn from attacks into better detection — the core loop of purple teaming.

---

## Roadmap & Versions

| Version | Focus | Status | Docs |
|---|---|---|---|
| **v1.0** | Foundation — MikroTik CHR router, DHCP, NAT, Firewall, Hotspot, QoS, Monitoring, Backup | ✅ Complete | [v1.0-foundation/](./v1.0-foundation/) |
| **v2.0** | Network Segmentation — VLAN, inter-VLAN routing, DMZ, VPN (remote + site-to-site) | 🔜 Planned | [v2.0-segmentation/](./v2.0-segmentation/) |
| **v3.0** | Security Monitoring — centralized logging, Wazuh (SIEM), Suricata (IDS/IPS) | 🔜 Planned | [v3.0-monitoring/](./v3.0-monitoring/) |
| **v4.0** | Attack Simulation & Detection Engineering — MITRE ATT&CK-mapped scenarios, MTTD measurement, detection rule tuning | 🔜 Planned | [v4.0-attack-simulation/](./v4.0-attack-simulation/) |
| **v5.0** | Automation & IaC — Ansible provisioning, Python detection/parsing scripts | 🔜 Planned | [v5.0-automation/](./v5.0-automation/) |
| **v6.0** | Cloud Hybrid Security — hybrid VPN to cloud VPC, centralized monitoring across on-prem + cloud | 🔜 Planned | [v6.0-cloud-hybrid/](./v6.0-cloud-hybrid/) |

Full detailed roadmap with sub-milestones: [ROADMAP.md](./ROADMAP.md)
Version history and release notes: [CHANGELOG.md](./CHANGELOG.md)

---

## Architecture Overview

The lab simulates **PT SecureNet Indonesia**, a fictional enterprise, running entirely on virtualized infrastructure (Oracle VirtualBox / eventually hybrid with cloud in v6).

```
                    ┌─────────────┐
                    │  Internet   │
                    └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │ MikroTik CHR│   ← Core router: NAT, Firewall,
                    │  (Router)   │     Hotspot, QoS, DHCP
                    └──────┬──────┘
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────┴─────┐   ┌──────┴─────┐   ┌──────┴─────┐
   │ Management │   │Departemen  │   │   Guest    │
   │  Network   │   │     IT     │   │  (Hotspot) │
   └────────────┘   └────────────┘   └────────────┘
```

Full architecture diagrams (updated per version): [docs/architecture/](./docs/architecture/)

---

## Purple Team Methodology

Starting from v4, every attack scenario follows a consistent red → blue → tune → re-validate cycle, documented with a standard template:

**Objective → Technique (MITRE ATT&CK ID) → Execution → Detection Result → MTTD → Tuning → Re-validation**

See methodology details: [docs/methodology/purple-team-workflow.md](./docs/methodology/purple-team-workflow.md)
Rules of Engagement (scope, authorization, boundaries): [docs/methodology/rules-of-engagement.md](./docs/methodology/rules-of-engagement.md)

All offensive testing in this repository is performed exclusively against my own isolated lab environment. No third-party systems, production infrastructure, or external networks are targeted at any point.

---

## Repository Structure

```
securenet-enterprise-lab/
├── README.md                      # You are here
├── CHANGELOG.md                   # Version history
├── ROADMAP.md                     # Detailed roadmap & sub-milestones
├── docs/
│   ├── architecture/              # Network diagrams (per version)
│   ├── methodology/                # Purple team workflow, rules of engagement
│   └── templates/                  # Reusable report templates
├── v1.0-foundation/                # Router config exports, screenshots, report
├── v2.0-segmentation/              # VLAN/DMZ/VPN configs & diagrams
├── v3.0-monitoring/                # Wazuh + Suricata configs & rules
├── v4.0-attack-simulation/         # Per-scenario attack + detection reports
├── v5.0-automation/                 # Ansible playbooks, Python scripts
├── v6.0-cloud-hybrid/               # Cloud VPC configs, hybrid VPN setup
└── assets/                          # Images used in documentation
```

---

## Tech Stack

**Networking:** MikroTik RouterOS (CHR) · VLAN · VPN (WireGuard/IPsec)
**Security Monitoring:** Wazuh · Suricata · Syslog
**Offensive Tooling:** Kali Linux · MITRE ATT&CK framework
**Automation:** Ansible · Python
**Cloud:** *(TBD — AWS/Azure, decided in v6)*
**Virtualization:** Oracle VirtualBox

---

## About Me

Built by M. Nur Yanfa, Informatics Engineering student, as a long-term hands-on portfolio project targeting Purple Team / Security Engineer roles. Originally started as a university final-exam network infrastructure project, now developed independently and continuously beyond the academic scope.

- LinkedIn: 

---

## License

This repository is licensed under the MIT License — see [LICENSE](./LICENSE) for details. All configurations are sanitized (no real credentials, IPs, or licensed keys) before being published. See [docs/methodology/rules-of-engagement.md](./docs/methodology/rules-of-engagement.md) for testing scope and disclosure policy.
