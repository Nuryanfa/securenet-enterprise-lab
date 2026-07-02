# Attack Scenario Report: [Short Descriptive Name]

**MITRE ATT&CK Technique:** T#### — [Technique Name]
**Date:** YYYY-MM-DD
**Target Segment:** [e.g. Guest → Hotspot login]
**Tester:** [Your name]

---

## 1. Objective

What is being tested and why. What real-world attack behavior does this
scenario represent, and why is it relevant to this lab's architecture?

## 2. Threat Model / Assumption

What access level does the attacker start with? (e.g. "attacker is an
unauthenticated user on the Guest Wi-Fi, no prior credentials")

## 3. Execution (Red Phase)

Step-by-step description of the attack as performed, including tools
and commands used. Include timestamps.

```bash
# Example command(s) used
```

**Evidence:** [link to screenshot/pcap in ./evidence/]

## 4. Detection Result (Blue Phase)

| Field | Result |
|---|---|
| Detected? | Yes / No |
| Detection source | Wazuh rule ID / Suricata SID / None |
| Time of attack start | HH:MM:SS |
| Time of first alert | HH:MM:SS |
| **MTTD** | X minutes / seconds / Not Detected |

**Evidence:** [link to alert screenshot/export in ./evidence/]

## 5. Tuning (If Not Detected or Detected Too Slowly)

Description of the detection gap and the rule created/modified to close it.

```yaml
# detection-rule.yml content or reference
```

## 6. Re-validation

Result of re-running the identical attack after tuning.

| Field | Result |
|---|---|
| Detected on re-run? | Yes / No |
| New MTTD | X minutes / seconds |

## 7. False Positive Consideration

Brief note on whether this rule could trigger on legitimate traffic,
and what was done (if anything) to reduce that risk.

## 8. Lessons Learned

Short reflection — what did this scenario reveal about the lab's
detection coverage, and what would you prioritize next as a result?
