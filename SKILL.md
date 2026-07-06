---
name: odoo-dev-superskill
description: >
  Expert guide for creating, reviewing, refactoring, and migrating Odoo modules
  in versions 16.0, 17.0, 18.0, and 19.0, strictly following OCA Guidelines.
  Use it when the user mentions: creating an Odoo module, inheriting models or
  views, writing security (ACL/ir.rule), migrating between Odoo versions
  (e.g., 16 to 18, 17 to 19), fixing tree/list view errors, reviewing Odoo code
  for anti-patterns, or developing e-commerce connectors (Amazon, eBay,
  WooCommerce, Mirakl, Temu) on Odoo. Also applies if the user pastes code with
  models.Model, _inherit, fields.Many2one, <tree>, <list>, or a __manifest__.py,
  without mentioning the word Odoo explicitly.
license: MIT
version: 1.1.0
compatibility: ["claude-code", "antigravity", "cursor", "windsurf", "codex-cli", "gemini-cli"]
---

# odoo-dev-superskill — Odoo Development Skill (16.0–19.0)

A complete skill enabling any AI agent to generate, review, refactor, and migrate
Odoo modules from version 16.0 to 19.x, adhering to OCA Guidelines.

---

## 1. Version Detection (Mandatory First Step)

**Before writing a single line of code, determine the target Odoo version.**

### Detection Strategy

1. **Search for `__manifest__.py`** in the module directory. Extract the
   `MAJOR.MINOR` prefix from the `version` key (e.g., `18.0.1.2.0` → `18.0`).
2. If there is no manifest, check `requirements.txt` looking for `odoo>=18` or similar.
3. Run `scripts/detect_odoo_version.py` to automate the above steps.
4. **If there are no clues**, explicitly ask the user:
   > "Which Odoo version are you developing for? (16.0 / 17.0 / 18.0 / 19.0)"

The detected version determines:
- The list view tag (`<tree>` in 16/17, `<list>` in 18/19).
- Which ORM methods to use and which are deprecated.
- The frontend testing framework (QUnit vs Hoot).

Check `references/version-matrix.md` for the full breakdown of differences.

---

## 2. Standard Workflow (6 Steps)

Follow these 6 steps in order for any Odoo development task:

| Step | Action | Tool/Reference |
|------|--------|----------------|
| 1 | **Detect target Odoo version** | `scripts/detect_odoo_version.py`, section 1 |
| 2 | **Generate module structure** | `templates/manifest/`, `templates/readme_structure/` |
| 3 | **Write Python model(s)** | `templates/model_skeleton.py.tpl`, `references/python-conventions.md` |
| 4 | **Write views, security, and data** | `references/xml-conventions.md`, `references/security.md` |
| 5 | **Auto-verify** with validation scripts | `scripts/validate_manifest.py`, `scripts/check_anti_patterns.py` |
| 6 | **Declare module maturity level** | `references/maturity-levels.md` |

---

## 3. Critical Universal Rules (All Versions)

These rules apply **always**, regardless of the Odoo version:

1. **Never use `cr.commit()`** outside of crons or migration scripts.
2. **Never use bare `except: pass`** — catch specific exceptions and log with `_logger`.
3. **Always define ACLs** (`ir.model.access.csv`) for every new model.
4. **Never execute raw SQL** without parameterization — use `cr.execute(query, params)` or `SQL()` (17+).
5. **Respect the OCA order** of attributes in model classes (see `references/python-conventions.md`).
6. **One model per Python file**, except for very small auxiliary models.
7. **Prefix XML IDs** with the technical module name: `<module_name>.view_<model>_form`.
8. **Include tests** — minimum one `TransactionCase` per model with basic CRUD operations.
9. **Document with OCA README** — use the structure from `templates/readme_structure/`.
10. **Version correctly** — format `MAJOR.MINOR.PATCH.BUILD` tied to the Odoo version.

---

## 4. Key Differences by Version

| Version | List View Tag | Conditional UI | Key ORM Change | Frontend |
|---------|---------------|----------------|----------------|----------|
| 16.0 | `<tree>` | `attrs="{...}"` | Improvements in `read_group` | OWL 1/2 transition |
| 17.0 | `<tree>` | `invisible="..."` | Secure `SQL()` wrapper | OWL 2 consolidated |
| 18.0 | `<list>` (**breaking**) | `invisible="..."` | `_read_group` replaces `read_group` | Hoot replaces QUnit |
| 19.0 | `<list>` | `invisible="..."` | `_search_display_name`, GROUPING SETS | OWL 2 continuity |

> **Golden Rule**: Before generating any view, check this table and use
> `<tree>` or `<list>` according to the target version. **Never assume a default.**

For full details on each version, check `references/version-matrix.md`.

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

| Reference | Description |
|-----------|-------------|
| [version-matrix.md](references/version-matrix.md) | Changes between 16–19, compatibility table |
| [python-conventions.md](references/python-conventions.md) | Attribute ordering, safe SQL, exception handling |
| [xml-conventions.md](references/xml-conventions.md) | tree vs list, xpath, indentation, ID naming |
| [orm-changelog-16-19.md](references/orm-changelog-16-19.md) | Detailed ORM changelog between versions |
| [security.md](references/security.md) | ACLs, ir.rule, HTTP controllers |
| [sql-performance.md](references/sql-performance.md) | Raw SQL usage, ORM bypass, caching strategies |
| [testing.md](references/testing.md) | Backend and frontend tests (QUnit / Hoot) |
| [versioning-migrations.md](references/versioning-migrations.md) | Versioning, migrations, OpenUpgrade |
| [maturity-levels.md](references/maturity-levels.md) | Alpha / Beta / Stable / Mature checklist |
| [ecommerce-connectors.md](references/ecommerce-connectors.md) | Patterns for Amazon, eBay, WooCommerce, Mirakl, Temu |
| [owl-components.md](references/owl-components.md) | OWL 2 component patterns and hooks |
| [pos-architecture.md](references/pos-architecture.md) | POS offline architecture guide |

---

## 7. Available Templates

### Models and Python Logic

| Template | Usage |
|----------|-------|
| `templates/manifest/manifest_{16,17,18,19}.py.tpl` | Manifest adapted to each version |
| `templates/model_skeleton.py.tpl` | Model skeleton with OCA ordering |
| `templates/wizard.py.tpl` | TransientModel with confirm/cancel and defaults |

### Controllers, Web, and REST APIs

| Template | Usage |
|----------|-------|
| `templates/controller.py.tpl` | Basic HTTP controller (JSON API, webhook, public page) |
| `templates/controllers/base_rest_api.py.tpl` | Pure and self-documented REST API with OpenAPI (OCA `base_rest`) |

### XML Views (Backend)

| Template | Usage |
|----------|-------|
| `templates/views/tree_view_16_17.xml.tpl` | List view with `<tree>` (v16/17) |
| `templates/views/list_view_18_19.xml.tpl` | List view with `<list>` (v18/19) |
| `templates/views/advanced_form_view.xml.tpl` | "Mega" Form (Smart buttons, Notebooks, One2many) |
| `templates/views/view_inheritance.xml.tpl` | View inheritance (`xpath`, `position="after/inside"`) |
| `templates/views/kanban_view.xml.tpl` | Kanban view with QWeb, colors, and activities |
| `templates/views/pivot_view.xml.tpl` | Pivot view (rows, columns, measures) |
| `templates/views/graph_view.xml.tpl` | Graph view (bar/line/pie) |
| `templates/views/calendar_view.xml.tpl` | Calendar view (start/stop, color, filters) |
| `templates/views/wizard_form_view.xml.tpl` | Wizard form with button footer |
| `templates/views/cron.xml.tpl` | Scheduled actions (daily/hourly/minutes) |

### Security and Performance

| File | Usage |
|------|-------|
| `references/sql-performance.md` | Guide for raw SQL usage (ORM bypass) and caching |
| `templates/security/multi_company_rules.xml.tpl`| Advanced `ir.rule` rules for multi-company environments |
| `templates/security/ir.model.access.csv.tpl` | ACLs with OCA nomenclature |
| `templates/security/security.xml.tpl` | User/Manager groups + standard rules |

### Initial and Demo Data

| Template | Usage |
|----------|-------|
| `templates/data/data.xml.tpl` | Initial data (params, email templates, server actions) |
| `templates/data/demo_data.xml.tpl` | Demo data with noupdate=1 |

### Reports and Printed Documents

| Template | Usage |
|----------|-------|
| `templates/reports/report_action.xml.tpl` | ir.actions.report record + paper format (PDF) |
| `templates/reports/report_qweb_template.xml.tpl` | HTML/QWeb template with external_layout (PDF) |
| `templates/reports/report_xlsx_action.xml.tpl` | Report action for Excel exports |
| `templates/reports/report_xlsx.py.tpl` | Dynamic Excel generator in Python (OCA `report_xlsx`) |

### Frontend (OWL 2 and SCSS)

| Template | Usage |
|----------|-------|
| `templates/static/src/components/owl_component.js.tpl` | JS class for OWL 2 component (state, hooks, ORM) |
| `templates/static/src/components/owl_component.xml.tpl` | QWeb/XML view for the OWL component |
| `templates/static/src/components/dashboard/dashboard.js.tpl`| Advanced interactive dashboard (Client Action OWL) |
| `templates/static/src/components/dashboard/dashboard.xml.tpl`| Dashboard QWeb (KPIs, tables, and events) |
| `templates/static/src/scss/custom_styles.scss.tpl` | SCSS stylesheet for backend customization |

### Infrastructure, CI/CD, and Docker

| Template | Usage |
|----------|-------|
| `templates/infra/.pre-commit-config.yaml.tpl` | Standard OCA config (Black, Isort, Flake8) |
| `templates/infra/github_actions_test.yml.tpl` | GitHub Actions CI with `maintainer-quality-tools` |
| `templates/infra/docker-compose.yml.tpl` | Local Odoo + PostgreSQL environment |

### Website and Customer Portal

| Template | Usage |
|----------|-------|
| `templates/website/snippet.xml.tpl` | Drag & Drop structure for Website Builder |
| `templates/website/snippet_options.xml.tpl` | Customization options in sidebar |
| `templates/website/portal_view.xml.tpl` | QWeb views for the customer portal (List/Detail) |
| `templates/website/portal_controller.py.tpl` | Secure route controller for the portal |

### Point of Sale (POS)

| Template | Usage |
|----------|-------|
| `references/pos-architecture.md` | POS offline architecture guide |
| `templates/pos/pos_button.js.tpl` | Injection of custom action buttons in OWL |

### Integrations, Emails, and Migrations (OpenUpgrade)

| Template | Usage |
|----------|-------|
| `templates/integrations/queue_job.py.tpl` | Queuing heavy tasks using OCA `queue_job` |
| `templates/models/mail_alias_mixin.py.tpl` | Automatic email reception (parsing to records) |
| `templates/scripts/external_rpc_client.py.tpl` | Standalone script (XML-RPC) to interact externally |
| `templates/migrations/pre-migration.py.tpl` | Pre-migration script (rename tables/columns) |
| `templates/migrations/post-migration.py.tpl` | Post-migration script (recompute data) |

### Backend, Frontend, and UI Testing

| Template | Usage |
|----------|-------|
| `templates/readme_structure/*.rst` | Standard OCA README structure |
| `templates/tests/test_transaction_case.py.tpl` | Backend tests (CRUD, compute, constrains, security) |
| `templates/tests/test_hoot.js.tpl` | Frontend tests with Hoot (v18/19 only) |
| `templates/tests/tour.js.tpl` | E2E UI Test script (Odoo Tours) simulating clicks |
| `templates/tests/test_tour_python.py.tpl` | Python `HttpCase` test to run the Tour |

---

## 8. Automation and Validation Scripts (Grandmaster)

| Script | Function |
|--------|----------|
| `scripts/autofix_xml.py` | **Black Magic!** Auto-converts `attrs`, `states`, and `<tree>` to 17/18+ syntax |
| `scripts/detect_odoo_version.py` | Detects the project's Odoo version |
| `scripts/scaffold_module.py` | **Generates a complete module from scratch** |
| `scripts/create_migration.py` | Creates the structure and scripts for migrating with OpenUpgrade |
| `scripts/extract_translations.py` | Extracts strings to a `.pot` file for translation |
| `scripts/validate_manifest.py` | Validates manifest structure and content |
| `scripts/check_anti_patterns.py` | Detects common anti-patterns in Odoo code |
| `scripts/check_acls.py` | Verifies that all models have an ACL entry |
| `scripts/check_test_coverage.py` | Verifies test existence and basic coverage |
| `scripts/migrate_code_patterns.py` | Migrates code syntax between versions (e.g., `<tree>` to `<list>`, `attrs` to `invisible`) using `odoo-module-migrator` |
| `scripts/port_addon.py` | Ports commits between branches using `oca-port` |
| `scripts/auto_migrate_full.py` | Executes the full pipeline (migrate patterns + port commits) |

Run these scripts after every code generation or modification to ensure quality before delivery.
