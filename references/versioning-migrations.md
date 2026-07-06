# Versioning & Migrations — Odoo OCA Development

Versioning and migration guide for Odoo modules (16.0–19.0).

---

## 1. Version Format

The standard OCA format for a module's version is:

```text
ODOO_MAJOR.ODOO_MINOR.MODULE_MAJOR.MODULE_MINOR.MODULE_PATCH
```

### Examples

| Odoo Version | Module Version | Meaning |
|--------------|----------------|---------|
| `16.0.1.0.0` | First stable version for Odoo 16.0 | |
| `16.0.1.1.0` | Minor: new backward-compatible feature | |
| `16.0.1.1.1` | Patch: bug fix | |
| `17.0.1.0.0` | Migration to Odoo 17.0 (MODULE version reset) | |
| `18.0.1.0.0` | Migration to Odoo 18.0 | |
| `18.0.2.0.0` | Major: breaking change in Odoo 18.0 | |

### In the `__manifest__.py`

```python
{
    "name": "My Module",
    "version": "18.0.1.0.0",  # Always include all 5 segments
    # ...
}
```

### When to Increment Each Segment

| Segment | When to increment |
|---------|-------------------|
| `ODOO_MAJOR.ODOO_MINOR` | When migrating to a new Odoo version |
| `MODULE_MAJOR` | Breaking change (new model, changed API) |
| `MODULE_MINOR` | New backward-compatible feature |
| `MODULE_PATCH` | Bug fixes, minor improvements |

---

## 2. Migration Structure

### Migrations Directory

```text
my_module/
├── __manifest__.py          # version: "18.0.1.2.0"
├── migrations/
│   ├── 18.0.1.1.0/
│   │   ├── pre-migration.py
│   │   └── post-migration.py
│   ├── 18.0.1.2.0/
│   │   └── post-migration.py
│   └── 17.0.1.0.0/          # Migration from 16.0
│       ├── pre-migration.py
│       └── post-migration.py
```

### Types of Migration Scripts

| Script | When it runs | Typical usage |
|--------|--------------|---------------|
| `pre-migration.py` | **Before** updating the module | Rename columns/tables, prepare data |
| `post-migration.py` | **After** updating the module | Migrate data, recompute computed fields |
| `end-migration.py` | At the end of the entire update | Final cleanup (rarely needed) |

### Pre-migration Example

```python
# migrations/18.0.1.1.0/pre-migration.py

import logging

_logger = logging.getLogger(__name__)


def migrate(cr, version):
    """Pre-migration: rename column before Odoo drops it."""
    if not version:
        return

    _logger.info("Pre-migration 18.0.1.1.0: renaming column old_field to new_field")

    cr.execute("""
        ALTER TABLE my_model
        RENAME COLUMN old_field TO new_field
    """)
    # cr.commit() is valid here (migration script)
```

### Post-migration Example

```python
# migrations/18.0.1.1.0/post-migration.py

import logging
from odoo import SUPERUSER_ID, api

_logger = logging.getLogger(__name__)


def migrate(cr, version):
    """Post-migration: recompute fields and migrate data."""
    if not version:
        return

    env = api.Environment(cr, SUPERUSER_ID, {})

    _logger.info("Post-migration 18.0.1.1.0: updating computed fields")

    # Recompute a stored computed field
    records = env["my.model"].search([])
    records._compute_display_name()

    # Migrate data from one field to another
    cr.execute("""
        UPDATE my_model
        SET new_status = CASE
            WHEN old_status = 'open' THEN 'in_progress'
            WHEN old_status = 'closed' THEN 'done'
            ELSE old_status
        END
        WHERE old_status IS NOT NULL
    """)

    _logger.info("Post-migration 18.0.1.1.0: migrated %d records", cr.rowcount)
```

---

## 3. Migration Between Major Odoo Versions

### Step-by-Step Migration (Recommended)

To migrate a module between major versions (e.g., 16.0 → 18.0), apply the
changes for **each intermediate version** in order:

#### 16.0 → 17.0

1. Change version prefix: `16.0.X.Y.Z` → `17.0.1.0.0`.
2. Replace `name_get()` with `_compute_display_name`.
3. Adopt `SQL()` wrapper for complex queries (optional but recommended).
4. No changes in XML views.
5. Create `migrations/17.0.1.0.0/` if there are data changes.

#### 17.0 → 18.0

1. Change version prefix: `17.0.X.Y.Z` → `18.0.1.0.0`.
2. **MANDATORY**: Replace `<tree>` with `<list>` in all views.
3. **MANDATORY**: Replace `tree` with `list` in action `view_mode`.
4. Replace `read_group()` with `_read_group()`.
5. Migrate JS tests from QUnit to Hoot (if applicable).
6. Check xpath inheritances using `//tree` → change to `//list`.

#### 18.0 → 19.0

1. Change version prefix: `18.0.X.Y.Z` → `19.0.1.0.0`.
2. Replace `record._cr`, `record._uid`, `record._context` with `self.env.*`.
3. Implement `_search_display_name` where `name_search()` was overridden.
4. Evaluate using `GROUPING SETS` for pivot views.

### Jumps of 2+ Versions

For large jumps (e.g., 16.0 → 18.0), apply intermediate migrations
in order: first 16→17, then 17→18.

---

## 4. OpenUpgrade

[OpenUpgrade](https://github.com/OCA/OpenUpgrade) is the OCA tool for
automatic database migrations between Odoo versions.

### When to Use OpenUpgrade

| Scenario | Tool |
|----------|------|
| Migrate a custom module | Custom migration scripts (`migrations/`) |
| Migrate an entire Odoo instance | OpenUpgrade |
| Migrate OCA modules | Check if OCA provides migration scripts |

### OpenUpgrade Structure

```text
openupgradelib/
├── openupgrade.py        # Helper functions for migrations
└── ...

# In your migration scripts:
from openupgradelib import openupgrade

def migrate(cr, version):
    openupgrade.rename_fields(
        cr,
        [("my.model", "my_model", "old_field", "new_field")],
    )
    openupgrade.rename_models(
        cr,
        [("old.model.name", "new.model.name")],
    )
```

### Common OpenUpgrade Helper Functions

| Function | Usage |
|----------|-------|
| `rename_fields` | Rename fields (column + ir.model.fields) |
| `rename_models` | Rename models (table + references) |
| `rename_xmlids` | Rename XML IDs |
| `logged_query` | Execute SQL with logging |
| `add_fields` | Add missing columns |
| `map_values` | Map values from one field to another |
| `column_exists` | Check if a column exists |

---

## 5. Migration Checklist

### Before Starting

- [ ] Do you have a database backup?
- [ ] Have you identified all changes from the source to the target version?
  (check `references/version-matrix.md`)
- [ ] Are there dependent modules that also need migration?

### During Migration

- [ ] Updated version prefix in `__manifest__.py`?
- [ ] Created the `migrations/X.0.1.0.0/` directory?
- [ ] Written necessary pre/post-migration scripts?
- [ ] Replaced `<tree>` with `<list>` (if migrating to 18.0+)?
- [ ] Replaced deprecated methods with their equivalents?
- [ ] Updated dependencies in the manifest?

### After Migration

- [ ] Do tests pass on the new version?
- [ ] Does the UI work correctly (views, menus, actions)?
- [ ] Was data migrated correctly?
- [ ] Are reports generated without errors?
- [ ] Do crons work correctly?
