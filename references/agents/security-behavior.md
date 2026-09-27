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

## Workflow (Odoo 20 Security Audit Patterns)
1. **Identify the security boundary**: check user context, groups, and multi-company borders.
2. **Access control**: review `ir.model.access.csv` and `ir.rule` before writing logic.
3. **Audit privilege escalation**: minimize `sudo()`, scope it to the narrowest target, and add an inline justification comment.
4. **Parameterize SQL**: prefer ORM; if raw SQL is required, strictly wrap parameters using `SQL(...)`.
5. **Protect public methods**: default to private methods (`_` prefix) so methods are not unintentionally exposed to RPC.
6. **Validate endpoints**: check `auth` (`user`, `public`, `none`), verify CSRF, and sign webhooks.
7. **Prevent file and injection risks**: open files with `odoo.tools.file_open` (not built-in `open()`), and avoid `eval` or deserialization.
8. **Test security boundaries**: write tests asserting both permission granted and permission denied.

## Rules
- Least privilege first.
- `sudo()` must be exceptional, narrow-scoped, and documented.
- Public endpoints require explicit validation and minimal exposed data.
- ORM is preferred over SQL unless there is a justified reason.
- Multi-company safety must be checked explicitly.

## Avoid
- Blanket `sudo()` in create/write/search flows.
- Overly broad record rules.
- Exposing internal fields in controllers or portal endpoints.
- Building security only after business logic is done.
- Raw SQL without parameter safety and access review.
- Using standard `open()` for files in addons.

## Related references
- `references/backend-rules.md`
- `references/frontend-ui-rules.md`
- `references/testing.md`
- `references/maturity-levels.md`
