# Python Conventions — Odoo OCA Development

Python code conventions for Odoo modules (16.0–19.0) strictly following OCA Guidelines.

---

## 1. Attribute Ordering in Model Classes

Strictly respect this order within any class inheriting from `models.Model`,
`models.TransientModel`, or `models.AbstractModel`:

```python
from odoo import api, fields, models, _
from odoo.exceptions import UserError, ValidationError

import logging

_logger = logging.getLogger(__name__)


class SaleOrderLine(models.Model):
    # --- 1. Private attributes ---
    _name = "sale.order.line"
    _description = "Sale Order Line"
    _inherit = ["mail.thread", "mail.activity.mixin"]
    _order = "sequence, id"
    _rec_name = "display_name"

    # --- 2. Fields (in order: default, related, compute, store) ---
    name = fields.Char(string="Description", required=True)
    sequence = fields.Integer(default=10)
    order_id = fields.Many2one("sale.order", required=True, ondelete="cascade")
    product_id = fields.Many2one("product.product", string="Product")
    quantity = fields.Float(string="Quantity", default=1.0)
    price_unit = fields.Float(string="Unit Price")
    price_subtotal = fields.Float(
        string="Subtotal",
        compute="_compute_price_subtotal",
        store=True,
    )
    state = fields.Selection(
        related="order_id.state",
        string="Order Status",
        store=True,
    )

    # --- 3. SQL Constraints ---
    _sql_constraints = [
        (
            "positive_quantity",
            "CHECK(quantity > 0)",
            "Quantity must be strictly positive.",
        ),
    ]

    # --- 4. Default methods ---
    def _default_company_id(self):
        return self.env.company

    # --- 5. Compute methods ---
    @api.depends("quantity", "price_unit")
    def _compute_price_subtotal(self):
        for line in self:
            line.price_subtotal = line.quantity * line.price_unit

    # --- 6. Onchange methods ---
    @api.onchange("product_id")
    def _onchange_product_id(self):
        if self.product_id:
            self.name = self.product_id.display_name
            self.price_unit = self.product_id.list_price

    # --- 7. Constrains methods ---
    @api.constrains("quantity")
    def _check_quantity(self):
        for line in self:
            if line.quantity <= 0:
                raise ValidationError(
                    _("Quantity must be positive for line '%s'.") % line.name
                )

    # --- 8. CRUD methods ---
    @api.model_create_multi
    def create(self, vals_list):
        for vals in vals_list:
            if not vals.get("name"):
                vals["name"] = _("New Line")
        return super().create(vals_list)

    def write(self, vals):
        res = super().write(vals)
        if "quantity" in vals:
            _logger.info(
                "Quantity updated for lines: %s", self.ids
            )
        return res

    def unlink(self):
        for line in self:
            if line.state == "done":
                raise UserError(
                    _("Cannot delete a confirmed line.")
                )
        return super().unlink()

    # --- 9. Action methods (buttons) ---
    def action_confirm(self):
        self.ensure_one()
        # confirmation logic
        return True

    # --- 10. Private / Business methods ---
    def _prepare_invoice_line(self):
        self.ensure_one()
        return {
            "product_id": self.product_id.id,
            "quantity": self.quantity,
            "price_unit": self.price_unit,
        }
```

---

## 2. Safe SQL by Version

### Odoo 16.0: `cr.execute` with parameters

```python
# ✅ Correct: parameters as tuple
self.env.cr.execute(
    "SELECT id FROM res_partner WHERE name ILIKE %s AND active = %s",
    (f"%{search_term}%", True),
)
results = self.env.cr.fetchall()

# ❌ FORBIDDEN: string concatenation (SQL injection)
self.env.cr.execute(
    "SELECT id FROM res_partner WHERE name = '" + name + "'"
)
```

### Odoo 17.0+: `SQL()` wrapper

```python
from odoo.tools import SQL

# ✅ Correct in 17.0+: use SQL() wrapper
query = SQL(
    "SELECT id, name FROM %s WHERE active = %s AND name ILIKE %s",
    SQL.identifier(self._table),
    True,
    SQL("%%%(pattern)s%%", pattern=search_term),
)
self.env.cr.execute(query)

# ✅ Safe query composition
base_query = SQL("SELECT id FROM %s", SQL.identifier("res_partner"))
where_clause = SQL("WHERE active = %s", True)
full_query = SQL("%s %s", base_query, where_clause)
self.env.cr.execute(full_query)
```

> **Note**: in 17.0+ you can still use `cr.execute(query, params)` with a tuple,
> but `SQL()` is the recommended way for complex queries with composition.

---

## 3. Prohibition of `cr.commit()`

**Never use `cr.commit()`** in normal business code. The framework manages
transactions automatically.

```python
# ❌ FORBIDDEN in business code
def action_process(self):
    self.state = "done"
    self.env.cr.commit()  # NEVER!

# ✅ Correct: let the framework manage the transaction
def action_process(self):
    self.state = "done"
    # commit occurs automatically at the end of the request
```

**Permitted exceptions** (unique):
- **Migration** scripts (`migrations/X.0.Y.Z.W/pre-migration.py`).
- **Cron** methods that process large volumes and need partial commits
  to avoid long locks (always document the reason).

```python
# ✅ Acceptable ONLY in a cron with documentation
def _cron_process_large_batch(self):
    """Processes large batches with partial commits to avoid locks."""
    batch_size = 100
    records = self.search([("state", "=", "pending")])
    for i in range(0, len(records), batch_size):
        batch = records[i:i + batch_size]
        batch.write({"state": "done"})
        self.env.cr.commit()  # Documented partial commit
        _logger.info("Processed batch %d/%d", i // batch_size + 1,
                      len(records) // batch_size + 1)
```

---

## 4. Replacement of Deprecated Methods by Version

### `name_get()` — deprecated since 17.0, removed in 19.0

```python
# --- Odoo 16.0: name_get() is the standard ---
# ✅ Correct in 16.0
def name_get(self):
    return [(rec.id, f"[{rec.code}] {rec.name}") for rec in self]

# --- Odoo 17.0+: use _compute_display_name ---
# ✅ Correct in 17.0, 18.0, 19.0
display_name = fields.Char(compute="_compute_display_name")

@api.depends("code", "name")
def _compute_display_name(self):
    for rec in self:
        rec.display_name = f"[{rec.code}] {rec.name}"
```

### `read_group()` — deprecated in 18.0, removed in 19.0

```python
# --- Odoo 16.0/17.0: read_group() is the standard ---
# ✅ Correct in 16.0/17.0
results = self.env["sale.order"].read_group(
    domain=[("state", "=", "sale")],
    fields=["amount_total:sum"],
    groupby=["partner_id"],
)

# --- Odoo 18.0+: use _read_group() ---
# ✅ Correct in 18.0/19.0
results = self.env["sale.order"]._read_group(
    domain=[("state", "=", "sale")],
    groupby=["partner_id"],
    aggregates=["amount_total:sum"],
)
```

### `_search_display_name` — new in 19.0

```python
# --- Odoo 19.0: replaces name_search ---
# ✅ Correct in 19.0
@api.model
def _search_display_name(self, operator, value):
    return [
        "|",
        ("name", operator, value),
        ("code", operator, value),
    ]
```

---

## 5. Exception Handling and Logging

```python
import logging

from odoo import _
from odoo.exceptions import UserError, ValidationError

_logger = logging.getLogger(__name__)

# ❌ FORBIDDEN: generic except without action
try:
    result = self._process_data()
except:
    pass

# ❌ FORBIDDEN: except Exception without logging
try:
    result = self._process_data()
except Exception:
    pass

# ✅ Correct: specific catch with logging
try:
    result = self._process_data()
except ValidationError:
    raise  # re-raise validation errors
except Exception as e:
    _logger.exception("Error processing data for record %s: %s", self.id, e)
    raise UserError(
        _("An error occurred while processing. Please contact support.")
    ) from e

# ✅ Correct: informative logging
_logger.info("Processing %d records in batch", len(self))
_logger.debug("Record %s values: %s", self.id, vals)
_logger.warning("Deprecated method called for model %s", self._name)
```

---

## 6. Imports and File Structure

### Import Ordering (PEP 8 + OCA)

```python
# 1. Standard library imports
import logging
from datetime import datetime, timedelta

# 2. Third-party imports
import requests

# 3. Odoo imports
from odoo import _, api, fields, models
from odoo.exceptions import UserError, ValidationError
from odoo.tools import float_compare, float_is_zero

# 4. Logger (always after imports)
_logger = logging.getLogger(__name__)
```

### One Model Per File

```text
models/
├── __init__.py
├── sale_order.py          # class SaleOrder
├── sale_order_line.py     # class SaleOrderLine
└── res_partner.py         # class ResPartner (inheritance)
```

```python
# models/__init__.py
from . import sale_order
from . import sale_order_line
from . import res_partner
```

---

## 7. Using `self.ensure_one()`

```python
# ✅ Correct: use ensure_one() when the method operates on a single record
def action_confirm(self):
    self.ensure_one()
    if self.state != "draft":
        raise UserError(_("Only draft orders can be confirmed."))
    self.state = "confirmed"

# ✅ Correct: iterate when the method can receive multiple records
def action_cancel(self):
    for record in self:
        if record.state == "confirmed":
            record.state = "cancelled"
```
