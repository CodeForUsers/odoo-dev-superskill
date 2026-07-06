# Scaffold Behavior

## Purpose
Define how the agent should behave when creating a new Odoo module or scaffolding a significant new functional area inside an existing addon.

## When to activate
- The user asks to create a new addon from scratch.
- The user asks for module scaffolding.
- The task starts from a functional specification and there is no existing implementation.
- A feature requires creating new models, views, security files, menus, and tests from zero.

## Pre-checks
- Detect the target Odoo version before generating anything.
- Identify whether the module is Community or Enterprise-specific.
- Check whether the module should follow OCA conventions.
- Check whether the module belongs to an existing repository naming scheme.
- Identify whether the feature is standalone or should extend an existing addon.

## Workflow
1. Detect Odoo version and adapt syntax accordingly.
2. Define module scope: models, views, security, data, demo, tests.
3. Generate minimal but complete structure.
4. Create a valid `__manifest__.py` aligned with the target version.
5. Add security files early: `ir.model.access.csv`, optional record rules if needed.
6. Create models before views.
7. Create base menu/actions only if the feature needs UI exposure.
8. Add tests from the beginning, not as an afterthought.
9. Ensure naming consistency across Python classes, XML ids, model names, menu ids and access records.

## Rules
- Never scaffold without detecting the Odoo version first.
- Prefer minimal complete scaffolding over bloated boilerplate.
- Respect OCA-style directory layout when relevant.
- Keep dependencies minimal and explicit.
- Generate code that is production-oriented, not just illustrative.

## Avoid
- Creating placeholder files with no real value.
- Adding unnecessary menus, demo data, or sample records by default.
- Mixing version syntax across Odoo releases.
- Skipping security and tests during initial scaffolding.
- Creating oversized modules when the feature should be an extension of an existing addon.

## Related references
- `references/version-matrix.md`
- `references/maturity-levels.md`
- `references/security.md`
- `references/sql-performance.md`
