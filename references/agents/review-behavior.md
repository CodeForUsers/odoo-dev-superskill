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

## Workflow
1. Review structure first.
2. Review security and access model.
3. Review models and business logic.
4. Review XML/UI consistency.
5. Review connectors/integrations if present.
6. Review tests, linting, and maintainability.
7. Present findings by severity: critical, important, optional.
8. Suggest concrete improvements, not vague opinions.

## Rules
- Prioritize correctness and maintainability over style nitpicks.
- Distinguish blockers from polish.
- Tie every recommendation to a specific risk or benefit.
- Be explicit when something is uncertain.
- Prefer actionable review output.

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
- `references/maturity-levels.md`
- `references/security.md`
- `references/sql-performance.md`
- `references/testing.md`
