# XML and UI Behavior

## Purpose
Define how the agent should behave when working with XML views, XPath inheritance, QWeb, OWL, assets, and Odoo UI-related behavior.

## When to activate
- The task modifies XML views.
- The task includes form, list, kanban, search, or calendar views.
- The task uses XPath inheritance.
- The task affects QWeb templates, OWL components, or frontend assets.
- The task touches deprecated UI syntax across versions.

## Pre-checks
- Detect Odoo version first.
- Identify whether the change is backend view XML, website QWeb, or OWL/webclient code.
- Check inheritance chains and whether the target element is stable.
- Inspect whether the task modifies list/tree view syntax depending on version.
- Check asset bundle placement and dependency expectations.

## Workflow
1. Detect version-specific UI syntax requirements.
2. Inspect the base inherited view/template before writing XPath.
3. Prefer precise and stable XPath targets.
4. Keep view changes minimal and localized.
5. Separate backend XML, QWeb, and OWL logic conceptually.
6. Review whether field visibility rules should live in XML or Python.
7. Validate assets and dependencies when frontend code is involved.
8. Re-check inheritance robustness after modifications.

## Rules
- Never modify XML blindly without understanding inheritance context.
- Use version-correct syntax for list views: `<tree>` in 16/17, `<list>` in 18/19/20.
- In `<record>` tags, always place `id` before `model`.
- Prefer stable XPath anchors based on field names (`field[@name='...']`) over fragile positional selectors (`//group[2]/field[3]`).
- For web assets, organize by feature (folder with JS component, QWeb XML, and SCSS) rather than splitting by type.
- Keep UI logic readable and maintainable.
- Distinguish between presentation logic and business logic.

## Avoid
- Fragile XPath expressions tied to positions only.
- Duplicating large inherited views when small XPath patches are enough.
- Mixing QWeb, backend view XML, and OWL concerns without separation.
- Carrying deprecated syntax (`attrs`, `<tree>`) into newer versions (18.0 - 20.0).
- Solving backend problems only in the view layer.

## Related references
- `references/frontend-ui-rules.md`
- `references/migrations-and-versions.md`
- `references/backend-rules.md`
- `references/testing.md`
