# Version Matrix — Odoo 16.0 to 19.0

Central reference for breaking changes or expected syntax modifications
between Odoo versions. **Consult this table before generating code.**

---

## Summary Table

| Version | List view tag | Key ORM change | Frontend |
|---------|---------------|----------------|----------|
| 16.0 | `<tree>` | `read_group` improvements | OWL 1/2 transition |
| 17.0 | `<tree>` | Safe `SQL()` wrapper | OWL 2 consolidated |
| 18.0 | `<list>` (**breaking change**) | `_read_group` replaces `read_group` | Hoot replaces QUnit |
| 19.0 | `<list>` | `_search_display_name`, GROUPING SETS | OWL 2 continuity |

---

## Odoo 16.0

### ORM
- Introduction of improvements in `_read_group` and field translation via JSONB
  in some cases.
- `read_group()` is the standard public method for grouping.
- `name_get()` remains the standard method for record representation.
- `cr.execute(query, params)` with a tuple of parameters is the safe way to execute SQL.

```python
# ✅ Correct in 16.0
def name_get(self):
    return [(rec.id, f"[{rec.code}] {rec.name}") for rec in self]

# ✅ Safe SQL in 16.0
self.env.cr.execute(
    "SELECT id, name FROM res_partner WHERE active = %s",
    (True,)
)
```

### Views
- **`<tree>`** is the root tag for list views.
- Attributes `editable`, `create`, `delete`, `default_order` go inside the `<tree>` tag.

```xml
<!-- ✅ Correct in 16.0 -->
<tree string="Partners" editable="bottom" create="true" delete="true">
    <field name="name"/>
    <field name="email"/>
</tree>
```

### Frontend
- OWL 1.x/2.0 in transition. Some legacy jQuery widgets are still present.
- Frontend testing with **QUnit**.
- Legacy components (`Widget`) coexist with OWL components.

---

## Odoo 17.0

### ORM
- **`SQL()` wrapper** for safe query composition and SQL injection prevention.
  It is recommended to migrate `cr.execute` with string concatenation to this wrapper.
- `name_get()` **starts to be deprecated** in favor of the computed field `display_name`.
  It still works but generates warnings in logs.

```python
# ✅ Recommended in 17.0: use SQL() wrapper
from odoo.tools import SQL

query = SQL(
    "SELECT id, name FROM %s WHERE active = %s",
    SQL.identifier(self._table),
    True,
)
self.env.cr.execute(query)

# ⚠️ Deprecated in 17.0 (still functional)
def name_get(self):
    return [(rec.id, f"[{rec.code}] {rec.name}") for rec in self]

# ✅ Preferred in 17.0
display_name = fields.Char(
    compute="_compute_display_name",
)

def _compute_display_name(self):
    for rec in self:
        rec.display_name = f"[{rec.code}] {rec.name}"
```

### Views
- Continues using **`<tree>`** as the root tag for lists.
- No changes in view syntax compared to 16.0.

### Frontend
- **OWL 2 is consolidated** as the main frontend framework.
- Legacy jQuery widgets are drastically reduced.
- Frontend testing with **QUnit** (still).

### Deprecations
| Method/Pattern | Status in 17.0 | Replacement |
|----------------|----------------|-------------|
| `name_get()` | Deprecated (functional) | `_compute_display_name` |
| `cr.execute` with concatenation | Discouraged | `SQL()` wrapper |

---

## Odoo 18.0

### ⚠️ Critical View Change

**The `<tree>` tag is officially renamed to `<list>`** throughout the codebase and UI.
Any third-party module using `<tree>` **must be migrated or it will fail** with errors like:

```text
UncaughtPromiseError
Wrong value for ir.ui.view.type: tree
```

#### Automatic Migration Tool

There is a command:
```bash
odoo-bin upgrade_code --addons-path=<path>
```

which automates the replacement of `<tree>` with `<list>`. **However**, this script
can misplace attributes like `create`, `delete`, `editable`, `default_order`
outside the `<list>` tag, so **the result must always be reviewed manually**.

```xml
<!-- ❌ Fails in 18.0 -->
<tree string="Partners" editable="bottom">
    <field name="name"/>
</tree>

<!-- ✅ Correct in 18.0 -->
<list string="Partners" editable="bottom">
    <field name="name"/>
</list>

<!-- ❌ Common bug after upgrade_code (attributes outside the tag) -->
<list string="Partners">
    <field name="name"/>
</list>
<!-- editable="bottom" is lost -->
```

### ORM
- **`read_group` is deprecated** in favor of:
  - `_read_group` (internal use, returns grouped records directly).
  - `formatted_read_group` (public API, for external consumption).

```python
# ❌ Deprecated in 18.0
results = self.env['sale.order'].read_group(
    domain=[('state', '=', 'sale')],
    fields=['amount_total:sum'],
    groupby=['partner_id'],
)

# ✅ Correct in 18.0
results = self.env['sale.order']._read_group(
    domain=[('state', '=', 'sale')],
    groupby=['partner_id'],
    aggregates=['amount_total:sum'],
)
```

### Frontend
- `html_editor` is split into separate modules.
- Testing migrates from **QUnit to Hoot**.
- Existing JS tests must be rewritten with the Hoot API.

### Deprecations
| Method/Pattern | Status in 18.0 | Replacement |
|----------------|----------------|-------------|
| `<tree>` | **Removed** | `<list>` |
| `read_group()` | Deprecated | `_read_group()` / `formatted_read_group()` |
| `name_get()` | Deprecated | `_compute_display_name` |
| QUnit (JS tests) | Deprecated | Hoot |

---

## Odoo 19.0

### ORM
- **Support for `GROUPING SETS`** for pivot views, allowing multiple grouping levels
  in a single query.
- **Dynamic dates in domains**: it is now possible to use expressions like
  `context_today()` in domains natively.
- **`_search_display_name`** replaces name-based search as the standard implementation
  for all `display_name` fields.

```python
# ✅ New in 19.0: _search_display_name
@api.model
def _search_display_name(self, operator, value):
    """Custom search by display_name."""
    domain = [
        '|',
        ('name', operator, value),
        ('code', operator, value),
    ]
    return domain
```

- **Custom domains with SQL**: new possibility to write and combine
  custom domains to inject arbitrary SQL in a controlled manner.
  **Use with extreme caution** and always document the reason.

### Deprecations
| Method/Pattern | Status in 19.0 | Replacement |
|----------------|----------------|-------------|
| `odoo.osv` | Deprecated | Specific modules |
| `record._cr` | Deprecated | `self.env.cr` |
| `record._context` | Deprecated | `self.env.context` |
| `record._uid` | Deprecated | `self.env.uid` |
| `name_get()` | Removed | `_compute_display_name` |
| `read_group()` | Removed | `_read_group()` |

### Views
- Continues using **`<list>`** (same as 18.0).
- No further changes in view syntax.

### Frontend
- Continuity of **OWL 2**.
- **Hoot** is the standard testing framework.

---

## Quick Migration Guide between Versions

### 16.0 → 17.0
1. Replace `name_get()` with `_compute_display_name`.
2. Adopt `SQL()` wrapper for complex queries.
3. No changes in XML views.

### 17.0 → 18.0
1. **Mandatory change**: replace `<tree>` with `<list>` in all views.
   - Verify that attributes (`editable`, `create`, `delete`, `default_order`)
     remain inside the `<list>` tag.
2. Replace `read_group()` with `_read_group()`.
3. Migrate JS tests from QUnit to Hoot.

### 18.0 → 19.0
1. Replace `record._cr`, `record._context`, `record._uid` with `self.env.*`.
2. Implement `_search_display_name` where necessary.
3. Evaluate the use of `GROUPING SETS` for complex pivot views.

### Major Jumps (e.g., 16.0 → 18.0)
For jumps of 2+ versions, consider using **OpenUpgrade** and apply the
changes of each intermediate version in order. See `references/versioning-migrations.md`.
