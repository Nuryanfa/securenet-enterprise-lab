# Purple Team Workflow

This document describes the repeatable methodology used for every attack
scenario documented from v4.0 onward. The goal is not just to "attack and
report success" — it is to close the loop between offense and defense,
which is the actual value a purple team engineer brings.

## The Cycle

```
   ┌─────────────┐
   │  1. Plan     │  Define objective, technique (MITRE ATT&CK ID),
   │  (Threat     │  expected behavior, and target segment
   │   Model)     │
   └──────┬──────┘
          │
   ┌──────┴──────┐
   │  2. Red      │  Execute the technique from Kali Linux against
   │  (Attack)    │  the in-scope lab target
   └──────┬──────┘
          │
   ┌──────┴──────┐
   │  3. Blue     │  Check Wazuh / Suricata for detection.
   │  (Detect)    │  Record whether it was detected, and MTTD
   │              │  (Mean Time to Detect) if it was
   └──────┬──────┘
          │
   ┌──────┴──────┐
   │  4. Tune     │  If NOT detected (or detected too slowly):
   │  (Improve)   │  author or adjust a detection rule
   │              │  (Wazuh custom rule / Sigma rule)
   └──────┬──────┘
          │
   ┌──────┴──────┐
   │ 5. Re-       │  Re-run the exact same attack to validate
   │  validate    │  the new/tuned rule actually catches it
   └─────────────┘
```

Step 4–5 is the step most write-ups skip. It's also the step that
actually demonstrates purple team thinking rather than either pure
red team (attack and move on) or pure blue team (defend without
ever testing the defense against a real technique).

## Documentation Standard

Every scenario is documented using
[docs/templates/attack-scenario-template.md](../templates/attack-scenario-template.md)
and stored under:

```
v4.0-attack-simulation/scenarios/<MITRE-technique-id>-<short-name>/
├── report.md              # Filled-out template
├── evidence/               # Screenshots, alert exports
└── detection-rule.yml      # If a new/tuned rule was created (optional)
```

## Metrics Tracked Per Scenario

- **MITRE ATT&CK Technique ID** — for consistent categorization
- **MTTD (Mean Time to Detect)** — time between attack execution and
  alert generation, in seconds/minutes. Recorded as "Not Detected" if
  no alert fires within a defined observation window (default: 15 minutes)
- **Detection source** — which tool caught it (Wazuh rule ID, Suricata
  signature ID, or "none" if undetected pre-tuning)
- **False positive consideration** — brief note on whether the new/tuned
  rule risks flagging legitimate traffic, and how that risk was mitigated

## Why This Matters

A resume line that says "simulated brute force attack" is common and
low-signal. A documented cycle showing: the attack was not initially
detected → a specific rule was written to catch it → the same attack was
re-run and successfully detected with a measured MTTD — is a demonstrable,
verifiable purple team skill, not a claim.
