# FloodForge iOS

SwiftUI iOS client for FloodForge: an autonomous flood detection + public warning platform.

## Features (MVP)
- Sites list with LOW/HIGH float state and derived status (NORMAL/RISING/CRITICAL/DEGRADED)
- Map view with site pins
- Alerts toggle + local notifications on escalation

## Data Contract
`GET /api/sites` returns:
```json
{ "status": "ok", "data": [ { "id": "...", "name": "...", "lowTriggered": false, "highTriggered": false, "status": "NORMAL", "updatedAt": "2025-12-31T09:10:00Z" } ] }
