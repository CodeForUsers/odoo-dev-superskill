# Python Conventions — Odoo OCA Development

Convenciones de código Python para módulos Odoo (16.0–19.0) siguiendo las OCA Guidelines.

---

## 1. Orden de atributos en clases de modelo

Respeta estrictamente este orden dentro de cualquier clase que herede de `models.Model`,
`models.TransientModel` o `models.AbstractModel`:

```python
from odoo import api, fields, models, _
from odoo.exceptions import UserError, ValidationError

import logging

_logger = logging.getLogger(__name__)


class SaleOrderLine(models.Model):
    # --- 1. Atributos privados ---
    _name = "sale.order.line"
    _description = "Sale Order Line"
    _inherit = ["mail.thread", "mail.activity.mixin"]
    _order = "sequence, id"
    _rec_name = "display_name"

    # --- 2. Campos (en orden: default, related, compute, store) ---
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

    # --- 3. Restricciones SQL ---
    _sql_constraints = [
        (
            "positive_quantity",
            "CHECK(quantity > 0)",
            "Quantity must be strictly positive.",
        ),
    ]

    # --- 4. Valores por defecto (métodos) ---
    def _default_company_id(self):
        return self.env.company

    # --- 5. Métodos compute ---
    @api.depends("quantity", "price_unit")
    def _compute_price_subtotal(self):
        for line in self:
            line.price_subtotal = line.quantity * line.price_unit

    # --- 6. Métodos onchange ---
    @api.onchange("product_id")
    def _onchange_product_id(self):
        if self.product_id:
            self.name = self.product_id.display_name
            self.price_unit = self.product_id.list_price

    # --- 7. Métodos constrains ---
    @api.constrains("quantity")
    def _check_quantity(self):
        for line in self:
            if line.quantity <= 0:
                raise ValidationError(
                    _("Quantity must be positive for line '%s'.") % line.name
                )

    # --- 8. Métodos CRUD ---
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

    # --- 9. Métodos de acción (botones) ---
    def action_confirm(self):
        self.ensure_one()
        # lógica de confirmación
        return True

    # --- 10. Métodos privados / de negocio ---
    def _prepare_invoice_line(self):
        self.ensure_one()
        return {
            "product_id": self.product_id.id,
            "quantity": self.quantity,
            "price_unit": self.price_unit,
        }
```

---

## 2. SQL seguro según versión

### Odoo 16.0: `cr.execute` con parámetros

```python
# ✅ Correcto: parámetros como tupla
self.env.cr.execute(
    "SELECT id FROM res_partner WHERE name ILIKE %s AND active = %s",
    (f"%{search_term}%", True),
)
results = self.env.cr.fetchall()

# ❌ PROHIBIDO: concatenación de strings (inyección SQL)
self.env.cr.execute(
    "SELECT id FROM res_partner WHERE name = '" + name + "'"
)
```

### Odoo 17.0+: wrapper `SQL()`

```python
from odoo.tools import SQL

# ✅ Correcto en 17.0+: usar SQL() wrapper
query = SQL(
    "SELECT id, name FROM %s WHERE active = %s AND name ILIKE %s",
    SQL.identifier(self._table),
    True,
    SQL("%%%(pattern)s%%", pattern=search_term),
)
self.env.cr.execute(query)

# ✅ Composición segura de queries
base_query = SQL("SELECT id FROM %s", SQL.identifier("res_partner"))
where_clause = SQL("WHERE active = %s", True)
full_query = SQL("%s %s", base_query, where_clause)
self.env.cr.execute(full_query)
```

> **Nota**: en 17.0+ puedes seguir usando `cr.execute(query, params)` con tupla,
> pero `SQL()` es la forma recomendada para queries complejas con composición.

---

## 3. Prohibición de `cr.commit()`

**Nunca uses `cr.commit()`** en código de negocio normal. El framework gestiona
las transacciones automáticamente.

```python
# ❌ PROHIBIDO en código de negocio
def action_process(self):
    self.state = "done"
    self.env.cr.commit()  # ¡NUNCA!

# ✅ Correcto: dejar que el framework gestione la transacción
def action_process(self):
    self.state = "done"
    # el commit ocurre automáticamente al finalizar la request
```

**Excepciones permitidas** (únicas):
- Scripts de **migración** (`migrations/X.0.Y.Z.W/pre-migration.py`).
- Métodos de **cron** que procesan grandes volúmenes y necesitan commits parciales
  para evitar bloqueos largos (documentar siempre el motivo).

```python
# ✅ Aceptable SOLO en un cron con documentación
def _cron_process_large_batch(self):
    """Procesa lotes grandes con commits parciales para evitar locks."""
    batch_size = 100
    records = self.search([("state", "=", "pending")])
    for i in range(0, len(records), batch_size):
        batch = records[i:i + batch_size]
        batch.write({"state": "done"})
        self.env.cr.commit()  # Commit parcial documentado
        _logger.info("Processed batch %d/%d", i // batch_size + 1,
                      len(records) // batch_size + 1)
```

---

## 4. Sustitución de métodos deprecados por versión

### `name_get()` — deprecado desde 17.0, eliminado en 19.0

```python
# --- Odoo 16.0: name_get() es el estándar ---
# ✅ Correcto en 16.0
def name_get(self):
    return [(rec.id, f"[{rec.code}] {rec.name}") for rec in self]

# --- Odoo 17.0+: usar _compute_display_name ---
# ✅ Correcto en 17.0, 18.0, 19.0
display_name = fields.Char(compute="_compute_display_name")

@api.depends("code", "name")
def _compute_display_name(self):
    for rec in self:
        rec.display_name = f"[{rec.code}] {rec.name}"
```

### `read_group()` — deprecado en 18.0, eliminado en 19.0

```python
# --- Odoo 16.0/17.0: read_group() es el estándar ---
# ✅ Correcto en 16.0/17.0
results = self.env["sale.order"].read_group(
    domain=[("state", "=", "sale")],
    fields=["amount_total:sum"],
    groupby=["partner_id"],
)

# --- Odoo 18.0+: usar _read_group() ---
# ✅ Correcto en 18.0/19.0
results = self.env["sale.order"]._read_group(
    domain=[("state", "=", "sale")],
    groupby=["partner_id"],
    aggregates=["amount_total:sum"],
)
```

### `_search_display_name` — nuevo en 19.0

```python
# --- Odoo 19.0: reemplaza la búsqueda por nombre ---
# ✅ Correcto en 19.0
@api.model
def _search_display_name(self, operator, value):
    return [
        "|",
        ("name", operator, value),
        ("code", operator, value),
    ]
```

---

## 5. Manejo de excepciones y logging

```python
import logging

from odoo import _
from odoo.exceptions import UserError, ValidationError

_logger = logging.getLogger(__name__)

# ❌ PROHIBIDO: except genérico sin acción
try:
    result = self._process_data()
except:
    pass

# ❌ PROHIBIDO: except Exception sin logging
try:
    result = self._process_data()
except Exception:
    pass

# ✅ Correcto: captura específica con logging
try:
    result = self._process_data()
except ValidationError:
    raise  # re-lanzar errores de validación
except Exception as e:
    _logger.exception("Error processing data for record %s: %s", self.id, e)
    raise UserError(
        _("An error occurred while processing. Please contact support.")
    ) from e

# ✅ Correcto: logging informativo
_logger.info("Processing %d records in batch", len(self))
_logger.debug("Record %s values: %s", self.id, vals)
_logger.warning("Deprecated method called for model %s", self._name)
```

---

## 6. Imports y estructura de archivos

### Orden de imports (PEP 8 + OCA)

```python
# 1. Imports de la librería estándar
import logging
from datetime import datetime, timedelta

# 2. Imports de terceros
import requests

# 3. Imports de Odoo
from odoo import _, api, fields, models
from odoo.exceptions import UserError, ValidationError
from odoo.tools import float_compare, float_is_zero

# 4. Logger (siempre después de los imports)
_logger = logging.getLogger(__name__)
```

### Un modelo por archivo

```
models/
├── __init__.py
├── sale_order.py          # class SaleOrder
├── sale_order_line.py     # class SaleOrderLine
└── res_partner.py         # class ResPartner (herencia)
```

```python
# models/__init__.py
from . import sale_order
from . import sale_order_line
from . import res_partner
```

---

## 7. Uso de `self.ensure_one()`

```python
# ✅ Correcto: usar ensure_one() cuando el método opera sobre un solo registro
def action_confirm(self):
    self.ensure_one()
    if self.state != "draft":
        raise UserError(_("Only draft orders can be confirmed."))
    self.state = "confirmed"

# ✅ Correcto: iterar cuando el método puede recibir múltiples registros
def action_cancel(self):
    for record in self:
        if record.state == "confirmed":
            record.state = "cancelled"
```
