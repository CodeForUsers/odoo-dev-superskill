---
name: odoo-dev-superskill
description: >
  Guia experta para crear, revisar, refactorizar y migrar modulos Odoo en las
  versiones 16.0, 17.0, 18.0 y 19.0, siguiendo estrictamente las OCA Guidelines.
  Usala cuando el usuario mencione: crear un modulo Odoo, heredar modelos o
  vistas, escribir seguridad (ACL/ir.rule), migrar entre versiones de Odoo
  (ej. 16 a 18, 17 a 19), corregir errores de vistas tree/list, revisar codigo
  Odoo en busca de anti-patrones, o desarrollar conectores de e-commerce
  (Amazon, eBay, WooCommerce, Mirakl, Temu) sobre Odoo. Aplica tambien si el
  usuario pega codigo con models.Model, _inherit, fields.Many2one, <tree>,
  <list> o un __manifest__.py, sin mencionar la palabra Odoo explicitamente.
license: MIT
version: 1.0.0
compatibility: ["claude-code", "antigravity", "cursor", "windsurf", "codex-cli", "gemini-cli"]
---

# odoo-dev-superskill — Skill de Desarrollo Odoo (16.0–19.0)

Skill completa para que cualquier agente de IA genere, revise, refactorice y migre
módulos Odoo desde la versión 16.0 hasta la 19.x, respetando las OCA Guidelines.

---

## 1. Detección de versión (primer paso obligatorio)

**Antes de escribir una sola línea de código, determina la versión de Odoo objetivo.**

### Estrategia de detección

1. **Buscar `__manifest__.py`** en el directorio del módulo. Extraer el prefijo
   `MAJOR.MINOR` de la clave `version` (ej. `18.0.1.2.0` → `18.0`).
2. Si no hay manifest, revisar `requirements.txt` buscando `odoo>=18` o similar.
3. Ejecutar `scripts/detect_odoo_version.py` para automatizar los pasos anteriores.
4. **Si no hay pistas**, preguntar explícitamente al usuario:
   > "¿Para qué versión de Odoo estás desarrollando? (16.0 / 17.0 / 18.0 / 19.0)"

La versión detectada determina:
- El tag de vista lista (`<tree>` en 16/17, `<list>` en 18/19).
- Qué métodos ORM usar y cuáles están deprecados.
- El framework de testing frontend (QUnit vs Hoot).

Consulta `references/version-matrix.md` para el detalle completo de diferencias.

---

## 2. Flujo de trabajo estándar (6 pasos)

Sigue estos 6 pasos en orden para cualquier tarea de desarrollo Odoo:

| Paso | Acción | Herramienta/Referencia |
|------|--------|----------------------|
| 1 | **Detectar versión** de Odoo objetivo | `scripts/detect_odoo_version.py`, sección 1 |
| 2 | **Generar estructura** del módulo | `templates/manifest/`, `templates/readme_structure/` |
| 3 | **Escribir modelo(s)** Python | `templates/model_skeleton.py.tpl`, `references/python-conventions.md` |
| 4 | **Escribir vistas, seguridad y datos** | `references/xml-conventions.md`, `references/security.md` |
| 5 | **Auto-verificar** con scripts de validación | `scripts/validate_manifest.py`, `scripts/check_anti_patterns.py` |
| 6 | **Declarar nivel de madurez** del módulo | `references/maturity-levels.md` |

---

## 3. Reglas críticas universales (todas las versiones)

Estas reglas aplican **siempre**, independientemente de la versión de Odoo:

1. **Nunca uses `cr.commit()`** fuera de crons o scripts de migración.
2. **Nunca uses `except: pass`** — captura excepciones específicas y loguea con `_logger`.
3. **Siempre define ACLs** (`ir.model.access.csv`) para cada modelo nuevo.
4. **Nunca ejecutes SQL** sin parametrizar — usa `cr.execute(query, params)` o `SQL()` (17+).
5. **Respeta el orden OCA** de atributos en clases de modelo (ver `references/python-conventions.md`).
6. **Un modelo por archivo** Python, salvo modelos auxiliares muy pequeños.
7. **Prefija IDs XML** con el nombre técnico del módulo: `<module_name>.view_<model>_form`.
8. **Incluye tests** — mínimo un `TransactionCase` por modelo con operaciones CRUD básicas.
9. **Documenta con README OCA** — usa la estructura de `templates/readme_structure/`.
10. **Versiona correctamente** — formato `MAJOR.MINOR.PATCH.BUILD` atado a la versión de Odoo.

---

## 4. Diferencias clave por versión

| Versión | Tag vista lista | UI Condicional | Cambio ORM clave | Frontend |
|---------|----------------|-----------------|-------------------|----------|
| 16.0 | `<tree>` | `attrs="{...}"` | Mejoras en `read_group` | OWL 1/2 en transición |
| 17.0 | `<tree>` | `invisible="..."` | Wrapper `SQL()` seguro | OWL 2 consolidado |
| 18.0 | `<list>` (**breaking**) | `invisible="..."` | `_read_group` reemplaza `read_group` | Hoot reemplaza QUnit |
| 19.0 | `<list>` | `invisible="..."` | `_search_display_name`, GROUPING SETS | Continuidad OWL 2 |

> **Regla de oro**: antes de generar cualquier vista, consulta esta tabla y usa
> `<tree>` o `<list>` según la versión objetivo. **Nunca asumas por defecto.**

Para el detalle completo de cada versión, consulta `references/version-matrix.md`.

---

## 5. Índice de referencias

| Referencia | Descripción |
|-----------|-------------|
| [version-matrix.md](references/version-matrix.md) | Cambios entre versiones 16–19, tabla de compatibilidad |
| [python-conventions.md](references/python-conventions.md) | Orden de atributos, SQL seguro, manejo de excepciones |
| [xml-conventions.md](references/xml-conventions.md) | tree vs list, xpath, indentación, nomenclatura de IDs |
| [orm-changelog-16-19.md](references/orm-changelog-16-19.md) | Changelog detallado del ORM entre versiones |
| [security.md](references/security.md) | ACLs, ir.rule, controladores HTTP |
| [testing.md](references/testing.md) | Tests backend y frontend (QUnit / Hoot) |
| [versioning-migrations.md](references/versioning-migrations.md) | Versionado, migraciones, OpenUpgrade |
| [maturity-levels.md](references/maturity-levels.md) | Checklist Alpha / Beta / Stable / Mature |
| [ecommerce-connectors.md](references/ecommerce-connectors.md) | Patrones para Amazon, eBay, WooCommerce, Mirakl, Temu |

---

## 6. Templates disponibles

### Modelos y lógica Python

| Template | Uso |
|----------|-----|
| `templates/manifest/manifest_{16,17,18,19}.py.tpl` | Manifest adaptado a cada versión |
| `templates/model_skeleton.py.tpl` | Esqueleto de modelo con orden OCA |
| `templates/wizard.py.tpl` | TransientModel con confirm/cancel y defaults |

### Controladores, Web y REST APIs

| Template | Uso |
|----------|-----|
| `templates/controller.py.tpl` | Controlador HTTP básico (JSON API, webhook, página pública) |
| `templates/controllers/base_rest_api.py.tpl` | API REST pura y auto-documentada con OpenAPI (OCA `base_rest`) |

### Vistas XML (Backend)

| Template | Uso |
|----------|-----|
| `templates/views/tree_view_16_17.xml.tpl` | Vista lista con `<tree>` (v16/17) |
| `templates/views/list_view_18_19.xml.tpl` | Vista lista con `<list>` (v18/19) |
| `templates/views/advanced_form_view.xml.tpl` | Formulario "Mega" (Smart buttons, Pestañas, One2many) |
| `templates/views/view_inheritance.xml.tpl` | Herencia de vistas (`xpath`, `position="after/inside"`) |
| `templates/views/kanban_view.xml.tpl` | Vista Kanban con QWeb, colores y actividades |
| `templates/views/pivot_view.xml.tpl` | Vista Pivot (filas, columnas, medidas) |
| `templates/views/graph_view.xml.tpl` | Vista Gráfico (bar/line/pie) |
| `templates/views/calendar_view.xml.tpl` | Vista Calendario (start/stop, color, filtros) |
| `templates/views/wizard_form_view.xml.tpl` | Formulario de Wizard con footer de botones |
| `templates/views/cron.xml.tpl` | Acciones programadas (daily/hourly/minutes) |

### Seguridad y Rendimiento

| Archivo | Uso |
|---------|-----|
| `references/sql-performance.md` | Guía de uso de SQL directo (Bypass de ORM) y caché |
| `templates/security/multi_company_rules.xml.tpl`| Reglas `ir.rule` avanzadas para entornos multi-empresa |
| `templates/security/ir.model.access.csv.tpl` | ACLs con nomenclatura OCA |
| `templates/security/security.xml.tpl` | Grupos User/Manager + reglas estándar |

### Datos Iniciales y Demo

| Template | Uso |
|----------|-----|
| `templates/data/data.xml.tpl` | Datos iniciales (params, email templates, server actions) |
| `templates/data/demo_data.xml.tpl` | Datos de demostración con noupdate=1 |

### Reportes y Documentos Impresos

| Template | Uso |
|----------|-----|
| `templates/reports/report_action.xml.tpl` | Registro ir.actions.report + paper format (PDF) |
| `templates/reports/report_qweb_template.xml.tpl` | Plantilla HTML/QWeb con external_layout (PDF) |
| `templates/reports/report_xlsx_action.xml.tpl` | Acción de reporte para exportaciones a Excel |
| `templates/reports/report_xlsx.py.tpl` | Generador dinámico de Excel en Python (OCA `report_xlsx`) |

### Frontend (OWL 2 y SCSS)

| Template | Uso |
|----------|-----|
| `templates/static/src/components/owl_component.js.tpl` | Clase JS para componente OWL 2 (estado, hooks, ORM) |
| `templates/static/src/components/owl_component.xml.tpl` | Vista QWeb/XML para el componente OWL |
| `templates/static/src/components/dashboard/dashboard.js.tpl`| Dashboard avanzado interactivo (Client Action OWL) |
| `templates/static/src/components/dashboard/dashboard.xml.tpl`| QWeb del Dashboard (KPIs, tablas y eventos) |
| `templates/static/src/scss/custom_styles.scss.tpl` | Hoja de estilos SCSS para personalización del backend |

### Infraestructura, CI/CD y Docker

| Template | Uso |
|----------|-----|
| `templates/infra/.pre-commit-config.yaml.tpl` | Configuración estándar OCA (Black, Isort, Flake8) |
| `templates/infra/github_actions_test.yml.tpl` | CI de GitHub Actions con `maintainer-quality-tools` |
| `templates/infra/docker-compose.yml.tpl` | Entorno local de Odoo + PostgreSQL |

### Website y Portal del Cliente

| Template | Uso |
|----------|-----|
| `templates/website/snippet.xml.tpl` | Estructura Drag & Drop para Website Builder |
| `templates/website/snippet_options.xml.tpl` | Opciones de personalización en sidebar |
| `templates/website/portal_view.xml.tpl` | Vistas QWeb para el portal del cliente (Lista/Detalle) |
| `templates/website/portal_controller.py.tpl` | Controlador de rutas seguras para el portal |

### Punto de Venta (POS)

| Template | Uso |
|----------|-----|
| `references/pos-architecture.md` | Guía de la arquitectura offline del TPV |
| `templates/pos/pos_button.js.tpl` | Inyección de botones de acción personalizados en OWL |

### Integraciones, Emails y Migraciones (OpenUpgrade)

| Template | Uso |
|----------|-----|
| `templates/integrations/queue_job.py.tpl` | Encolado de tareas pesadas usando `queue_job` OCA |
| `templates/models/mail_alias_mixin.py.tpl` | Recepción automática de emails (parseo a registros) |
| `templates/scripts/external_rpc_client.py.tpl` | Script standalone (XML-RPC) para interactuar desde fuera |
| `templates/migrations/pre-migration.py.tpl` | Script de pre-migración (renombrar tablas/columnas) |
| `templates/migrations/post-migration.py.tpl` | Script de post-migración (recomputar datos) |

### Testing de Backend, Frontend e Interfaces

| Template | Uso |
|----------|-----|
| `templates/readme_structure/*.rst` | Estructura README estándar OCA |
| `templates/tests/test_transaction_case.py.tpl` | Tests backend (CRUD, compute, constrains, seguridad) |
| `templates/tests/test_hoot.js.tpl` | Tests frontend con Hoot (v18/19 únicamente) |
| `templates/tests/tour.js.tpl` | Guión de E2E UI Test (Odoo Tours) simulando clics |
| `templates/tests/test_tour_python.py.tpl` | Test Python `HttpCase` para ejecutar el Tour |

---

## 7. Scripts de automatización y validación (Grandmaster)

| Script | Función |
|--------|----------|
| `scripts/autofix_xml.py` | **¡Magia Negra!** Convierte `attrs`, `states` y `<tree>` a sintaxis 17/18+ automáticamente |
| `scripts/detect_odoo_version.py` | Detecta la versión de Odoo del proyecto |
| `scripts/scaffold_module.py` | **Genera un módulo completo desde cero** |
| `scripts/create_migration.py` | Crea la estructura y scripts para migrar con OpenUpgrade |
| `scripts/extract_translations.py` | Extrae strings a un archivo `.pot` para traducción |
| `scripts/validate_manifest.py` | Valida estructura y contenido del manifest |
| `scripts/check_anti_patterns.py` | Detecta anti-patrones comunes en código Odoo |
| `scripts/check_acls.py` | Verifica que todos los modelos tienen entrada ACL |
| `scripts/check_test_coverage.py` | Verifica que existen tests y su cobertura básica |

Ejecuta estos scripts después de cada generación o modificación de código para
asegurar la calidad antes de entregar.
