# Detection Capability Report: [Component Name]

Used for documenting monitoring/detection capability deployment (v3.0),
as opposed to attack scenario testing (v4.0, which uses
attack-scenario-template.md instead).

**Component:** [e.g. Wazuh SIEM / Suricata IDS]
**Date Deployed:** YYYY-MM-DD

## 1. Purpose

What visibility gap does this component close?

## 2. Deployment Summary

Brief description of how it was deployed (architecture, agents,
log sources connected).

## 3. Configuration Highlights

Key configuration decisions and why (not a full config dump —
link to the actual config file in the repo instead).

## 4. Verification

Evidence that the component is actually receiving and processing data
correctly (e.g. sample dashboard screenshot, test alert triggered
intentionally to confirm the pipeline works end-to-end).

## 5. Baseline Observations

What does "normal" look like once this component is running? This
becomes the reference point for v4.0 attack simulation.

## 6. Known Limitations

Anything not yet covered by this deployment (to be addressed in a
later version or scenario).
