# Roadmap

Target timeline: 6 months, developed part-time alongside other commitments.
Primary goal: Purple Team / Security Engineer portfolio, with growing emphasis
on cloud security as the project matures.

---

## v1.0 — Foundation ✅ Complete

MikroTik CHR-based enterprise router foundation: DHCP, NAT, Firewall,
Hotspot, QoS, Monitoring, Backup. Originally built for a university course,
now the base layer for everything that follows.

---

## v2.0 — Network Segmentation & Enterprise Services (Est. 4–5 weeks)

- [ ] **v2.1 VLAN** — trunking between switch/router, inter-VLAN routing,
      access port policy per department
- [ ] **v2.2 DMZ** — isolated segment for a public-facing service
      (e.g. web server), reverse proxy, tightly scoped port forwarding
- [ ] **v2.3 VPN — Remote Access** — WireGuard for individual remote access
- [ ] **v2.4 VPN — Site-to-Site** — simulate a branch office connecting
      back to HQ

**Purple team angle introduced here:** each segment gets a short
"attack surface note" — what could plausibly be attacked from this
segment, and what should be visible if it is. This sets up v4 properly
instead of starting threat modeling from zero.

---

## v3.0 — Enterprise Security Monitoring (Est. 5–6 weeks)

- [ ] **v3.1 Centralized Logging** — MikroTik syslog → log server
      (this is the prerequisite for everything else in v3)
- [ ] **v3.2 Wazuh** — SIEM manager + agents, dashboards, alerting
      (prioritized first — visible results, strong portfolio value)
- [ ] **v3.3 Suricata** — network IDS/IPS, alerts forwarded into Wazuh
      for a single pane of glass
- [ ] **v3.4 Baseline profiling** — capture what "normal" traffic looks
      like before attack simulation begins

---

## v4.0 — Attack Simulation & Detection Engineering (Est. 6–8 weeks)

This is the core of the purple team story. Each scenario follows the
Red → Blue → Tune → Re-validate cycle (see
[docs/methodology/purple-team-workflow.md](./docs/methodology/purple-team-workflow.md)).

Planned initial scenarios (expand as the lab grows):
- [ ] T1110 — Brute Force (against Hotspot login)
- [ ] T1046 — Network Service Discovery (Guest → IT lateral probing)
- [ ] T1071 — Application Layer Protocol (simulated C2 beacon over HTTP/DNS)
- [ ] T1562 — Impair Defenses (attempt to disable/evade monitoring, validate
      whether the attempt itself is detected)

Each scenario is documented individually under
`v4.0-attack-simulation/scenarios/<technique-id>/` using
[docs/templates/attack-scenario-template.md](./docs/templates/attack-scenario-template.md).

---

## v5.0 — Automation & Infrastructure as Code (Est. 3–4 weeks)

- [ ] **v5.1 Ansible** — playbooks to provision the lab reproducibly from
      scratch (proof of "not a one-off snowflake lab")
- [ ] **v5.2 Python tooling** — log parsing / detection-support scripts,
      built to speed up the v4 red-blue-tune loop

---

## v6.0 — Cloud Hybrid Security Lab (Est. 4–5 weeks)

- [ ] **v6.1 Hybrid VPN** — site-to-site from on-prem lab to a cloud VPC
- [ ] **v6.2 Hybrid Monitoring** — Wazuh agent on cloud instances,
      logs forwarded to the same central SIEM
- [ ] **v6.3 Cloud-native tooling (stretch goal)** — AWS GuardDuty/Security
      Hub or Azure Sentinel free tier, to demonstrate familiarity with
      cloud-native security tooling, not just VPN connectivity

---

## Notes on Scope

- v1–v3 alone already form a solid, differentiated portfolio. v4 is the
  biggest differentiator. v5–v6 are valuable additions but not a blocker
  for the project to be "presentable" if time runs short.
- Each version is published as a GitHub Release with its own changelog
  entry and tag (see versioning strategy in the main README).
