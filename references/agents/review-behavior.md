# Review Behavior

## Purpose
Define how the agent should behave when reviewing an existing Odoo module for quality, maintainability, structure, OCA alignment, and production readiness.

## When to activate
- The user asks for code review.
- The user asks for improvement suggestions.
- The task is to assess quality before publication or migration.
- The task is to audit an addon for structure or maintainability.

## Pre-checks
- Identify target version and module scope.
- Inspect manifest, dependencies, models, views, security, tests, and data files.
- Determine whether the review should focus on bugs, architecture, style, or OCA compliance.
- Check if the module has tests and documentation.

## Workflow (2-Pass Review Model)
1. **Pass 1 — House Rules & Baseline Compliance**:
   - Manifest & structure (`__manifest__.py`, dependencies, license, clean file layout).
   - Security floor: verify every model in `ir.model.access.csv`, multi-company `ir.rule`, sweep for unnecessary `sudo()` or raw SQL formatting.
   - Backend rules: attribute ordering, `self.env._(...)` translations with kwargs, plain ASCII punctuation, `odoo.fields.Domain`.
   - Frontend/UI rules: `<list>` tags (18.0 - 20.0), `id` before `model` in `<record>`, no fragile positional XPaths.
   - Web framework: feature-based organization, no component getters, no fragile JS patching.
2. **Pass 2 — Merit & Architectural Judgement (Sceptical Colleague Pass)**:
   - Does this change solve the business problem cleanly without side effects?
   - Is performance scalable (batch operations vs O(N) loop ORM queries)?
   - Are edge cases handled (empty recordsets, concurrency, multi-company)?
   - Do tests assert behavior rather than implementation details?
3. **Report findings by severity**: Blocker (Must Fix), Warning (Should Improve), Optimization/Polish (Optional).

## Rules
- Prioritize correctness, security, and maintainability over style nitpicks.
- Distinguish blockers from polish.
- Tie every recommendation to a specific risk or benefit.
- Be explicit when something is uncertain.
- Prefer actionable review output with concrete diffs.

## Avoid
- Generic praise with no technical value.
- Treating all issues as equally important.
- Reviewing style while ignoring security or maintainability.
- Recommending large refactors without justification.
- Assuming OCA compliance without checking module structure.

## Tooling integration (Optional)
- **Codegraph**: Use `codegraph_explore` to quickly map the models defined in the module and their inheritance hierarchy. Use `codegraph_callers` to verify if modified methods are invoked elsewhere in the codebase, preventing broken references.
- **Engram**: Retrieve past review findings or conventions using `mem_search` before starting the audit. Record any significant new architectural decisions or custom coding constraints identified during review using `mem_save`.

## Related references
- `references/backend-rules.md`
- `references/frontend-ui-rules.md`
- `references/migrations-and-versions.md`
- `references/testing.md`
- `references/maturity-levels.md`
