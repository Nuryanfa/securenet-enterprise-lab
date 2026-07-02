# v1.0 — Foundation

Status: ✅ Complete (2026-07-01)

## Summary

Core enterprise router foundation built on MikroTik CHR, running in a
fully virtualized environment (Oracle VirtualBox). This version
establishes the base network segmentation and services that every
later version builds on top of.

## What's Implemented

- 4-segment network: WAN, Management, Departemen IT, Guest
- DHCP Server (IT + Guest segments)
- NAT (Masquerade) for internet sharing
- Firewall Filter — Guest isolated from internal IT network
- Hotspot captive portal authentication (Guest)
- Simple Queue bandwidth management (IT: 20 Mbps / Guest: 5 Mbps)
- Real-time monitoring via Torch
- Automated configuration backup (Scheduler)

## Contents of This Folder

- `configs/` — Sanitized RouterOS configuration export (`.rsc`)
- `screenshots/` — Implementation and testing evidence
- `docs/` — Full original report (converted from the source academic report)

## Origin Note

This version began as a university final exam (UAS) project for the
*Instalasi Jaringan Komputer* course. It has since been adopted as the
foundation for this independent, ongoing portfolio project and will
continue to be extended well beyond the original academic scope.

## Full Report

See [docs/full-report.md](./docs/full-report.md) for the complete
original documentation (background, requirements analysis, design,
implementation, and testing).
