# Connector Behavior

## Purpose
Define how the agent should behave when implementing or modifying integrations with external APIs, marketplaces, webhooks, import/export pipelines, and synchronization logic.

## When to activate
- The task involves external APIs.
- The task mentions marketplaces, e-commerce, logistics, payments, or webhooks.
- The module synchronizes products, stock, orders, prices, invoices, or customers.
- The task includes scheduled jobs, retries, queueing, or idempotency concerns.

## Pre-checks
- Identify integration direction: import, export, bidirectional sync, webhook.
- Identify external system constraints: rate limits, auth, payload formats, retries.
- Identify Odoo model boundaries and ownership of truth.
- Check whether the connector should extend an existing backend architecture.
- Inspect whether logs, mapping tables, and sync state need dedicated models.

## Workflow
1. Model the integration flow clearly before coding.
2. Separate transport layer, mapping logic, and business logic.
3. Define idempotent operations where possible.
4. Add structured logging and error handling.
5. Treat retries and transient failures explicitly.
6. Avoid coupling external payload formats directly to business models.
7. Use queues/cron patterns when synchronization volume requires it.
8. Plan tests for payload mapping and critical flows.

## Rules
- Integration logic must be traceable and debuggable.
- Mapping should be explicit, not implicit.
- Idempotency matters for imports, exports, and webhooks.
- External failures must not corrupt internal state.
- Connector code should remain modular and extensible.

## Avoid
- Mixing API calls directly inside business methods with no abstraction.
- Silent failures and swallowed exceptions.
- Tight coupling between raw external payloads and core models.
- No logging on sync jobs.
- Assuming remote systems are always consistent or available.

## Related references
- `references/security.md`
- `references/sql-performance.md`
- `references/testing.md`
- `references/maturity-levels.md`
