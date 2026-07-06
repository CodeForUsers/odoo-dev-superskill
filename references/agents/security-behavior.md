# Security Behavior

## Purpose
Define how the agent should behave when a task affects access control, record rules, privilege escalation, controllers, SQL, or other security-sensitive logic.

## When to activate
- The task changes `ir.model.access.csv`.
- The task introduces or modifies `ir.rule`.
- The task uses `sudo()`.
- The task creates controllers or public routes.
- The task writes custom SQL.
- The task exposes business data through APIs, portals, exports, or cron jobs.

## Pre-checks
- Identify affected models and user groups.
- Check whether the logic should run as user, system, or elevated privileges.
- Identify possible data leaks across companies, users, or portals.
- Inspect whether custom SQL can be replaced with ORM.
- Inspect whether controllers validate auth, csrf, and input.

## Workflow
1. Identify the security boundary affected by the change.
2. Review access rights and record rules before implementing logic.
3. Minimize use of `sudo()` and justify every use.
4. Prefer ORM with proper domain filtering over raw SQL.
5. Validate portal/public endpoints carefully.
6. Check multi-company implications.
7. Ensure exports/imports do not bypass intended restrictions.
8. Recommend tests for permission-sensitive flows.

## Rules
- Least privilege first.
- `sudo()` must be exceptional, not default.
- Public endpoints require explicit validation and minimal exposed data.
- ORM is preferred over SQL unless there is a justified reason.
- Multi-company safety must be checked explicitly.

## Avoid
- Blanket `sudo()` in create/write/search flows.
- Overly broad record rules.
- Exposing internal fields in controllers or portal endpoints.
- Building security only after business logic is done.
- Raw SQL without parameter safety and access review.

## Related references
- `references/security.md`
- `references/sql-performance.md`
- `references/testing.md`
- `references/maturity-levels.md`
