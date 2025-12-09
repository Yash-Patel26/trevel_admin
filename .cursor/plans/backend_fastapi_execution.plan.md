# Backend (FastAPI + Postgres) Execution Plan

We will implement RBAC/auth guards, audit logging, and the Operational Dashboard back-end features (vehicle/driver onboarding, dashboards, ticketing) following the existing blueprint.

## Steps

1) Scaffold backend package: FastAPI app, settings (env-based), Postgres via SQLAlchemy, Alembic, structured logging and request ID middleware.
2) Auth & RBAC: JWT (access/refresh), users/roles/permissions schema, seed roles per `docs/operational_dashboard_blueprint.md`, dependency `require_permissions`.
3) Audit logging: table + decorator to capture before/after on mutations; admin endpoint to query logs with pagination.
4) Migrations: create all entities (vehicles, drivers, tickets, logs, notifications, ride_summaries) per blueprint; seed roles/permissions and an Operational Admin.
5) Vehicle workflow: endpoints for create/list/review/assign-driver/logs/metrics; permission checks; notifications; append vehicle_logs + audit logs.
6) Driver workflow: create/list/bg-check/training/approve/assign-vehicle/logs; permission checks; notifications; driver_logs + audit logs.
7) Ticketing: ingest from driver app; list/filter; patch status/assignee; notify assignee/admin; log updates.
8) Dashboards: fleet/vehicle/driver endpoints with aggregates and live keys (GPS/dashcam placeholders), pagination/filtering.
9) Reporting/exports stubs (CSV) and hardening (errors, retries, pagination).
10) Tests/CI: unit/service tests, RBAC guard tests, flow integration tests; lint/type/test in CI.

## Notes

- Blueprint reference: `docs/operational_dashboard_blueprint.md`.
- No frontend changes in this plan.

# Backend (FastAPI + Postgres) Execution Plan

We will implement RBAC/auth guards, audit logging, and the Operational Dashboard back-end features (vehicle/driver onboarding, dashboards, ticketing) following the existing blueprint.

## Steps

1) Scaffold backend package: FastAPI app, settings (env-based), Postgres via SQLAlchemy, Alembic, structured logging and request ID middleware.
2) Auth & RBAC: JWT (access/refresh), users/roles/permissions schema, seed roles per `docs/operational_dashboard_blueprint.md`, dependency `require_permissions`.
3) Audit logging: table + decorator to capture before/after on mutations; admin endpoint to query logs with pagination.
4) Migrations: create all entities (vehicles, drivers, tickets, logs, notifications, ride_summaries) per blueprint; seed roles/permissions and an Operational Admin.
5) Vehicle workflow: endpoints for create/list/review/assign-driver/logs/metrics; permission checks; notifications; append vehicle_logs + audit logs.
6) Driver workflow: create/list/bg-check/training/approve/assign-vehicle/logs; permission checks; notifications; driver_logs + audit logs.
7) Ticketing: ingest from driver app; list/filter; patch status/assignee; notify assignee/admin; log updates.
8) Dashboards: fleet/vehicle/driver endpoints with aggregates and live keys (GPS/dashcam placeholders), pagination/filtering.
9) Reporting/exports stubs (CSV) and hardening (errors, retries, pagination).
10) Tests/CI: unit/service tests, RBAC guard tests, flow integration tests; lint/type/test in CI.

## Notes

- Blueprint reference: `docs/operational_dashboard_blueprint.md`.
- No frontend changes in this plan.

# Backend (FastAPI + Postgres) Execution Plan

We will implement RBAC/auth guards, audit logging, and the Operational Dashboard back-end features (vehicle/driver onboarding, dashboards, ticketing) following the existing blueprint.

## Steps

1) Scaffold backend package: FastAPI app, settings (env-based), Postgres via SQLAlchemy, Alembic, structured logging and request ID middleware.
2) Auth & RBAC: JWT (access/refresh), users/roles/permissions schema, seed roles per `docs/operational_dashboard_blueprint.md`, dependency `require_permissions`.
3) Audit logging: table + decorator to capture before/after on mutations; admin endpoint to query logs with pagination.
4) Migrations: create all entities (vehicles, drivers, tickets, logs, notifications, ride_summaries) per blueprint; seed roles/permissions and an Operational Admin.
5) Vehicle workflow: endpoints for create/list/review/assign-driver/logs/metrics; permission checks; notifications; append vehicle_logs + audit logs.
6) Driver workflow: create/list/bg-check/training/approve/assign-vehicle/logs; permission checks; notifications; driver_logs + audit logs.
7) Ticketing: ingest from driver app; list/filter; patch status/assignee; notify assignee/admin; log updates.
8) Dashboards: fleet/vehicle/driver endpoints with aggregates and live keys (GPS/dashcam placeholders), pagination/filtering.
9) Reporting/exports stubs (CSV) and hardening (errors, retries, pagination).
10) Tests/CI: unit/service tests, RBAC guard tests, flow integration tests; lint/type/test in CI.

## Notes

- Blueprint reference: `docs/operational_dashboard_blueprint.md`.
- No frontend changes in this plan.