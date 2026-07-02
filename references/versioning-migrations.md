# Versioning & Migrations — Odoo OCA Development

Guía de versionado y migraciones para módulos Odoo (16.0–19.0).

---

## 1. Formato de versión

El formato estándar OCA para la versión de un módulo es:

```
ODOO_MAJOR.ODOO_MINOR.MODULE_MAJOR.MODULE_MINOR.MODULE_PATCH
```

### Ejemplos

| Versión Odoo | Versión módulo | Significado |
|-------------|----------------|-------------|
| `16.0.1.0.0` | Primera versión estable para Odoo 16.0 | |
| `16.0.1.1.0` | Minor: nueva funcionalidad retrocompatible | |
| `16.0.1.1.1` | Patch: corrección de bug | |
| `17.0.1.0.0` | Migración a Odoo 17.0 (reset de MODULE version) | |
| `18.0.1.0.0` | Migración a Odoo 18.0 | |
| `18.0.2.0.0` | Major: cambio que rompe compatibilidad en Odoo 18.0 | |

### En el `__manifest__.py`

```python
{
    "name": "My Module",
    "version": "18.0.1.0.0",  # Siempre incluir los 5 segmentos
    # ...
}
```

### Cuándo incrementar cada segmento

| Segmento | Cuándo incrementar |
|----------|-------------------|
| `ODOO_MAJOR.ODOO_MINOR` | Al migrar a una nueva versión de Odoo |
| `MODULE_MAJOR` | Cambio que rompe compatibilidad (nuevo modelo, API cambiada) |
| `MODULE_MINOR` | Nueva funcionalidad retrocompatible |
| `MODULE_PATCH` | Corrección de bugs, mejoras menores |

---

## 2. Estructura de migraciones

### Directorio de migraciones

```
my_module/
├── __manifest__.py          # version: "18.0.1.2.0"
├── migrations/
│   ├── 18.0.1.1.0/
│   │   ├── pre-migration.py
│   │   └── post-migration.py
│   ├── 18.0.1.2.0/
│   │   └── post-migration.py
│   └── 17.0.1.0.0/          # Migración desde 16.0
│       ├── pre-migration.py
│       └── post-migration.py
```

### Tipos de scripts de migración

| Script | Cuándo se ejecuta | Uso típico |
|--------|-------------------|-----------|
| `pre-migration.py` | **Antes** de actualizar el módulo | Renombrar columnas/tablas, preparar datos |
| `post-migration.py` | **Después** de actualizar el módulo | Migrar datos, recalcular campos computados |
| `end-migration.py` | Al final de toda la actualización | Limpieza final (raramente necesario) |

### Ejemplo de pre-migration

```python
# migrations/18.0.1.1.0/pre-migration.py

import logging

_logger = logging.getLogger(__name__)


def migrate(cr, version):
    """Pre-migración: renombrar columna antes de que Odoo la elimine."""
    if not version:
        return

    _logger.info("Pre-migration 18.0.1.1.0: renaming column old_field to new_field")

    cr.execute("""
        ALTER TABLE my_model
        RENAME COLUMN old_field TO new_field
    """)
    # cr.commit() es válido aquí (script de migración)
```

### Ejemplo de post-migration

```python
# migrations/18.0.1.1.0/post-migration.py

import logging
from odoo import SUPERUSER_ID, api

_logger = logging.getLogger(__name__)


def migrate(cr, version):
    """Post-migración: recalcular campos y migrar datos."""
    if not version:
        return

    env = api.Environment(cr, SUPERUSER_ID, {})

    _logger.info("Post-migration 18.0.1.1.0: updating computed fields")

    # Recalcular un campo computado almacenado
    records = env["my.model"].search([])
    records._compute_display_name()

    # Migrar datos de un campo a otro
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

## 3. Migración entre versiones mayores de Odoo

### Migración paso a paso (recomendado)

Para migrar un módulo entre versiones mayores (ej. 16.0 → 18.0), aplica los
cambios de **cada versión intermedia** en orden:

#### 16.0 → 17.0

1. Cambiar prefijo de versión: `16.0.X.Y.Z` → `17.0.1.0.0`.
2. Reemplazar `name_get()` por `_compute_display_name`.
3. Adoptar `SQL()` wrapper para queries complejas (opcional pero recomendado).
4. Sin cambios en vistas XML.
5. Crear `migrations/17.0.1.0.0/` si hay cambios de datos.

#### 17.0 → 18.0

1. Cambiar prefijo de versión: `17.0.X.Y.Z` → `18.0.1.0.0`.
2. **OBLIGATORIO**: Reemplazar `<tree>` por `<list>` en todas las vistas.
3. **OBLIGATORIO**: Reemplazar `tree` por `list` en `view_mode` de acciones.
4. Reemplazar `read_group()` por `_read_group()`.
5. Migrar tests JS de QUnit a Hoot (si aplica).
6. Verificar herencias xpath que usen `//tree` → cambiar a `//list`.

#### 18.0 → 19.0

1. Cambiar prefijo de versión: `18.0.X.Y.Z` → `19.0.1.0.0`.
2. Reemplazar `record._cr`, `record._uid`, `record._context` por `self.env.*`.
3. Implementar `_search_display_name` donde se sobrescribía `name_search()`.
4. Evaluar uso de `GROUPING SETS` para vistas pivote.

### Saltos de 2+ versiones

Para saltos grandes (ej. 16.0 → 18.0), aplica las migraciones intermedias
en orden: primero 16→17, luego 17→18.

---

## 4. OpenUpgrade

[OpenUpgrade](https://github.com/OCA/OpenUpgrade) es la herramienta OCA para
migraciones automáticas de la base de datos entre versiones de Odoo.

### Cuándo usar OpenUpgrade

| Escenario | Herramienta |
|-----------|-------------|
| Migrar un módulo custom | Scripts de migración propios (`migrations/`) |
| Migrar una instancia completa de Odoo | OpenUpgrade |
| Migrar módulos OCA | Verificar si OCA provee scripts de migración |

### Estructura de OpenUpgrade

```
openupgradelib/
├── openupgrade.py        # Funciones helper para migraciones
└── ...

# En tus scripts de migración:
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

### Funciones helper de OpenUpgrade más comunes

| Función | Uso |
|---------|-----|
| `rename_fields` | Renombrar campos (columna + ir.model.fields) |
| `rename_models` | Renombrar modelos (tabla + referencias) |
| `rename_xmlids` | Renombrar XML IDs |
| `logged_query` | Ejecutar SQL con logging |
| `add_fields` | Añadir columnas faltantes |
| `map_values` | Mapear valores de un campo a otro |
| `column_exists` | Verificar si una columna existe |

---

## 5. Checklist de migración

### Antes de empezar

- [ ] ¿Tienes un backup de la base de datos?
- [ ] ¿Has identificado todos los cambios de la versión origen a la destino?
  (consulta `references/version-matrix.md`)
- [ ] ¿Hay módulos dependientes que también necesiten migración?

### Durante la migración

- [ ] ¿Actualizado el prefijo de versión en `__manifest__.py`?
- [ ] ¿Creado el directorio `migrations/X.0.1.0.0/`?
- [ ] ¿Escritos los scripts pre/post-migration necesarios?
- [ ] ¿Reemplazado `<tree>` por `<list>` (si migras a 18.0+)?
- [ ] ¿Reemplazados métodos deprecados por sus equivalentes?
- [ ] ¿Actualizadas las dependencias en el manifest?

### Después de la migración

- [ ] ¿Los tests pasan en la nueva versión?
- [ ] ¿La UI funciona correctamente (vistas, menús, acciones)?
- [ ] ¿Los datos se migraron correctamente?
- [ ] ¿Los reportes se generan sin errores?
- [ ] ¿Los crons funcionan correctamente?
