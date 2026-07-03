# v3.0 — Enterprise Security Monitoring

Status: 🔜 Planned

## Goal

Establish full visibility into the lab environment: centralized logging,
SIEM (Wazuh), and network IDS/IPS (Suricata) — the detection backbone
that v4.0 attack simulations will be measured against.

## Architecture Blueprint

Full architecture blueprint: [v2-v3-architecture-blueprint.md](../docs/architecture/v2-v3-architecture-blueprint.md)

## Planned Sub-Milestones

- [ ] v3.1 — Centralized syslog collection from MikroTik
- [ ] v3.2 — Wazuh deployment (manager + agents)
- [ ] v3.3 — Suricata deployment, alerts forwarded to Wazuh
- [ ] v3.4 — Baseline "normal traffic" profiling
- [ ] v3.5 — Custom Active Response script (Wazuh AR + MikroTik API integration)

See [../ROADMAP.md](../ROADMAP.md) for full details.

## Contents (once complete)

- `wazuh/` — Wazuh manager/agent configuration, custom rules
- `suricata/` — Suricata configuration, custom signatures
- `screenshots/` — Dashboards, alert verification evidence
