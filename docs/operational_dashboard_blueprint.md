# Operational Dashboard Blueprint

Context: current Flutter app is a starter template with no auth, routing, or backend wiring. This document defines the target architecture, RBAC, data model, APIs, UI surfaces, integrations, reporting, and delivery slices for the Operational Dashboard (Fleet + Driver + Ticketing).

## RBAC (Operational Dashboard)
- Permission groups: `vehicle:create`, `vehicle:review`, `vehicle:approve`, `vehicle:view`, `vehicle:assign`, `vehicle:logs`, `driver:create`, `driver:verify`, `driver:train`, `driver:approve`, `driver:view`, `driver:assign`, `driver:logs`, `dashboard:view`, `ticket:view`, `ticket:update`, `notifications:manage`, `reports:view`, `audit:view`.
- Role matrix (✓ full, △ limited scope, • view):

| Role | Vehicle CRUD | Vehicle Review/Approve | Vehicle Logs | Driver Onboard | Background Verification | Training Assign | Driver Approve | Driver Logs | Dashboards | Tickets | Notifications | Reports/Audit |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Operational Admin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Fleet Admin | ✓ | ✓ | ✓ | • | • | • | • | • | ✓ | ✓ | ✓ | ✓ |
| Sub Fleet Admin | ✓ | ✓ | ✓ | • | • | • | • | • | ✓ | ✓ | △ | ✓ |
| Fleet Manager | • | • | ✓ | • | • | • | • | • | ✓ | ✓ | △ | ✓ |
| Fleet Team | • | ✓ | △ | • | • | • | • | • | • | ✓ | • | • |
| Fleet Individual | ✓ (own) | • (submit) | △ (own) | • | • | • | • | • | • | • | • | • |
| Driver Admin | • | • | • | ✓ | ✓ | ✓ | ✓ (final) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Sub Driver Admin | • | • | • | • | ✓ | ✓ | • | ✓ | ✓ | ✓ | ✓ | ✓ |
| Driver Manager | • | • | • | ✓ | ✓ | • | • | ✓ | ✓ | ✓ | • | • |
| Driver Team | • | • | • | ✓ | ✓ | • | • | △ | ✓ | • | • | • |
| Driver Individual | • | • | • | ✓ (submit) | • | • | • | △ (own) | • | • | • | • |

Notes:
- Ticket visibility: Fleet roles see vehicle-labelled tickets; Driver roles see driver-labelled tickets; Operational Admin sees all.
- Only Driver Admin can final-approve drivers; Fleet Manager receives review logs/notifications; Sub roles can assign training (driver) or add vehicles (fleet) within scope.

## Data Model (conceptual)
- `User`: id, name, email, phone, role_id, team_id.
- `Role`: id, name, permissions[].
- `Vehicle`: id, number_plate, make, model, year, insurance_policy_number, insurance_expiry, live_location_key, dashcam_key, status (active/inactive), created_by, created_at, updated_at.
- `VehicleReview`: id, vehicle_id, reviewer_id, status (pending/approved/rejected), comments, created_at.
- `VehicleLog`: id, vehicle_id, actor_id, action (created/reviewed/approved/rejected/assign_driver/update), payload (JSON), timestamp.
- `VehicleAssignment`: id, vehicle_id, driver_id, assigned_by, assigned_at, unassigned_at.
- `VehicleMetricsDaily`: vehicle_id, date, total_rides, distance_km, charging_sessions, active_minutes.
- `Driver`: id, name, mobile, email, status (pending/verified/approved/rejected), onboarding_data (JSON), contact_preferences, created_by, created_at, updated_at.
- `DriverDocument`: id, driver_id, type, url, status (uploaded/verified/rejected), verified_by, verified_at.
- `DriverBackgroundCheck`: id, driver_id, status (pending/clear/flagged), notes, verified_by, verified_at.
- `DriverTrainingAssignment`: id, driver_id, module (technical/soft-skill/other), status (assigned/in_progress/completed), assigned_by, completed_at.
- `DriverLog`: id, driver_id, actor_id, action (onboard, verify_docs, bg_check, assign_training, allocate_vehicle, approve), payload, timestamp.
- `Ticket`: id, source (driver_app), vehicle_number, driver_name, driver_mobile, category, status (open/in_progress/resolved/closed), priority, description, attachments[], created_at, updated_at, assigned_to.
- `Notification`: id, actor_id, target_id, type (approval, assignment, ticket, training), channel (email/sms/in-app), payload, status (queued/sent/failed), timestamps.
- `AuditLog`: id, actor_id, action, entity_type, entity_id, before, after, timestamp.
- `RideSummary`: id, vehicle_id, driver_id, started_at, ended_at, distance_km, status, fare, created_at.

## Workflows (state + logging)
- Vehicle onboarding: Individual submits → Team reviews/approves → Fleet Manager notified/logged → Sub/Fleet Admin can add directly and oversee logs. All actions append `VehicleLog` and `AuditLog`.
- Driver onboarding: Individual adds → Team background verification → Sub Driver Admin assigns training → Driver Admin final approval → vehicle allocation logged in `DriverLog` and `VehicleAssignment`.
- Tickets: Ingested from driver app with vehicle/driver labels → triage/assign → status transitions logged.

## API/Service Contracts (REST shape)
- Auth assumed existing session/JWT; add route guards for permissions above.
- Vehicles:
  - `POST /vehicles` {number_plate, make, model, insurance_policy_number, insurance_expiry, live_location_key, dashcam_key}
  - `GET /vehicles?status=&search=&page=&page_size=`
  - `POST /vehicles/{id}/review` {status: approved|rejected, comments}
  - `POST /vehicles/{id}/assign-driver` {driver_id}
  - `GET /vehicles/{id}/logs`
  - `GET /vehicles/{id}/metrics?range=30d`
- Drivers:
  - `POST /drivers` {name, mobile, email, onboarding_data, contact_preferences, documents[]}
  - `GET /drivers?status=&search=&page=&page_size=`
  - `POST /drivers/{id}/background-check` {status, notes}
  - `POST /drivers/{id}/training` {module, status}
  - `POST /drivers/{id}/approve` {decision, comments}
  - `POST /drivers/{id}/assign-vehicle` {vehicle_id}
  - `GET /drivers/{id}/logs`
- Tickets:
  - `POST /tickets` {vehicle_number, driver_name, driver_mobile, category, priority, description, attachments}
  - `GET /tickets?status=&category=&assigned_to=&page=&page_size=`
  - `PATCH /tickets/{id}` {status, assigned_to, resolution_notes}
- Dashboards:
  - Fleet panel: `GET /dashboards/fleet` → {total_vehicles, active_vehicles, total_rides, per_vehicle_charging_capability[], per_vehicle_distance[], live_status[]}
  - Vehicle detail: `GET /dashboards/vehicle/{id}` → vehicle info, ride totals, booking history, assignments, live location URL/key, dashcam feed URL/key.
  - Driver list/detail: `GET /dashboards/drivers` and `GET /dashboards/driver/{id}` → ride counts, assignment history, logs.
- Notifications:
  - `POST /notifications/test`
  - Event hooks: on approval, training assignment, ticket updates.
- Standard responses: wrap data + error codes; use pagination (page, page_size, total); use idempotent retries for ticket ingestion.

## UI / Navigation (Flutter admin)
- Navigation sections (permission-gated): Fleet, Vehicles, Drivers, Tickets, Notifications, Reports.
- Fleet Panel dashboard: cards (total/active vehicles, total rides), charts (distance/charging per vehicle), table with live status.
- Vehicle detail: info, access keys, metrics, booking history, assigned drivers, live map embed, dashcam feed embed, logs tab.
- Driver list: name, assigned vehicle, mobile, status (from driver app), filters; row click → detail.
- Driver detail: onboarding info, rides initiated, assignment history with timestamps, logs (who assigned what/when), training status.
- Onboarding/review forms: vehicle creation, vehicle review, driver submission, background verification, training assignment, final approval; show action log context.
- Ticket list/detail: source fields (vehicle number, driver name/mobile), status, priority, assignee; timeline of updates.
- Notifications center: inbox of triggers; controls per role if allowed.

## Integrations & Telemetry
- GPS tracking API: store `live_location_key`, embed map via provider SDK; poll or subscribe (websocket) for live status.
- Dashcam feed API: store `dashcam_key`, retrieve stream URL/token per request; gate access by permission and audit access.
- Notification system: Email/SMS via provider; in-app via websocket/push channel; retries + failure logging.
- Training module engine: store module references; mark progress in `DriverTrainingAssignment`.
- Metrics collection: daily aggregates for rides, distance, charging, active minutes per vehicle; use for dashboards.

## Reporting & Audit
- Reports: vehicle summary, driver onboarding, approval logs, ride/trip summaries, training completion, ticket stats.
- Export CSV/PDF endpoints; filter by date/team/role.
- Audit logging: every mutation writes `AuditLog` with actor, before/after, timestamp; surface in admin-only views.

## Delivery Slices (milestones)
1) RBAC plumbing + entities/schemas + audit logging.
2) Vehicle onboarding workflow (create/review/approve + logs + notifications).
3) Driver onboarding + background + training + final approval + vehicle allocation + logs.
4) Dashboards (fleet panel, vehicle detail, driver detail) with metrics stubs and live keys wiring.
5) Ticket ingestion/list/detail with status transitions and notifications.
6) Reporting exports + hardening (errors, retries, pagination) + QA.

