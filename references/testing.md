# Testing — Odoo OCA Development

Guía de testing para módulos Odoo (16.0–19.0).

---

## 1. Estructura de tests

```
tests/
├── __init__.py
├── test_sale_order.py          # Tests del modelo sale.order
├── test_sale_order_line.py     # Tests del modelo sale.order.line
├── test_controller.py          # Tests de controladores HTTP
└── test_js/                    # Tests frontend (si aplica)
    └── test_widget.js          # QUnit (16/17) o Hoot (18/19)
```

```python
# tests/__init__.py
from . import test_sale_order
from . import test_sale_order_line
from . import test_controller
```

---

## 2. Tests de backend (Python)

### Clases base

| Clase | Uso | Transacción |
|-------|-----|-------------|
| `TransactionCase` | Tests unitarios, CRUD, lógica de negocio | Rollback tras cada test |
| `SavepointCase` | Tests con `setUpClass` compartido (16.0) | Rollback tras la clase |
| `HttpCase` | Tests que necesitan request HTTP o tours JS | Commit real |
| `Form` | Simular interacción de formularios (onchange) | Según la clase padre |

> **Nota**: A partir de 17.0, `SavepointCase` y `TransactionCase` se comportan
> de forma similar. Usa `TransactionCase` por defecto.

### Test básico con TransactionCase

```python
from odoo.tests.common import TransactionCase
from odoo.exceptions import ValidationError


class TestSaleOrder(TransactionCase):

    @classmethod
    def setUpClass(cls):
        """Configuración compartida para todos los tests de la clase."""
        super().setUpClass()
        cls.partner = cls.env["res.partner"].create({
            "name": "Test Partner",
            "email": "test@example.com",
        })
        cls.product = cls.env["product.product"].create({
            "name": "Test Product",
            "list_price": 100.0,
        })

    def test_create_order(self):
        """Test: crear un pedido de venta."""
        order = self.env["sale.order"].create({
            "partner_id": self.partner.id,
        })
        self.assertTrue(order.exists())
        self.assertEqual(order.state, "draft")
        self.assertEqual(order.partner_id, self.partner)

    def test_add_order_line(self):
        """Test: añadir línea de pedido."""
        order = self.env["sale.order"].create({
            "partner_id": self.partner.id,
            "order_line": [(0, 0, {
                "product_id": self.product.id,
                "product_uom_qty": 5,
                "price_unit": 100.0,
            })],
        })
        self.assertEqual(len(order.order_line), 1)
        self.assertEqual(order.order_line.product_uom_qty, 5)

    def test_constrains_quantity(self):
        """Test: la cantidad debe ser positiva."""
        with self.assertRaises(ValidationError):
            self.env["sale.order.line"].create({
                "order_id": self.env["sale.order"].create({
                    "partner_id": self.partner.id,
                }).id,
                "product_id": self.product.id,
                "product_uom_qty": -1,
            })

    def test_compute_amount(self):
        """Test: cálculo de totales."""
        order = self.env["sale.order"].create({
            "partner_id": self.partner.id,
            "order_line": [(0, 0, {
                "product_id": self.product.id,
                "product_uom_qty": 3,
                "price_unit": 50.0,
            })],
        })
        self.assertEqual(order.amount_total, 150.0)
```

### Test con simulación de formulario (Form)

```python
from odoo.tests.common import Form, TransactionCase


class TestSaleOrderForm(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.partner = cls.env["res.partner"].create({"name": "Test"})
        cls.product = cls.env["product.product"].create({
            "name": "Product",
            "list_price": 75.0,
        })

    def test_onchange_product(self):
        """Test: onchange de producto rellena precio."""
        order_form = Form(self.env["sale.order"])
        order_form.partner_id = self.partner

        with order_form.order_line.new() as line:
            line.product_id = self.product
            # Verificar que el onchange rellenó el precio
            self.assertEqual(line.price_unit, 75.0)

        order = order_form.save()
        self.assertEqual(len(order.order_line), 1)
```

### Test de controlador HTTP

```python
from odoo.tests.common import HttpCase


class TestMyController(HttpCase):

    def test_public_page(self):
        """Test: la página pública es accesible."""
        response = self.url_open("/my_module/page")
        self.assertEqual(response.status_code, 200)

    def test_json_api_authenticated(self):
        """Test: el endpoint JSON requiere autenticación."""
        self.authenticate("admin", "admin")
        response = self.url_open(
            "/my_module/api/records",
            data="{}",
            headers={"Content-Type": "application/json"},
        )
        self.assertEqual(response.status_code, 200)
```

---

## 3. Tags de tests

Usa tags para categorizar y ejecutar subconjuntos de tests:

```python
from odoo.tests import tagged

@tagged("post_install", "-at_install")
class TestPostInstall(TransactionCase):
    """Se ejecuta DESPUÉS de instalar el módulo."""

    def test_data_loaded(self):
        record = self.env.ref("my_module.demo_record")
        self.assertTrue(record.active)


@tagged("at_install")
class TestAtInstall(TransactionCase):
    """Se ejecuta DURANTE la instalación del módulo (por defecto)."""
    pass
```

### Tags comunes

| Tag | Significado |
|-----|-------------|
| `at_install` | Ejecutar durante la instalación (default) |
| `post_install` | Ejecutar después de instalar todos los módulos |
| `-at_install` | NO ejecutar durante instalación |
| `standard` | Test estándar (default) |

### Comando de ejecución

```bash
# Ejecutar tests de un módulo
odoo-bin -d testdb -i my_module --test-enable --stop-after-init

# Ejecutar tests específicos con tag
odoo-bin -d testdb -i my_module --test-tags=post_install --stop-after-init

# Ejecutar un test específico (por clase o método)
odoo-bin -d testdb -i my_module --test-tags=/my_module:TestSaleOrder.test_create_order
```

---

## 4. Tests de frontend

### Odoo 16.0 / 17.0: QUnit

```javascript
/** @odoo-module **/

import { registry } from "@web/core/registry";
import { getFixture, click, mount } from "@web/../tests/helpers/utils";
import { makeTestEnv } from "@web/../tests/helpers/mock_env";

QUnit.module("my_module", (hooks) => {
    let target;

    hooks.beforeEach(async () => {
        target = getFixture();
    });

    QUnit.test("widget renders correctly", async (assert) => {
        assert.expect(2);

        // Setup y montaje del componente
        const env = await makeTestEnv();
        // ... montar componente ...

        assert.containsOnce(target, ".my-widget");
        assert.strictEqual(
            target.querySelector(".my-widget-title").textContent,
            "Expected Title"
        );
    });
});
```

### Odoo 18.0 / 19.0: Hoot

A partir de Odoo 18.0, el framework de testing frontend migra de **QUnit a Hoot**.

```javascript
/** @odoo-module **/

import { describe, expect, test } from "@odoo/hoot";
import { mountWithCleanup } from "@web/../tests/web_test_helpers";
import { MyComponent } from "@my_module/components/my_component";

describe("MyComponent", () => {
    test("renders correctly", async () => {
        await mountWithCleanup(MyComponent, {
            props: { title: "Test Title" },
        });

        expect(".my-component").toHaveCount(1);
        expect(".my-component-title").toHaveText("Test Title");
    });

    test("click handler works", async () => {
        await mountWithCleanup(MyComponent, {
            props: { onButtonClick: () => {} },
        });

        await contains(".my-button").click();
        expect(".my-result").toHaveCount(1);
    });
});
```

### Migración QUnit → Hoot

| QUnit | Hoot |
|-------|------|
| `QUnit.module("name", ...)` | `describe("name", () => { ... })` |
| `QUnit.test("name", async (assert) => { ... })` | `test("name", async () => { ... })` |
| `assert.strictEqual(a, b)` | `expect(a).toBe(b)` |
| `assert.containsOnce(target, sel)` | `expect(sel).toHaveCount(1)` |
| `assert.containsNone(target, sel)` | `expect(sel).toHaveCount(0)` |
| `assert.expect(n)` | No necesario en Hoot |
| `getFixture()` | No necesario (DOM global) |

---

## 5. Buenas prácticas de testing

### Nomenclatura

```python
# Nombre de clase: Test<Modelo>
class TestSaleOrder(TransactionCase):

    # Nombre de método: test_<acción>_<condición>
    def test_create_order_with_partner(self):
        ...

    def test_confirm_order_without_lines_raises_error(self):
        ...

    def test_compute_total_with_discount(self):
        ...
```

### Datos de test

```python
# ✅ Crear datos en setUpClass (compartidos, eficiente)
@classmethod
def setUpClass(cls):
    super().setUpClass()
    cls.partner = cls.env["res.partner"].create({"name": "Test"})

# ✅ Datos de demo via ref (si existen)
partner = self.env.ref("base.res_partner_1")

# ❌ Evitar: IDs hardcoded
partner = self.env["res.partner"].browse(1)  # ¡Puede no existir!
```

### Assertions comunes

```python
# Existencia
self.assertTrue(record.exists())
self.assertFalse(deleted_record.exists())

# Igualdad
self.assertEqual(record.state, "draft")
self.assertNotEqual(record.amount, 0)

# Numéricos
self.assertAlmostEqual(record.amount, 99.99, places=2)
self.assertGreater(record.quantity, 0)

# Colecciones
self.assertIn(partner, order.partner_ids)
self.assertEqual(len(order.order_line), 3)

# Excepciones
with self.assertRaises(UserError):
    record.action_invalid()

with self.assertRaises(ValidationError):
    self.env["my.model"].create({"quantity": -1})
```

---

## 6. Cobertura mínima recomendada (OCA)

| Área | Tests mínimos |
|------|--------------|
| Cada modelo nuevo | CRUD (create, read, write, unlink) |
| Campos computados | Verificar cálculo correcto |
| Constrains | Verificar que se lanzan excepciones |
| Onchange | Verificar valores rellenados (con `Form`) |
| Workflows | Verificar transiciones de estado |
| ACLs | Verificar acceso/denegación por grupo |
| Controladores | Verificar status codes y respuestas |
