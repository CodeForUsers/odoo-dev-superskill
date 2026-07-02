# Version Matrix — Odoo 16.0 a 19.0

Referencia central de cambios que rompen compatibilidad o modifican la sintaxis
esperada entre versiones de Odoo. **Consulta esta tabla antes de generar código.**

---

## Tabla resumen

| Versión | Tag de vista lista | Cambio ORM clave | Frontend |
|---------|-------------------|-------------------|----------|
| 16.0 | `<tree>` | Mejoras en `read_group` | OWL 1/2 en transición |
| 17.0 | `<tree>` | Wrapper `SQL()` seguro | OWL 2 consolidado |
| 18.0 | `<list>` (**breaking change**) | `_read_group` reemplaza `read_group` | Hoot reemplaza QUnit |
| 19.0 | `<list>` | `_search_display_name`, GROUPING SETS | Continuidad de OWL 2 |

---

## Odoo 16.0

### ORM
- Introducción de mejoras en `_read_group` y en la traducción de campos vía JSONB
  en algunos casos.
- `read_group()` es el método público estándar para agrupaciones.
- `name_get()` sigue siendo el método estándar para representación de registros.
- `cr.execute(query, params)` con tupla de parámetros es la forma segura de ejecutar SQL.

```python
# ✅ Correcto en 16.0
def name_get(self):
    return [(rec.id, f"[{rec.code}] {rec.name}") for rec in self]

# ✅ SQL seguro en 16.0
self.env.cr.execute(
    "SELECT id, name FROM res_partner WHERE active = %s",
    (True,)
)
```

### Vistas
- **`<tree>`** es el tag raíz para vistas de lista.
- Los atributos `editable`, `create`, `delete`, `default_order` van dentro del tag `<tree>`.

```xml
<!-- ✅ Correcto en 16.0 -->
<tree string="Partners" editable="bottom" create="true" delete="true">
    <field name="name"/>
    <field name="email"/>
</tree>
```

### Frontend
- OWL 1.x/2.0 en transición. Algunos widgets legacy de jQuery aún presentes.
- Tests de frontend con **QUnit**.
- Los componentes legacy (`Widget`) conviven con componentes OWL.

---

## Odoo 17.0

### ORM
- **Wrapper `SQL()`** para composición segura de queries y prevención de inyección SQL.
  Se recomienda migrar `cr.execute` con concatenación de strings a este wrapper.
- `name_get()` **empieza a deprecarse** en favor del campo computado `display_name`.
  Todavía funciona pero genera advertencias en logs.

```python
# ✅ Recomendado en 17.0: usar SQL() wrapper
from odoo.tools import SQL

query = SQL(
    "SELECT id, name FROM %s WHERE active = %s",
    SQL.identifier(self._table),
    True,
)
self.env.cr.execute(query)

# ⚠️ Deprecado en 17.0 (aún funcional)
def name_get(self):
    return [(rec.id, f"[{rec.code}] {rec.name}") for rec in self]

# ✅ Preferido en 17.0
display_name = fields.Char(
    compute="_compute_display_name",
)

def _compute_display_name(self):
    for rec in self:
        rec.display_name = f"[{rec.code}] {rec.name}"
```

### Vistas
- Sigue usando **`<tree>`** como tag raíz para listas.
- Sin cambios en la sintaxis de vistas respecto a 16.0.

### Frontend
- **OWL 2 se consolida** como framework frontend principal.
- Los widgets legacy jQuery se reducen drásticamente.
- Tests de frontend con **QUnit** (todavía).

### Deprecaciones
| Método/Patrón | Estado en 17.0 | Reemplazo |
|---------------|----------------|-----------|
| `name_get()` | Deprecado (funcional) | `_compute_display_name` |
| `cr.execute` con concatenación | Desaconsejado | `SQL()` wrapper |

---

## Odoo 18.0

### ⚠️ Cambio crítico de vistas

**El tag `<tree>` se renombra oficialmente a `<list>`** en todo el código y la UI.
Todo módulo de terceros que use `<tree>` **debe migrarse o fallará** con errores como:

```
UncaughtPromiseError
Wrong value for ir.ui.view.type: tree
```

#### Herramienta de migración automática

Existe el comando:
```bash
odoo-bin upgrade_code --addons-path=<ruta>
```

que automatiza el reemplazo de `<tree>` por `<list>`. **Sin embargo**, este script
puede colocar mal atributos como `create`, `delete`, `editable`, `default_order`
fuera del tag `<list>`, por lo que **siempre hay que revisar manualmente el resultado**.

```xml
<!-- ❌ Falla en 18.0 -->
<tree string="Partners" editable="bottom">
    <field name="name"/>
</tree>

<!-- ✅ Correcto en 18.0 -->
<list string="Partners" editable="bottom">
    <field name="name"/>
</list>

<!-- ❌ Bug común tras upgrade_code (atributos fuera del tag) -->
<list string="Partners">
    <field name="name"/>
</list>
<!-- editable="bottom" se perdió -->
```

### ORM
- **`read_group` se deprecia** en favor de:
  - `_read_group` (uso interno, devuelve registros agrupados directamente).
  - `formatted_read_group` (API pública, para consumo externo).

```python
# ❌ Deprecado en 18.0
results = self.env['sale.order'].read_group(
    domain=[('state', '=', 'sale')],
    fields=['amount_total:sum'],
    groupby=['partner_id'],
)

# ✅ Correcto en 18.0
results = self.env['sale.order']._read_group(
    domain=[('state', '=', 'sale')],
    groupby=['partner_id'],
    aggregates=['amount_total:sum'],
)
```

### Frontend
- `html_editor` se divide en módulos separados.
- Testing migra de **QUnit a Hoot**.
- Los tests JS existentes deben reescribirse con la API de Hoot.

### Deprecaciones
| Método/Patrón | Estado en 18.0 | Reemplazo |
|---------------|----------------|-----------|
| `<tree>` | **Eliminado** | `<list>` |
| `read_group()` | Deprecado | `_read_group()` / `formatted_read_group()` |
| `name_get()` | Deprecado | `_compute_display_name` |
| QUnit (tests JS) | Deprecado | Hoot |

---

## Odoo 19.0

### ORM
- **Soporte de `GROUPING SETS`** para vistas pivote, permitiendo múltiples niveles
  de agrupación en una sola query.
- **Fechas dinámicas en dominios**: ahora es posible usar expresiones como
  `context_today()` en dominios de forma nativa.
- **`_search_display_name`** reemplaza la búsqueda por nombre como implementación
  estándar para todos los campos `display_name`.

```python
# ✅ Nuevo en 19.0: _search_display_name
@api.model
def _search_display_name(self, operator, value):
    """Búsqueda personalizada por display_name."""
    domain = [
        '|',
        ('name', operator, value),
        ('code', operator, value),
    ]
    return domain
```

- **Dominios personalizados con SQL**: nueva posibilidad de escribir y combinar
  dominios personalizados para inyectar SQL arbitrario de forma controlada.
  **Usar con extremo cuidado** y siempre documentando el motivo.

### Deprecaciones
| Método/Patrón | Estado en 19.0 | Reemplazo |
|---------------|----------------|-----------|
| `odoo.osv` | Deprecado | Módulos específicos |
| `record._cr` | Deprecado | `self.env.cr` |
| `record._context` | Deprecado | `self.env.context` |
| `record._uid` | Deprecado | `self.env.uid` |
| `name_get()` | Eliminado | `_compute_display_name` |
| `read_group()` | Eliminado | `_read_group()` |

### Vistas
- Continúa usando **`<list>`** (igual que 18.0).
- Sin cambios adicionales en la sintaxis de vistas.

### Frontend
- Continuidad de **OWL 2**.
- **Hoot** es el framework de testing estándar.

---

## Guía rápida de migración entre versiones

### 16.0 → 17.0
1. Reemplazar `name_get()` por `_compute_display_name`.
2. Adoptar `SQL()` wrapper para queries complejas.
3. Sin cambios en vistas XML.

### 17.0 → 18.0
1. **Cambio obligatorio**: reemplazar `<tree>` por `<list>` en todas las vistas.
   - Verificar que atributos (`editable`, `create`, `delete`, `default_order`)
     se mantengan dentro del tag `<list>`.
2. Reemplazar `read_group()` por `_read_group()`.
3. Migrar tests JS de QUnit a Hoot.

### 18.0 → 19.0
1. Reemplazar `record._cr`, `record._context`, `record._uid` por `self.env.*`.
2. Implementar `_search_display_name` donde sea necesario.
3. Evaluar uso de `GROUPING SETS` para vistas pivote complejas.

### Saltos mayores (ej. 16.0 → 18.0)
Para saltos de 2+ versiones, considerar el uso de **OpenUpgrade** y aplicar los
cambios de cada versión intermedia en orden. Ver `references/versioning-migrations.md`.
