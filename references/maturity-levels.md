# Maturity Levels — Odoo OCA Development

Niveles de madurez para módulos Odoo según los estándares OCA.
Estos niveles son **idénticos para las 4 versiones** (16.0–19.0).

---

## Niveles de madurez

| Nivel | Badge | Significado |
|-------|-------|-------------|
| **Alpha** | `Alpha` | En desarrollo activo, no apto para producción |
| **Beta** | `Beta` | Funcional pero puede tener bugs, apto para testing |
| **Production/Stable** | `Production/Stable` | Probado y estable, apto para producción |
| **Mature** | `Mature` | Estable durante varias versiones, ampliamente adoptado |

---

## Checklist por nivel

### Alpha

Requisitos mínimos para declarar un módulo como Alpha:

- [x] El módulo se instala sin errores.
- [x] El manifest (`__manifest__.py`) contiene todos los campos obligatorios.
- [x] Los modelos tienen ACLs básicas (`ir.model.access.csv`).
- [ ] No se requieren tests.
- [ ] No se requiere documentación completa.

```python
# __manifest__.py
{
    "development_status": "Alpha",
    # ...
}
```

### Beta

Requisitos para declarar un módulo como Beta (incluye todo lo de Alpha):

- [x] Todo lo de Alpha.
- [x] Existe al menos un test por modelo (`TransactionCase` con CRUD básico).
- [x] Las vistas principales funcionan (formulario, lista, búsqueda).
- [x] Existe documentación básica (`README.rst` o carpeta `readme/`).
- [x] Los campos computados tienen tests.
- [x] Las constrains tienen tests que verifican excepciones.
- [ ] No se requiere documentación exhaustiva.

```python
# __manifest__.py
{
    "development_status": "Beta",
    # ...
}
```

### Production/Stable

Requisitos para declarar un módulo como Stable (incluye todo lo de Beta):

- [x] Todo lo de Beta.
- [x] Cobertura de tests adecuada (CRUD, compute, constrains, workflows).
- [x] Documentación completa con estructura OCA:
  - `DESCRIPTION.rst`: descripción funcional.
  - `CONFIGURE.rst`: instrucciones de configuración.
  - `USAGE.rst`: guía de uso con capturas de pantalla.
  - `CONTRIBUTORS.rst`: lista de contribuidores.
- [x] Tests de workflows/transiciones de estado.
- [x] Tests de seguridad (verificar acceso por grupo).
- [x] Reglas de registro (`ir.rule`) para multi-compañía si aplica.
- [x] Sin warnings de deprecación en logs al ejecutar tests.
- [x] Código revisado por al menos un desarrollador.

```python
# __manifest__.py
{
    "development_status": "Production/Stable",
    # ...
}
```

### Mature

Requisitos para declarar un módulo como Mature (incluye todo lo de Stable):

- [x] Todo lo de Production/Stable.
- [x] El módulo ha sido estable durante **al menos 2 versiones** de Odoo
  (ej. funcional en 16.0 y 17.0 sin bugs críticos reportados).
- [x] Ampliamente adoptado por la comunidad (múltiples instalaciones en producción).
- [x] Historial limpio de issues: bugs críticos resueltos en menos de 30 días.
- [x] Cobertura de tests > 80%.
- [x] Documentación completa y actualizada, incluyendo changelog.
- [x] Tests de rendimiento si el módulo maneja grandes volúmenes de datos.

```python
# __manifest__.py
{
    "development_status": "Mature",
    # ...
}
```

---

## Cómo declarar el nivel de madurez

### En el manifest

```python
# __manifest__.py
{
    "name": "My Module",
    "version": "18.0.1.0.0",
    "development_status": "Beta",  # Alpha | Beta | Production/Stable | Mature
    # ...
}
```

### En el README (badge)

Usa un badge en el README para indicar el nivel:

```rst
.. |badge_status| image:: https://img.shields.io/badge/maturity-Beta-yellow.svg
    :target: https://odoo-community.org/page/development-status
    :alt: Beta
```

### Valores válidos para `development_status`

```python
# Valores aceptados por la OCA:
"Alpha"
"Beta"
"Production/Stable"
"Mature"
```

---

## Flujo de progresión

```
Alpha  →  Beta  →  Production/Stable  →  Mature
  │         │              │                  │
  │         │              │                  └─ 2+ versiones estable
  │         │              └─ Tests completos + docs + review
  │         └─ Tests básicos + docs mínimas
  └─ Se instala + ACLs
```

### Cuándo promocionar

| De → A | Condición |
|--------|-----------|
| Alpha → Beta | Tests CRUD pasan, documentación básica existe |
| Beta → Stable | Tests completos, documentación OCA completa, code review |
| Stable → Mature | 2+ versiones sin bugs críticos, amplia adopción |

### Cuándo degradar

| De → A | Condición |
|--------|-----------|
| Stable → Beta | Bug crítico en producción no resuelto en 30 días |
| Mature → Stable | Refactorización mayor que cambia la API |
| Cualquiera → Alpha | Reescritura completa del módulo |

---

## Checklist rápido de validación

Antes de declarar cualquier nivel, verifica:

- [ ] ¿`development_status` está definido en el manifest?
- [ ] ¿El nivel declarado coincide con la realidad del módulo?
- [ ] ¿Los tests pasan al 100%?
- [ ] ¿La documentación es proporcional al nivel declarado?
- [ ] ¿No hay warnings de deprecación si el nivel es Stable o superior?
