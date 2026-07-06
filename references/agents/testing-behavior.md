# Testing Behavior

## Purpose
Define how the agent should behave when a task involves tests, validation strategy, coverage, and quality assurance for Odoo modules.

## When to activate
- The user asks for tests.
- The task touches business-critical logic.
- The module is being prepared for publication, migration, or review.
- A change affects permissions, imports, sync flows, computed fields, or UI logic.

## Pre-checks
- Identify whether tests already exist.
- Identify critical flows that require regression protection.
- Determine whether the task needs unit, transactional, integration, or UI-adjacent validation.
- Check whether test data/setup already exists.

## Workflow
1. Identify the risk introduced by the change.
2. Decide what must be tested first.
3. Prefer meaningful tests over superficial coverage inflation.
4. Cover security-sensitive and business-critical flows first.
5. Add regression tests for every fixed bug when possible.
6. Keep tests maintainable and tied to actual behavior.
7. Avoid overly brittle tests tied to unstable UI details unless necessary.

## Rules
- Tests are part of the feature, not a final optional phase.
- Cover business rules before edge formatting details.
- Prioritize regression protection.
- Tests should explain expected behavior.
- Coverage percentage is useful, but not a substitute for relevance.

## Avoid
- Dummy tests that assert nothing meaningful.
- Chasing coverage numbers with trivial assertions.
- Ignoring tests on permissions, imports, migrations, and connectors.
- Huge monolithic tests that validate too many concerns at once.
- UI-fragile tests when backend assertions are enough.

## Related references
- `references/testing.md`
- `references/maturity-levels.md`
- `references/version-matrix.md`
