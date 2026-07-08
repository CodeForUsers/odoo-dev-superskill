# Backend Development Rules & Guidelines (Odoo v16.0 - v19.0)

This guide consolidates all Python conventions, database performance patterns, and security guidelines for Odoo module development.

---

## 1. Python & Model Conventions

### Attribute Ordering in Model Classes
Strictly respect this order within any class inheriting from `models.Model`, `models.TransientModel`, or `models.AbstractModel`:

```python
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
    price_subtotal = fields.Float(string="Subtotal", compute="_compute_price_subtotal", store=True)
    state = fields.Selection(related="order_id.state", string="Order Status", store=True)

    # --- 3. SQL Constraints ---
    _sql_constraints = [
        ("positive_quantity", "CHECK(quantity > 0)", "Quantity must be positive."),
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
                raise ValidationError(_("Quantity must be positive."))

    # --- 8. CRUD methods ---
    @api.model_create_multi
    def create(self, vals_list):
        return super().create(vals_list)

    def write(self, vals):
        return super().write(vals)

    def unlink(self):
        return super().unlink()

    # --- 9. Action methods (buttons) ---
    def action_confirm(self):
        self.ensure_one()
        return True

    # --- 10. Private / Business methods ---
    def _prepare_invoice_line(self):
        self.ensure_one()
        return {}
```

### Exception Handling & Logging
* **Never** use bare `except: pass` or `except Exception: pass`. Catch specific exceptions and log properly.
* **Always** use `_` for user-facing exceptions (e.g. `UserError`, `ValidationError`).

```python
import logging
_logger = logging.getLogger(__name__)

# ✅ Correct Exception Handling
try:
    result = self._process_data()
except ValidationError:
    raise  # Re-raise validation errors
except Exception as e:
    _logger.exception("Error processing record %s", self.id)
    raise UserError(_("An error occurred. Please contact support.")) from e
```

### Import Ordering (PEP 8 + OCA)
1. Standard library imports (e.g. `import logging`, `from datetime import datetime`).
2. Third-party library imports (e.g. `import requests`).
3. Odoo core imports (e.g. `from odoo import api, fields, models, _`).
4. Odoo exceptions & tools (`from odoo.exceptions import UserError`, `from odoo.tools import float_compare`).
5. Logger definition (`_logger = logging.getLogger(__name__)`).

### Using `self.ensure_one()`
* Call `self.ensure_one()` at the start of methods that must operate on a single record.
* Loop over `self` if the method can handle multiple records.

---

## 2. Database & SQL Performance Guidelines

### SQL Injection Prevention
**NEVER** use string formatting (f-strings, `.format()`, `%`) to insert variables into raw SQL queries.

```python
# ❌ VULNERABLE (SQL Injection)
self.env.cr.execute(f"SELECT id FROM res_partner WHERE name = '{req_name}'")

# ✅ SAFE (Psycopg2 parameterized) - Odoo 16.0
self.env.cr.execute("SELECT id FROM res_partner WHERE name = %s", [req_name])

# ✅ SAFE (SQL wrapper) - Odoo 17.0+
from odoo.tools import SQL
self.env.cr.execute(SQL("SELECT id FROM res_partner WHERE name = %s", req_name))
```

### Cache Invalidation
When updating records bypassing the ORM (`cr.execute`), Odoo's memory cache does not sync automatically. You must invalidate it manually.

```python
# UPDATE query
self.env.cr.execute("UPDATE sale_order SET state = 'done' WHERE id = %s", [order_id])

# Invalidate cache
if hasattr(self.env, 'invalidate_all'):
    self.env.invalidate_all()  # Odoo 17.0+
else:
    self.env.cache.invalidate()  # Odoo 16.0
```

### Row-Level Security in Raw SQL
Raw SQL bypasses record rules (`ir.rule`). In multi-company environments, check active company ids:

```python
# Apply active companies filter to raw query
query = self.env['sale.order']._where_calc([])
where_clause, where_params = query.get_sql()
sql = f"SELECT id FROM sale_order WHERE active = True AND {where_clause}"
self.env.cr.execute(sql, where_params)
```

### Batch SQL Operations
Avoid running `cr.execute` in loops. Use bulk operations:

```python
# ✅ Batch Update
self.env.cr.execute("UPDATE account_move SET state='draft' WHERE id IN %s", [tuple(list_of_ids)])
```

### Prohibition of `cr.commit()`
Never call `cr.commit()` in business code. The framework manages transactions automatically. Only allowed in:
* Migration scripts (`pre-migration.py` / `post-migration.py`).
* Heavy Cron tasks processing large batches (must be well-documented).

---

## 3. Security Guidelines

### Access Control Lists (ACLs)
Every model **must** have security records defined in `security/ir.model.access.csv`.
* Format: `id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink`
* Naming: `access_model_name_group,model_name,model_model_name,module.group_id,1,1,1,0`

### Security Groups Hierarchy
Define categories and groups inside `security/security.xml`. Ensure implied groups are correctly inherited:

```xml
<record id="group_my_module_user" model="res.groups">
    <field name="name">User</field>
    <field name="implied_ids" eval="[(4, ref('base.group_user'))]"/>
</record>
<record id="group_my_module_manager" model="res.groups">
    <field name="name">Manager</field>
    <field name="implied_ids" eval="[(4, ref('group_my_module_user'))]"/>
</record>
```

### Record Rules (`ir.rule`)
Write multi-company rules or per-user access limits:

```xml
<record id="rule_my_model_company" model="ir.rule">
    <field name="name">My Model: multi-company</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="domain_force">['|', ('company_id', '=', False), ('company_id', 'in', company_ids)]</field>
</record>
```

### HTTP Controllers Security
* Define appropriate authentication: `auth="user"`, `auth="public"`, or `auth="none"`.
* **auth="none"** endpoints must manually verify signatures or secure webhook tokens.
* Never use `.sudo()` without data validation and token check.
* Webhooks requiring no login should disable CSRF (`csrf=False`) only after manual signature check.

### `sudo()` Usage Rules
Only use `sudo()` when business logic requires it (e.g. sending automated emails, writing log history) and **never** to evade ACLs or company record rules protecting sensitive data.

---

## 4. Security & Performance Checklist
- [ ] Every model has an ACL rule in `security/ir.model.access.csv`.
- [ ] Multi-company models have a corresponding company `ir.rule` record rule.
- [ ] Raw SQL queries do not contain f-string or string concatenations.
- [ ] Cache invalidation is triggered after raw UPDATE/DELETE SQL calls.
- [ ] `cr.commit()` is not used inside ordinary actions or buttons.
- [ ] `auth="none"` endpoints verify requests manually.
