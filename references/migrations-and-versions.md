# Odoo Version Changes, Changelog & Migrations Guide (v16.0 - v20.0)

This guide consolidates all ORM version differences, compatibility matrices, versioning conventions, and migration protocols.

---

## 1. Version Comparison Matrix

| Version | List view tag | Key ORM change | Frontend | Standard JS Testing | Runtime |
|---------|---------------|----------------|----------|---------------------|---------|
| **16.0** | `<tree>` | `read_group` improvements | OWL 1/2 transition | QUnit | Python 3.10+ |
| **17.0** | `<tree>` | Safe `SQL()` wrapper | OWL 2 consolidated | QUnit | Python 3.10+ |
| **18.0** | `<list>` (**breaking**) | `_read_group` replaces `read_group` | OWL 2 | Hoot | Python 3.10+ |
| **19.0** | `<list>` | `_search_display_name`, GROUPING SETS | OWL 2 | Hoot | Python 3.11+ |
| **20.0** | `<list>` | `odoo.fields.Domain`, `self.env._`, `SQL()` | OWL 2 (by feature) | Hoot | Python 3.11–3.13 |

---

## 2. API Changelog & Equivalences

### Display Name Representation
* **Odoo 16.0**: Use `name_get()` method.
* **Odoo 17.0 / 18.0**: `name_get()` is deprecated. Use a computed `display_name` field instead.
* **Odoo 19.0 / 20.0**: `name_get()` is **removed**. You must use `_compute_display_name()`.

```python
# Odoo 16.0
def name_get(self):
    return [(rec.id, f"[{rec.code}] {rec.name}") for rec in self]

# Odoo 17.0+
display_name = fields.Char(compute="_compute_display_name")
@api.depends("code", "name")
def _compute_display_name(self):
    for rec in self:
        rec.display_name = f"[{rec.code}] {rec.name}"
```

### Searching display_name
* **Odoo 16.0 - 18.0**: Override `name_search()` method.
* **Odoo 19.0 / 20.0**: `name_search()` is deprecated. Override `_search_display_name()` instead.

```python
# Odoo 19.0+
@api.model
def _search_display_name(self, operator, value):
    return ['|', ('name', operator, value), ('code', operator, value)]
```

### Record Grouping
* **Odoo 16.0 / 17.0**: Use `read_group()` public method.
* **Odoo 18.0 - 20.0**: `read_group()` is removed/deprecated.
  * Internal: Use `_read_group()`. Note the signature separation: `groupby` and `aggregates` are now separate list arguments.
  * External/Public APIs: Use `formatted_read_group()`.

```python
# Odoo 18.0+
results = self.env["sale.order"]._read_group(
    domain=[("state", "=", "sale")],
    groupby=["partner_id"],
    aggregates=["amount_total:sum"],
)
# Returns a list of tuples: [(partner, sum_amount_total), ...]
```

### Domain Construction (Odoo 20.0 Strict Standard)
* **Odoo 16.0 - 19.0**: Polish notation prefixes `['&', ...]` or deprecated `expression.AND()`.
* **Odoo 20.0**: Combine domains using `odoo.fields.Domain`:
  * Use Python operators `&`, `|`, `~` for inline domains.
  * Use `Domain.AND([d1, d2])` / `Domain.OR([d1, d2])` for lists of domains.
  * `expression.AND` and `expression.OR` are deprecated.

```python
# Odoo 20.0+
from odoo.fields import Domain

# Inline combination
domain = Domain([("state", "=", "draft")]) & Domain([("partner_id", "=", partner.id)])

# List combination
active_domains = [Domain([("active", "=", True)]), Domain([("company_id", "=", self.env.company.id)])]
combined = Domain.AND(active_domains)
```

### Translations (Odoo 20.0 Strict Standard)
* In Odoo 20.0, translate only **static literals** via `self.env._(...)`.
* Pass dynamic parameters as keyword arguments or `%s`.
* Never use `%` or f-strings inside `_()` or after lookup.

```python
# ✅ Correct (Odoo 20.0)
raise UserError(self.env._("Record %s cannot be modified", record.display_name))
msg = self.env._("%(count)s records imported by %(user)s", count=len(records), user=user.name)

# ❌ Forbidden
raise UserError(self.env._("Record %s cannot be modified" % record.display_name))
raise UserError(self.env._(f"Record {record.display_name} cannot be modified"))
```

### Plain ASCII Punctuation (Odoo 20.0 Standard)
* Comments, docstrings, commit messages, and user-facing strings must use **plain ASCII punctuation only**.
* Replace em dashes (`—`) and en dashes (`–`) with `-`, commas, or colons.
* Replace curly quotes (`“ ” ‘ ’`) with standard quotes (`" '`).
* Replace ellipsis characters (`…`) with `...`.

### Python Transaction Direct Accessors
* **Odoo 19.0 / 20.0**: Direct attributes like `self._cr`, `self._uid`, and `self._context` are deprecated. Use environment counterparts instead:
  * `self._cr` ➡️ `self.env.cr`
  * `self._uid` ➡️ `self.env.uid`
  * `self._context` ➡️ `self.env.context`

### File Access
* **Odoo 20.0**: Do not use standard `open()` for addon files; always use `odoo.tools.file_open` to prevent traversal and respect addon resolution.

---

## 3. Versioning Standards (OCA)

### Version Format
All modules must define their version in `__manifest__.py` using all 5 segments:
```text
ODOO_MAJOR.ODOO_MINOR.MODULE_MAJOR.MODULE_MINOR.MODULE_PATCH
```
* Example: `20.0.1.0.0`
* Increment rules:
  * `ODOO_MAJOR.ODOO_MINOR`: Incremented when migrating to a new Odoo version. (Reset the module version to `1.0.0`).
  * `MODULE_MAJOR`: Incremented on backward-incompatible features or major model restructurings.
  * `MODULE_MINOR`: Incremented on backward-compatible feature additions.
  * `MODULE_PATCH`: Incremented on bug fixes or minor patches.

---

## 4. Migration Script Protocols

### Directory structure
Put migration files under `migrations/` inside the module:
```text
my_module/
├── migrations/
│   └── 20.0.1.0.0/
│       ├── pre-migration.py
│       └── post-migration.py
```
* **pre-migration.py**: Runs **before** the module code updates. Ideal for renaming SQL columns or tables.
* **post-migration.py**: Runs **after** the module code updates. Ideal for data mapping or recomputing stored fields.

### Pre-migration pattern
```python
# pre-migration.py
def migrate(cr, version):
    if not version:
        return
    cr.execute("ALTER TABLE my_model RENAME COLUMN old_field TO new_field")
```

### Post-migration pattern
```python
# post-migration.py
from odoo import SUPERUSER_ID, api
def migrate(cr, version):
    if not version:
        return
    env = api.Environment(cr, SUPERUSER_ID, {})
    # Trigger computed field updates or data mapping
    records = env["my.model"].search([])
    records._compute_display_name()
```

### OpenUpgrade Integrations
When writing complex migrations, import `openupgradelib`:
```python
from openupgradelib import openupgrade
def migrate(cr, version):
    openupgrade.rename_fields(cr, [("my.model", "my_model", "old_field", "new_field")])
```
* Key helpers: `rename_fields`, `rename_models`, `rename_xmlids`, `logged_query`.

---

## 5. Migration Checklist (Up to Odoo 20.0)
- [ ] Database backup has been created before running migrations.
- [ ] Odoo major version prefix matches target version in `__manifest__.py` (e.g. `20.0.1.0.0`).
- [ ] Direct references to `<tree>` tags are renamed to `<list>` (when upgrading to 18.0+).
- [ ] View `<record>` tags have attribute `id` placed before `model`.
- [ ] Deprecated methods like `name_get()` or `read_group()` are replaced with `_compute_display_name()` and `_read_group()`.
- [ ] Legacy domain operations (`expression.AND`/`OR`) are converted to `odoo.fields.Domain`.
- [ ] Dynamic strings in `_()` are replaced with `self.env._("...", count=...)`.
- [ ] Direct references to `self._cr`, `self._uid`, `self._context` are updated to `self.env.cr`, `self.env.uid`, `self.env.context`.
- [ ] Migration scripts (pre/post) are configured under the target folder in `migrations/`.
