# ORM Changelog — Odoo 16.0 to 19.0

Detailed changelog of Odoo ORM changes between versions 16.0 and 19.0.

---

## Summary of Deprecated Methods and Replacements

| Method / Pattern | 16.0 | 17.0 | 18.0 | 19.0 | Replacement |
|------------------|------|------|------|------|-------------|
| `name_get()` | ✅ Standard | ⚠️ Deprecated | ⚠️ Deprecated | ❌ Removed | `_compute_display_name` |
| `read_group()` | ✅ Standard | ✅ Standard | ⚠️ Deprecated | ❌ Removed | `_read_group()` / `formatted_read_group()` |
| `name_search()` | ✅ Standard | ✅ Standard | ✅ Standard | ⚠️ Deprecated | `_search_display_name` |
| `cr.execute` + concat | ❌ Forbidden | ❌ Forbidden | ❌ Forbidden | ❌ Forbidden | `cr.execute(q, params)` or `SQL()` |
| `SQL()` wrapper | ❌ N/A | ✅ New | ✅ Standard | ✅ Standard | — |
| `record._cr` | ✅ Functional | ✅ Functional | ✅ Functional | ⚠️ Deprecated | `self.env.cr` |
| `record._uid` | ✅ Functional | ✅ Functional | ✅ Functional | ⚠️ Deprecated | `self.env.uid` |
| `record._context` | ✅ Functional | ✅ Functional | ✅ Functional | ⚠️ Deprecated | `self.env.context` |
| `odoo.osv` | ✅ Functional | ✅ Functional | ✅ Functional | ⚠️ Deprecated | Specific modules |
| `attrs` in XML | ✅ Functional | ⚠️ Deprecated | ⚠️ Deprecated | ❌ Removed | Direct attributes (`invisible`, `readonly`) |

---

## Odoo 16.0

### Main ORM Changes

#### `_read_group` Improvements
- The internal `_read_group` method receives improvements for field translation and
  grouping with JSONB on certain backends.
- The public method remains `read_group()`.

#### Field Translation with JSONB
- In some scenarios, Odoo 16.0 starts using JSONB columns to
  store field translations instead of the `ir_translation` table.

```python
# 16.0: read_group is the public standard
results = self.env["sale.order"].read_group(
    domain=[("state", "=", "sale")],
    fields=["partner_id", "amount_total:sum"],
    groupby=["partner_id"],
)
for group in results:
    _logger.info(
        "Partner: %s, Total: %s",
        group["partner_id"][1],
        group["amount_total"],
    )
```

#### `api.model_create_multi`
- Available and recommended for overriding `create()` by receiving
  a list of dictionaries.

```python
@api.model_create_multi
def create(self, vals_list):
    for vals in vals_list:
        if not vals.get("name"):
            vals["name"] = self.env["ir.sequence"].next_by_code("my.model")
    return super().create(vals_list)
```

---

## Odoo 17.0

### `SQL()` Wrapper for Safe Composition

The most significant ORM change in 17.0. It allows safe SQL query composition,
preventing injection via string concatenation.

```python
from odoo.tools import SQL

# Safe composition
table = SQL.identifier(self._table)
query = SQL(
    "SELECT id, name FROM %s WHERE active = %s AND company_id = %s",
    table,
    True,
    self.env.company.id,
)
self.env.cr.execute(query)

# Fragment composition
select = SQL("SELECT id, name FROM %s", table)
where = SQL("WHERE state IN %s", tuple(["draft", "confirmed"]))
order = SQL("ORDER BY create_date DESC")
full_query = SQL("%s %s %s", select, where, order)
self.env.cr.execute(full_query)
```

### `name_get()` Deprecation

`name_get()` starts generating warnings in logs. The replacement is the
computed field `display_name`:

```python
# ✅ 17.0+: computed field
display_name = fields.Char(compute="_compute_display_name")

@api.depends("code", "name")
def _compute_display_name(self):
    for rec in self:
        rec.display_name = f"[{rec.code}] {rec.name}"
```

### `with_context` and `with_company` Improvements

```python
# Cleaner way to change context
records = self.with_context(active_test=False).search([])
records_company = self.with_company(company).search([])
```

---

## Odoo 18.0

### `read_group()` Deprecation

The public method `read_group()` is deprecated. The replacements are:

```python
# ❌ Deprecated in 18.0
results = self.env["sale.order"].read_group(
    domain=[("state", "=", "sale")],
    fields=["amount_total:sum"],
    groupby=["partner_id"],
)

# ✅ Internal use: _read_group
# Note: the signature changes — groupby and aggregates are separate arguments
results = self.env["sale.order"]._read_group(
    domain=[("state", "=", "sale")],
    groupby=["partner_id"],
    aggregates=["amount_total:sum"],
)
# Returns a list of tuples: [(partner, sum_amount_total), ...]

# ✅ Public API: formatted_read_group
results = self.env["sale.order"].formatted_read_group(
    domain=[("state", "=", "sale")],
    groupby=["partner_id"],
    aggregates=["amount_total:sum"],
)
```

### `_read_group` Signature Changes

The `_read_group` signature in 18.0 is significantly different from
previous versions:

```python
# 18.0: new signature
Model._read_group(
    domain,                  # list of domains
    groupby=["field1"],      # list of fields to group by
    aggregates=["field2:agg"], # list of "field:aggregation"
    having=[],               # optional HAVING conditions
    offset=0,
    limit=None,
    order=None,
)
# Returns: [(group_value_1, agg_value_1), ...]
```

### Computed Fields Improvements

```python
# 18.0: better support for flush and prefetch in computed fields
# Compute+store fields are recalculated more efficiently
price_total = fields.Float(
    compute="_compute_price_total",
    store=True,
    precompute=True,  # Calculated before INSERT
)
```

---

## Odoo 19.0

### `GROUPING SETS` for Pivot Views

```python
# 19.0: native GROUPING SETS support
# Allows multiple grouping levels in a single query
# Used internally by pivot views for better performance
results = self.env["sale.order"]._read_group(
    domain=[("state", "=", "sale")],
    groupby=["partner_id", "date_order:month"],
    aggregates=["amount_total:sum", "__count"],
)
```

### `_search_display_name`

New method replacing `name_search()` as the standard implementation
for name-based searches:

```python
@api.model
def _search_display_name(self, operator, value):
    """Custom search: by name OR code."""
    return [
        "|",
        ("name", operator, value),
        ("code", operator, value),
    ]
```

### Dynamic Dates in Domains

```python
# 19.0: native date expressions in domains
domain = [
    ("date_order", ">=", "context_today() - relativedelta(months=3)"),
]
```

### Direct Accessor Deprecations

```python
# ❌ Deprecated in 19.0
self._cr.execute(query)
uid = self._uid
ctx = self._context

# ✅ Correct in 19.0
self.env.cr.execute(query)
uid = self.env.uid
ctx = self.env.context
```

### Custom Domains with SQL

```python
# 19.0: controlled SQL injection in domains (use with extreme caution)
# Always document the reason for usage
from odoo.osv.expression import DOMAIN_OPERATORS

# Only for cases where standard domains are insufficient
# Example: full-text search with tsvector
```

> **⚠️ Caution**: This feature is powerful but dangerous. Only use it
> when standard Odoo domains are insufficient, and always thoroughly
> document the reason.

---

## Common Patterns Valid Across All Versions

### Model Inheritance

```python
# Extension inheritance (most common)
class ResPartner(models.Model):
    _inherit = "res.partner"

    custom_field = fields.Char(string="Custom Field")

# Delegation inheritance
class ProductProduct(models.Model):
    _name = "product.product"
    _inherits = {"product.template": "product_tmpl_id"}

# Abstract inheritance
class MailThread(models.AbstractModel):
    _name = "mail.thread"
    _description = "Mail Thread"
```

### API Decorators

```python
# Valid in 16.0–19.0
@api.depends("field1", "field2")          # For computed fields
@api.constrains("field1")                 # Validations
@api.onchange("field1")                   # UI changes
@api.model                                # Class methods
@api.model_create_multi                   # create() override
@api.returns("self", lambda rec: rec.id)  # Return type
```
