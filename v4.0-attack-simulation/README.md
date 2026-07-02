# v4.0 — Attack Simulation & Detection Engineering

Status: 🔜 Planned

## Goal

The core of this project's purple team story. Execute MITRE ATT&CK-mapped
attack scenarios against the lab, measure detection outcomes, and close
the loop by tuning detection rules and re-validating.

Methodology: [../docs/methodology/purple-team-workflow.md](../docs/methodology/purple-team-workflow.md)
Rules of Engagement: [../docs/methodology/rules-of-engagement.md](../docs/methodology/rules-of-engagement.md)

## Planned Scenarios

| Technique ID | Name | Status |
|---|---|---|
| T1110 | Brute Force (Hotspot login) | 🔜 Planned |
| T1046 | Network Service Discovery (Guest → IT probing) | 🔜 Planned |
| T1071 | Application Layer Protocol (simulated C2 beacon) | 🔜 Planned |
| T1562 | Impair Defenses | 🔜 Planned |

Each scenario will get its own folder under `scenarios/<technique-id>-<name>/`
using [../docs/templates/attack-scenario-template.md](../docs/templates/attack-scenario-template.md).

## Contents (once complete)

- `scenarios/` — One folder per attack scenario, each with a full report
- `detection-rules/` — Custom Wazuh/Sigma rules authored as a result of testing
