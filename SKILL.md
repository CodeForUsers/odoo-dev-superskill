---
name: odoo-dev-superskill
description: >
  Expert guide for creating, reviewing, refactoring, and migrating Odoo modules
  in versions 16.0, 17.0, 18.0, 19.0, and 20.0, strictly following OCA Guidelines
  and Odoo 20 official house rules. Use it when the user mentions: creating an Odoo
  module, inheriting models or views, writing security (ACL/ir.rule), migrating between
  Odoo versions (e.g., 16 to 18, 18 to 20), fixing tree/list view errors, reviewing Odoo
  code for anti-patterns, or developing e-commerce connectors (Amazon, eBay, WooCommerce,
  Mirakl, Temu). Also applies if the user pastes code with models.Model, _inherit,
  fields.Many2one, <tree>, <list>, or a __manifest__.py, without mentioning Odoo explicitly.
license: MIT
version: 1.2.0
compatibility: ["claude-code", "antigravity", "cursor", "windsurf", "codex-cli", "gemini-cli"]
---

# odoo-dev-superskill — Odoo Development Skill (16.0–20.0)

An expert skill enabling AI agents to generate, review, refactor, and migrate
Odoo modules from version 16.0 to 20.x, adhering to OCA Guidelines and Odoo 20
official house rules.

---

## 1. Version Detection (Mandatory First Step)

**Before writing a single line of code, determine the target Odoo version.**

### Detection Strategy

1. **Search for `__manifest__.py`** in the module directory. Extract the
   `MAJOR.MINOR` prefix from the `version` key (e.g., `20.0.1.0.0` → `20.0`).
2. If there is no manifest, check `requirements.txt` looking for `odoo>=18`, `odoo>=20`, or similar.
3. Run `scripts/detect_odoo_version.py` to automate the above steps.
4. **If there are no clues**, explicitly ask the user:
   > "Which Odoo version are you developing for? (16.0 / 17.0 / 18.0 / 19.0 / 20.0)"

The detected version determines:
- The list view tag (`<tree>` in 16/17, `<list>` in 18/19/20).
- Which ORM methods to use and which are deprecated.
- The frontend testing framework (QUnit vs Hoot).
- Domain syntax (`odoo.fields.Domain` vs legacy prefix domains).

Check `references/migrations-and-versions.md` for the full breakdown of differences.

---

## 2. Standard Workflow (6 Steps)

Follow these 6 steps in order for any Odoo development task:

| Step | Action | Tool/Reference |
|------|--------|----------------|
| 1 | **Detect target Odoo version** | `scripts/detect_odoo_version.py`, section 1 |
| 2 | **Generate module structure** | `templates/manifest/`, `templates/readme_structure/` |
| 3 | **Write Python model(s)** | `templates/model_skeleton.py.tpl`, `references/backend-rules.md` |
| 4 | **Write views, security, and data** | `references/frontend-ui-rules.md`, `references/backend-rules.md` |
| 5 | **Auto-verify** with validation scripts | `scripts/validate_manifest.py`, `scripts/check_anti_patterns.py` |
| 6 | **Declare module maturity level** | `references/maturity-levels.md` |

---

## 3. Universal Development Rules (All Versions)

These rules govern Odoo module development. They are classified by urgency level:

### Mandatory (Must Follow)
1. **Never use `cr.commit()`** outside of crons or migration scripts.
2. **Never use bare `except: pass`** — catch specific exceptions and log with `_logger`.
3. **Always define ACLs** (`ir.model.access.csv`) for every new model.
4. **Never execute raw SQL** without parameterization — use `cr.execute(query, params)` or `SQL()` (17+).
5. **Prefix XML IDs** with the technical module name: `<module_name>.view_<model>_form`.
6. **In `<record>` tags, place `id` before `model`** (Odoo 20 house standard).

### Recommended (Best Practices)
7. **Respect the attribute order** in model classes (see `references/backend-rules.md`).
8. **One model per Python file**, except for very small auxiliary models.
9. **Include tests** — minimum one `TransactionCase` per model with basic CRUD operations.
10. **Document with OCA README** — use the structure from `templates/readme_structure/`.
11. **Version correctly** — format `MAJOR.MINOR.PATCH.BUILD` tied to the Odoo version (e.g. `20.0.1.0.0`).
12. **Static literals for translations** — use `self.env._(...)` with kwargs or `%s`, and plain ASCII punctuation.

---

## 4. Key Differences by Version

| Version | List View Tag | Conditional UI | Key ORM Change | Frontend | Runtime |
|---------|---------------|----------------|----------------|----------|---------|
| 16.0 | `<tree>` | `attrs="{...}"` | Improvements in `read_group` | OWL 1/2 transition | Python 3.10+ |
| 17.0 | `<tree>` | `invisible="..."` | Secure `SQL()` wrapper | OWL 2 consolidated | Python 3.10+ |
| 18.0 | `<list>` (**breaking**) | `invisible="..."` | `_read_group` replaces `read_group` | Hoot replaces QUnit | Python 3.10+ |
| 19.0 | `<list>` | `invisible="..."` | `_search_display_name`, GROUPING SETS | OWL 2 continuity | Python 3.11+ |
| 20.0 | `<list>` | `invisible="..."` | `odoo.fields.Domain`, `self.env._`, `SQL()` | OWL 2 (by feature), Hoot | Python 3.11–3.13 |

> **Golden Rule**: Before generating any view, check this table and use
> `<tree>` or `<list>` according to the target version. **Never assume a default.**

For full details on each version, check `references/migrations-and-versions.md`.

### Synergy with Odoo 20 Native Repo Skills
In Odoo 20, official agent skills are distributed directly in the core repository (`skills/odoo-guidelines`, `skills/odoo-review`, `skills/odoo-security`, `skills/odoo-web-guidelines`) following the `agentskills.io` standard. `odoo-dev-superskill` fully incorporates these house rules while expanding them with:
- **OCA Multi-version standards** across versions 16.0 through 20.0.
- **Automated Scaffolding & Migration tooling** (`auto_migrate_full.py`, `scaffold_module.py`).
- **AST quality inspection & autofixers** (`check_anti_patterns.py`, `autofix_xml.py`).
- **E-commerce & marketplace connector architectures** (Amazon, eBay, Mirakl, Temu).

### Target Version Examples (Few-Shot Reasoning)
* **Example 1 (New Module v20.0)**:
  * *Request*: "Create a new Odoo 20.0 module with a list view."
  * *Action*: Generate the list view using the `<list>` tag instead of `<tree>`, place `id` before `model` in `<record>`, and use `20.0.1.0.0` manifest.
* **Example 2 (XML View Migration to v18.0+)**:
  * *Request*: "Migrate this view with `attrs="{'invisible': [('state', '=', 'draft')]}"` and `<tree>` to Odoo 20."
  * *Action*: Refactor `<tree>` to `<list>`, and conditional visibility to `invisible="state == 'draft'"`.
* **Example 3 (Ambiguous version context)**:
  * *Request*: "Generate model logic for this addon." (No manifest exists, no version specified).
  * *Action*: Run `detect_odoo_version.py` first. If the version is still undetermined, ask: *"Which Odoo version are you developing for? (16.0 / 17.0 / 18.0 / 19.0 / 20.0)"*.

---

## 5. Behavior templates

If the task is creating a new addon or scaffolding a module from scratch, read `references/agents/scaffold-behavior.md`.

If the task involves migration between Odoo versions or adaptation of deprecated syntax, read `references/agents/migration-behavior.md`.

If the task affects access rights, record rules, sudo usage, SQL queries, controllers, or security-sensitive logic, read `references/agents/security-behavior.md`.

If the task involves XML views, XPath inheritance, QWeb, OWL components, assets, or frontend behavior, read `references/agents/xml-ui-behavior.md`.

If the task involves APIs, marketplaces, webhooks, import/export flows, or external integrations, read `references/agents/connector-behavior.md`.

If the task is reviewing an existing module for quality, structure, maintainability, or OCA alignment, read `references/agents/review-behavior.md`.

If the task is about tests, coverage, validation flows, or QA strategy, read `references/agents/testing-behavior.md`.

These files are complementary to the global skill behavior. They do not replace the version matrix or general references, and they can be combined if a task touches multiple areas (e.g., a migration with XML view changes).

---

## 6. References Index

Refer to these consolidated guides for technical specifications. **Avoid scanning multiple files; use these curated references directly:**

| Reference | Description |
|-----------|-------------|
| [backend-rules.md](references/backend-rules.md) | Attribute ordering, Python exceptions, raw SQL safety, caching, ACLs, record rules, and controller security |
| [frontend-ui-rules.md](references/frontend-ui-rules.md) | tree vs list views, xpath selection, indentation, XML IDs, OWL 2 development, and POS architecture |
| [migrations-and-versions.md](references/migrations-and-versions.md) | Version compatibility matrix, API changelog (v16-19), and OCA migration/OpenUpgrade guidelines |
| [testing.md](references/testing.md) | Backend TransactionCase and frontend OWL 2 Hoot test patterns |
| [ecommerce-connectors.md](references/ecommerce-connectors.md) | Integration patterns for Amazon, eBay, WooCommerce, Mirakl, and Temu |
| [maturity-levels.md](references/maturity-levels.md) | Addon readiness checklists (Alpha, Beta, Stable, Mature) |
| [error-recipes.json](references/error-recipes.json) | Machine-readable linter remediation recipes |
| [cheatsheet-agent.md](references/cheatsheet-agent.md) | Compact, token-efficient agent quick-reference |

> **Note**: For lists of all available boilerplates and CLI scripts, read [skill-manifest.json](skill-manifest.json) at the repository root.

---

## 7. Advanced Agent Tooling (Optional: Codegraph & Engram)

If `codegraph` or `engram` servers are active in your MCP environment, leverage them to improve speed, precision, and context persistence:

### Codegraph (Code Intelligence)
* **Code Navigation & Search**: Avoid raw grep or manual file reading. Use `codegraph_explore` to inspect how Odoo models are inherited or extended (e.g., searching for `_inherit = "res.partner"`).
* **Call Graph Analysis**: Before refactoring or renaming ORM methods, call `codegraph_callers` or `codegraph_impact` to assess what references will break.
* **Overloaded Definition Search**: For common Odoo methods like `write` or `create`, use `codegraph_node` (with `includeCode`) to view all definitions in a single call instead of browsing multiple files.

### Engram (Persistent Memory)
* **Session Persistence**: Proactively record architectural choices, resolved Odoo framework bugs, or custom guidelines for this repository using `mem_save`.
* **Search History**: Use `mem_search` at the start of a session or when encountering an obscure ORM error to see if it was resolved previously.
* **Session Summaries**: Call `mem_session_summary` before ending your turn to keep a record of completed and pending tasks.

