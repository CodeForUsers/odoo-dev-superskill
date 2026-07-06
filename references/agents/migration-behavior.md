# Migration Behavior

## Purpose
Define how the agent should behave when migrating an Odoo module between versions, especially across 16.0, 17.0, 18.0 and 19.0.

## When to activate
- The user mentions migration.
- The task involves deprecated syntax.
- The task includes adapting legacy views, ORM APIs, assets, or manifest behavior.
- A module created for an older version must run on a newer Odoo release.

## Pre-checks
- Identify source version and target version.
- Inspect manifest version.
- Locate deprecated XML syntax (`attrs`, `states`, `<tree>` where relevant, old assets patterns, etc.).
- Check whether OWL, web assets, JS patches, or controllers are involved.
- Determine whether tests exist and whether they need version-specific adaptation.

## Workflow
1. Detect current version and target version.
2. Build a migration checklist specific to that jump.
3. Inspect XML views first, then Python ORM/API changes, then assets/frontend code.
4. Replace deprecated patterns using the version matrix.
5. Keep changes minimal and traceable.
6. Re-run consistency checks after each migration block.
7. Update tests and manifests to reflect the new version.
8. Flag unclear cases instead of hallucinating a migration rule.

## Rules
- Never assume migration rules without version evidence.
- Prefer explicit before/after transformations.
- Keep backward compatibility only if explicitly requested.
- Treat view migrations and ORM migrations as separate passes.
- Preserve business logic unless migration requires changes.

## Avoid
- Mixing source and target syntax.
- Rewriting working logic unnecessarily.
- Applying mass changes without checking side effects.
- Ignoring XML inheritance breakage after syntax migration.
- Updating version numbers without adapting code.

## Related references
- `references/version-matrix.md`
- `references/orm-changelog-16-19.md`
- `references/testing.md`
