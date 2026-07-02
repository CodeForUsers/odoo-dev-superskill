# ORM Changelog — Odoo 16.0 a 19.0

Changelog detallado de los cambios en el ORM de Odoo entre las versiones 16.0 y 19.0.

---

## Resumen de métodos deprecados y reemplazos

| Método / Patrón | 16.0 | 17.0 | 18.0 | 19.0 | Reemplazo |
|-----------------|------|------|------|------|-----------|
| `name_get()` | ✅ Estándar | ⚠️ Deprecado | ⚠️ Deprecado | ❌ Eliminado | `_compute_display_name` |
| `read_group()` | ✅ Estándar | ✅ Estándar | ⚠️ Deprecado | ❌ Eliminado | `_read_group()` / `formatted_read_group()` |
| `name_search()` | ✅ Estándar | ✅ Estándar | ✅ Estándar | ⚠️ Deprecado | `_search_display_name` |
| `cr.execute` + concat | ❌ Prohibido | ❌ Prohibido | ❌ Prohibido | ❌ Prohibido | `cr.execute(q, params)` o `SQL()` |
| `SQL()` wrapper | ❌ No existe | ✅ Nuevo | ✅ Estándar | ✅ Estándar | — |
| `record._cr` | ✅ Funcional | ✅ Funcional | ✅ Funcional | ⚠️ Deprecado | `self.env.cr` |
| `record._uid` | ✅ Funcional | ✅ Funcional | ✅ Funcional | ⚠️ Deprecado | `self.env.uid` |
| `record._context` | ✅ Funcional | ✅ Funcional | ✅ Funcional | ⚠️ Deprecado | `self.env.context` |
| `odoo.osv` | ✅ Funcional | ✅ Funcional | ✅ Funcional | ⚠️ Deprecado | Módulos específicos |
| `attrs` en XML | ✅ Funcional | ⚠️ Deprecado | ⚠️ Deprecado | ❌ Eliminado | Atributos directos (`invisible`, `readonly`) |

---

## Odoo 16.0

### Cambios principales del ORM

#### Mejoras en `_read_group`
- El método interno `_read_group` recibe mejoras para traducción de campos y
  agrupaciones con JSONB en ciertos backends.
- El método público sigue siendo `read_group()`.

#### Traducción de campos con JSONB
- En algunos escenarios, Odoo 16.0 empieza a usar columnas JSONB para
  almacenar traducciones de campos, en lugar de la tabla `ir_translation`.

```python
# 16.0: read_group es el estándar público
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
- Ya disponible y recomendado para sobreescribir `create()` recibiendo
  una lista de diccionarios.

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

### Wrapper `SQL()` para composición segura

El cambio más significativo del ORM en 17.0. Permite componer queries SQL de
forma segura, evitando inyección por concatenación de strings.

```python
from odoo.tools import SQL

# Composición segura
table = SQL.identifier(self._table)
query = SQL(
    "SELECT id, name FROM %s WHERE active = %s AND company_id = %s",
    table,
    True,
    self.env.company.id,
)
self.env.cr.execute(query)

# Composición de fragmentos
select = SQL("SELECT id, name FROM %s", table)
where = SQL("WHERE state IN %s", tuple(["draft", "confirmed"]))
order = SQL("ORDER BY create_date DESC")
full_query = SQL("%s %s %s", select, where, order)
self.env.cr.execute(full_query)
```

### Deprecación de `name_get()`

`name_get()` empieza a generar warnings en logs. El reemplazo es el campo
computado `display_name`:

```python
# ✅ 17.0+: campo computado
display_name = fields.Char(compute="_compute_display_name")

@api.depends("code", "name")
def _compute_display_name(self):
    for rec in self:
        rec.display_name = f"[{rec.code}] {rec.name}"
```

### Mejoras en `with_context` y `with_company`

```python
# Forma más limpia de cambiar contexto
records = self.with_context(active_test=False).search([])
records_company = self.with_company(company).search([])
```

---

## Odoo 18.0

### Deprecación de `read_group()`

El método público `read_group()` se deprecia. Los reemplazos son:

```python
# ❌ Deprecado en 18.0
results = self.env["sale.order"].read_group(
    domain=[("state", "=", "sale")],
    fields=["amount_total:sum"],
    groupby=["partner_id"],
)

# ✅ Uso interno: _read_group
# Nota: la firma cambia — groupby y aggregates son argumentos separados
results = self.env["sale.order"]._read_group(
    domain=[("state", "=", "sale")],
    groupby=["partner_id"],
    aggregates=["amount_total:sum"],
)
# Retorna lista de tuplas: [(partner, sum_amount_total), ...]

# ✅ API pública: formatted_read_group
results = self.env["sale.order"].formatted_read_group(
    domain=[("state", "=", "sale")],
    groupby=["partner_id"],
    aggregates=["amount_total:sum"],
)
```

### Cambios en la firma de `_read_group`

La firma de `_read_group` en 18.0 es significativamente diferente de
versiones anteriores:

```python
# 18.0: nueva firma
Model._read_group(
    domain,                  # lista de dominios
    groupby=["field1"],      # lista de campos para agrupar
    aggregates=["field2:agg"], # lista de "campo:agregación"
    having=[],               # condiciones HAVING opcionales
    offset=0,
    limit=None,
    order=None,
)
# Retorna: [(group_value_1, agg_value_1), ...]
```

### Mejoras en campos computados

```python
# 18.0: mejor soporte para flush y prefetch en campos computados
# Los campos compute+store se recalculan más eficientemente
price_total = fields.Float(
    compute="_compute_price_total",
    store=True,
    precompute=True,  # Se calcula antes del INSERT
)
```

---

## Odoo 19.0

### `GROUPING SETS` para vistas pivote

```python
# 19.0: soporte nativo de GROUPING SETS
# Permite múltiples niveles de agrupación en una sola query
# Usado internamente por las vistas pivote para mayor rendimiento
results = self.env["sale.order"]._read_group(
    domain=[("state", "=", "sale")],
    groupby=["partner_id", "date_order:month"],
    aggregates=["amount_total:sum", "__count"],
)
```

### `_search_display_name`

Nuevo método que reemplaza `name_search()` como implementación estándar
para búsquedas por nombre:

```python
@api.model
def _search_display_name(self, operator, value):
    """Búsqueda personalizada: por nombre O código."""
    return [
        "|",
        ("name", operator, value),
        ("code", operator, value),
    ]
```

### Fechas dinámicas en dominios

```python
# 19.0: expresiones de fecha nativas en dominios
domain = [
    ("date_order", ">=", "context_today() - relativedelta(months=3)"),
]
```

### Deprecaciones de accesores directos

```python
# ❌ Deprecado en 19.0
self._cr.execute(query)
uid = self._uid
ctx = self._context

# ✅ Correcto en 19.0
self.env.cr.execute(query)
uid = self.env.uid
ctx = self.env.context
```

### Dominios personalizados con SQL

```python
# 19.0: inyección SQL controlada en dominios (usar con extremo cuidado)
# Siempre documentar el motivo de uso
from odoo.osv.expression import DOMAIN_OPERATORS

# Solo para casos donde los dominios estándar no son suficientes
# Ejemplo: búsqueda full-text con tsvector
```

> **⚠️ Precaución**: esta funcionalidad es poderosa pero peligrosa. Solo usarla
> cuando los dominios estándar de Odoo sean insuficientes, y siempre documentar
> exhaustivamente el motivo.

---

## Patrones comunes válidos en todas las versiones

### Herencia de modelos

```python
# Herencia por extensión (la más común)
class ResPartner(models.Model):
    _inherit = "res.partner"

    custom_field = fields.Char(string="Custom Field")

# Herencia por delegación
class ProductProduct(models.Model):
    _name = "product.product"
    _inherits = {"product.template": "product_tmpl_id"}

# Herencia abstracta
class MailThread(models.AbstractModel):
    _name = "mail.thread"
    _description = "Mail Thread"
```

### Decoradores de API

```python
# Válidos en 16.0–19.0
@api.depends("field1", "field2")      # Para campos computados
@api.constrains("field1")              # Validaciones
@api.onchange("field1")                # Cambios en UI
@api.model                             # Métodos de clase
@api.model_create_multi                # Override de create()
@api.returns("self", lambda rec: rec.id)  # Tipo de retorno
```
