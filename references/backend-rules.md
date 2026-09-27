# Backend Development Rules & Guidelines (Odoo v16.0 - v20.0)

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

    # --- 2. Default methods ---
    def _default_company_id(self):
        return self.env.company

    # --- 3. Fields (in order: default, related, compute, store) ---
    name = fields.Char(string="Description", required=True)
    sequence = fields.Integer(default=10)
    order_id = fields.Many2one("sale.order", required=True, ondelete="cascade")
    product_id = fields.Many2one("product.product", string="Product")
    quantity = fields.Float(string="Quantity", default=1.0)
    price_unit = fields.Float(string="Unit Price")
    price_subtotal = fields.Float(string="Subtotal", compute="_compute_price_subtotal", store=True)
    state = fields.Selection(related="order_id.state", string="Order Status", store=True)

    # --- 4. Constraints and Indexes (Odoo 18.0 - 20.0) ---
    # _sql_constraints is legacy/compatible; modern versions also allow models.Constraint / models.Index
    _sql_constraints = [
        ("positive_quantity", "CHECK(quantity > 0)", "Quantity must be positive."),
    ]

    # --- 5. Compute, inverse, and search methods (in field order) ---
    @api.depends("quantity", "price_unit")
    def _compute_price_subtotal(self):
        for line in self:
            line.price_subtotal = line.quantity * line.price_unit

    # --- 6. Selection methods ---
    # def _selection_target_state(self): ...

    # --- 7. Onchange methods ---
    @api.onchange("product_id")
    def _onchange_product_id(self):
        if self.product_id:
            self.name = self.product_id.display_name
            self.price_unit = self.product_id.list_price

    # --- 8. Constrains methods ---
    @api.constrains("quantity")
    def _check_quantity(self):
        for line in self:
            if line.quantity <= 0:
                raise ValidationError(self.env._("Quantity must be positive."))

    # --- 9. CRUD overrides ---
    @api.model_create_multi
    def create(self, vals_list):
        return super().create(vals_list)

    def write(self, vals):
        return super().write(vals)

    def unlink(self):
        return super().unlink()

    # --- 10. Action methods (buttons) ---
    def action_confirm(self):
        self.ensure_one()
        return True

    # --- 11. Business / Private methods ---
    def _prepare_invoice_line(self):
        self.ensure_one()
        return {}
```

### Domain Construction (`odoo.fields.Domain`)
In modern Odoo (18.0 - 20.0), combine domains using `odoo.fields.Domain`:
* Use operators `&`, `|`, `~` for inline domain logic.
* Use `Domain.AND` and `Domain.OR` when combining lists of existing domains.
* **Never** hand-craft `'&'` or `'|'` prefix lists manually unless working in raw XML.
* **Never** use `expression.AND` / `expression.OR` (deprecated).

```python
from odoo.fields import Domain

# ✅ Modern Domain composition
domain = Domain([("state", "=", "sale")]) & Domain([("partner_id", "=", partner.id)])
```

### Translations & User-Facing Strings (`self.env._`)
Translate only **static literals**, passing dynamic variables as arguments:
* Current API in model code: `self.env._(...)`.
* Pass keyword arguments for named formatting: `self.env._("%(count)s records", count=len(records))`.
* **Never** format inside `_()` (e.g. `_("Text %s" % val)` or `_(f"Text {val}")`).
* **Never** call `_()` at class or module level; use `odoo.tools.translate.LazyTranslate` (`_lt`) if a module-level constant is required.

### Plain ASCII Punctuation in Messages & Comments
* Follow the Odoo 20 guideline: comments, docstrings, commit messages, and translated messages must use **plain ASCII punctuation only**.
* Replace em dashes (`—`) with hyphens, commas, or colons.
* Replace curly quotes (`“ ”`) with standard quotes (`" '`).
* Replace ellipsis character (`…`) with `...`.

### Safe File Opening
* Always open addon files using `odoo.tools.file_open` instead of standard Python `open()`.
* `file_open` resolves paths within addons securely and prevents path-traversal vulnerabilities.

```python
from odoo.tools import file_open

with file_open("my_module/data/template.json", "rb") as f:
    data = f.read()
```

### Exception Handling & Logging
* **Never** use bare `except: pass` or `except Exception: pass`. Catch specific exceptions and log properly.
* **Always** use `_` or `self.env._` for user-facing exceptions (e.g. `UserError`, `ValidationError`).

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
    raise UserError(self.env._("An error occurred. Please contact support.")) from e
```

### Import Ordering (PEP 8 + OCA)
1. Standard library imports (e.g. `import logging`, `from datetime import datetime`).
2. Third-party library imports (e.g. `import requests`).
3. Odoo core imports (e.g. `from odoo import api, fields, models, _`).
4. Odoo exceptions & tools (`from odoo.exceptions import UserError`, `from odoo.tools import float_compare, file_open, SQL`).
5. Logger definition (`_logger = logging.getLogger(__name__)`).

### Using `self.ensure_one()`
* Call `self.ensure_one()` at the start of methods that must operate on a single record (especially `action_*` methods).
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

### `sudo()` Usage Rules (Odoo House Rules)
* **Narrowest scope**: Chain `.sudo()` only onto the exact record or method call needing escalation, not the entire recordset upfront.
* **Mandatory comment**: Every usage of `sudo()` must carry an inline comment explaining why elevated privileges are required.
* **Field-level access**: Be aware that `related=` crossing models is sudo-computed by default; protect sensitive fields with explicit `groups="..."`.
* **Never** use `sudo()` to silently bypass ACLs or multi-company restrictions on sensitive commercial data.

---

## 4. Security & Performance Checklist (Up to Odoo 20.0)
- [ ] Every model has an ACL rule in `security/ir.model.access.csv`.
- [ ] Multi-company models have a corresponding company `ir.rule` record rule.
- [ ] Raw SQL queries do not contain f-string or string concatenations; use `SQL(...)` parameterization.
- [ ] Cache invalidation is triggered after raw UPDATE/DELETE SQL calls (`env.invalidate_all()`).
- [ ] `cr.commit()` is not used inside ordinary actions or buttons.
- [ ] `sudo()` calls are scoped to the minimum necessary and documented with a comment.
- [ ] User-facing strings use `self.env._(...)` with static literals and keyword parameters.
- [ ] Comments, docstrings, and strings use plain ASCII punctuation (no em dashes or curly quotes).
- [ ] Files are opened with `odoo.tools.file_open` rather than standard `open()`.
- [ ] Domains are combined using `odoo.fields.Domain` (&, |, ~, Domain.AND/OR).
- [ ] `auth="none"` endpoints verify signatures manually.
