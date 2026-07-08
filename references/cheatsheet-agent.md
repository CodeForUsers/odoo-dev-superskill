# Odoo Agent Cheatsheet

Quick reference for Odoo module development (v16.0 - v19.0). Strictly adhere to these rules.

## 1. Golden Rules (Mandatory)
* **No `cr.commit()`**: Never call commit outside migrations/crons.
* **Define ACLs**: Every model must have a line in `security/ir.model.access.csv`.
* **No SQL Injection**: Parameterize raw SQL: `cr.execute(query, params)`. Use `SQL()` class in 17.0+.
* **XML IDs**: Prefix all XML IDs with the technical module name (e.g. `<record id="module_name.view_id" ...>`).
* **Clean Errors**: Never use bare `except: pass`. Catch specific errors and log using `_logger`.

## 2. Version Syntax Matrix
| Version | List View | Conditional UI | Grouping ORM | Test Framework |
|---|---|---|---|---|
| **16.0** | `<tree>` | `attrs="{'invisible': [('state', '=', 'draft')]}"` | `read_group()` | QUnit |
| **17.0** | `<tree>` | `invisible="state == 'draft'"` | `read_group()` | QUnit / OWL 2 |
| **18.0** | `<list>` | `invisible="state == 'draft'"` | `_read_group()` | Hoot |
| **19.0** | `<list>` | `invisible="state == 'draft'"` | `_read_group()` | Hoot |

## 3. Mandatory Workflow
1. Detect version via `scripts/detect_odoo_version.py`.
2. Scaffold scaffolding via `scripts/scaffold_module.py`.
3. Develop logic (models, views, security, tests).
4. Run validation:
   * `python3 scripts/check_anti_patterns.py --json`
   * `python3 scripts/check_acls.py --json`
   * `python3 scripts/check_test_coverage.py --json`
   * `python3 scripts/validate_manifest.py --json`
5. Apply auto-fixes: `python3 scripts/autofix_linter.py`.

## 4. MCP Integrations (If Available)
* **Codegraph**: Use `codegraph_explore` to trace model inheritance (`_inherit`) and field extensions.
* **Engram**: Use `mem_save` to record complex Odoo bug resolutions and `mem_search` to find past conventions.
