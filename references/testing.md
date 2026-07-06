# Testing — Odoo OCA Development

Testing guide for Odoo modules (16.0–19.0).

---

## 1. Test Structure

```text
tests/
├── __init__.py
├── test_sale_order.py          # sale.order model tests
├── test_sale_order_line.py     # sale.order.line model tests
├── test_controller.py          # HTTP controller tests
└── test_js/                    # Frontend tests (if applicable)
    └── test_widget.js          # QUnit (16/17) or Hoot (18/19)
```

```python
# tests/__init__.py
from . import test_sale_order
from . import test_sale_order_line
from . import test_controller
```

---

## 2. Backend Tests (Python)

### Base Classes

| Class | Usage | Transaction |
|-------|-------|-------------|
| `TransactionCase` | Unit tests, CRUD, business logic | Rollback after each test |
| `SavepointCase` | Tests with shared `setUpClass` (16.0) | Rollback after the class |
| `HttpCase` | Tests needing HTTP request or JS tours | Real commit |
| `Form` | Simulating form interaction (onchange) | Depends on parent class |

> **Note**: Starting from 17.0, `SavepointCase` and `TransactionCase` behave
> similarly. Use `TransactionCase` by default.

### Basic Test with TransactionCase

```python
from odoo.tests.common import TransactionCase
from odoo.exceptions import ValidationError


class TestSaleOrder(TransactionCase):

    @classmethod
    def setUpClass(cls):
        """Shared setup for all tests in the class."""
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
        """Test: create a sales order."""
        order = self.env["sale.order"].create({
            "partner_id": self.partner.id,
        })
        self.assertTrue(order.exists())
        self.assertEqual(order.state, "draft")
        self.assertEqual(order.partner_id, self.partner)

    def test_add_order_line(self):
        """Test: add order line."""
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
        """Test: quantity must be positive."""
        with self.assertRaises(ValidationError):
            self.env["sale.order.line"].create({
                "order_id": self.env["sale.order"].create({
                    "partner_id": self.partner.id,
                }).id,
                "product_id": self.product.id,
                "product_uom_qty": -1,
            })

    def test_compute_amount(self):
        """Test: total calculations."""
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

### Test with Form Simulation (Form)

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
        """Test: product onchange fills in price."""
        order_form = Form(self.env["sale.order"])
        order_form.partner_id = self.partner

        with order_form.order_line.new() as line:
            line.product_id = self.product
            # Verify the onchange filled the price
            self.assertEqual(line.price_unit, 75.0)

        order = order_form.save()
        self.assertEqual(len(order.order_line), 1)
```

### HTTP Controller Test

```python
from odoo.tests.common import HttpCase


class TestMyController(HttpCase):

    def test_public_page(self):
        """Test: public page is accessible."""
        response = self.url_open("/my_module/page")
        self.assertEqual(response.status_code, 200)

    def test_json_api_authenticated(self):
        """Test: JSON endpoint requires authentication."""
        self.authenticate("admin", "admin")
        response = self.url_open(
            "/my_module/api/records",
            data="{}",
            headers={"Content-Type": "application/json"},
        )
        self.assertEqual(response.status_code, 200)
```

---

## 3. Test Tags

Use tags to categorize and run subsets of tests:

```python
from odoo.tests import tagged

@tagged("post_install", "-at_install")
class TestPostInstall(TransactionCase):
    """Runs AFTER the module is installed."""

    def test_data_loaded(self):
        record = self.env.ref("my_module.demo_record")
        self.assertTrue(record.active)


@tagged("at_install")
class TestAtInstall(TransactionCase):
    """Runs DURING module installation (default)."""
    pass
```

### Common Tags

| Tag | Meaning |
|-----|---------|
| `at_install` | Run during installation (default) |
| `post_install` | Run after all modules are installed |
| `-at_install` | Do NOT run during installation |
| `standard` | Standard test (default) |

### Execution Command

```bash
# Run tests for a module
odoo-bin -d testdb -i my_module --test-enable --stop-after-init

# Run specific tests with tag
odoo-bin -d testdb -i my_module --test-tags=post_install --stop-after-init

# Run a specific test (by class or method)
odoo-bin -d testdb -i my_module --test-tags=/my_module:TestSaleOrder.test_create_order
```

---

## 4. Frontend Tests

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

        // Setup and mounting of the component
        const env = await makeTestEnv();
        // ... mount component ...

        assert.containsOnce(target, ".my-widget");
        assert.strictEqual(
            target.querySelector(".my-widget-title").textContent,
            "Expected Title"
        );
    });
});
```

### Odoo 18.0 / 19.0: Hoot

Starting from Odoo 18.0, the frontend testing framework migrates from **QUnit to Hoot**.

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

### Migration QUnit → Hoot

| QUnit | Hoot |
|-------|------|
| `QUnit.module("name", ...)` | `describe("name", () => { ... })` |
| `QUnit.test("name", async (assert) => { ... })` | `test("name", async () => { ... })` |
| `assert.strictEqual(a, b)` | `expect(a).toBe(b)` |
| `assert.containsOnce(target, sel)` | `expect(sel).toHaveCount(1)` |
| `assert.containsNone(target, sel)` | `expect(sel).toHaveCount(0)` |
| `assert.expect(n)` | Not necessary in Hoot |
| `getFixture()` | Not necessary (global DOM) |

---

## 5. Testing Best Practices

### Naming Conventions

```python
# Class name: Test<Model>
class TestSaleOrder(TransactionCase):

    # Method name: test_<action>_<condition>
    def test_create_order_with_partner(self):
        ...

    def test_confirm_order_without_lines_raises_error(self):
        ...

    def test_compute_total_with_discount(self):
        ...
```

### Test Data

```python
# ✅ Create data in setUpClass (shared, efficient)
@classmethod
def setUpClass(cls):
    super().setUpClass()
    cls.partner = cls.env["res.partner"].create({"name": "Test"})

# ✅ Demo data via ref (if they exist)
partner = self.env.ref("base.res_partner_1")

# ❌ Avoid: hardcoded IDs
partner = self.env["res.partner"].browse(1)  # May not exist!
```

### Common Assertions

```python
# Existence
self.assertTrue(record.exists())
self.assertFalse(deleted_record.exists())

# Equality
self.assertEqual(record.state, "draft")
self.assertNotEqual(record.amount, 0)

# Numerics
self.assertAlmostEqual(record.amount, 99.99, places=2)
self.assertGreater(record.quantity, 0)

# Collections
self.assertIn(partner, order.partner_ids)
self.assertEqual(len(order.order_line), 3)

# Exceptions
with self.assertRaises(UserError):
    record.action_invalid()

with self.assertRaises(ValidationError):
    self.env["my.model"].create({"quantity": -1})
```

---

## 6. Recommended Minimum Coverage (OCA)

| Area | Minimum Tests |
|------|---------------|
| Every new model | CRUD (create, read, write, unlink) |
| Computed fields | Verify correct calculation |
| Constraints | Verify exceptions are raised |
| Onchange | Verify filled values (with `Form`) |
| Workflows | Verify state transitions |
| ACLs | Verify access/denial by group |
| Controllers | Verify status codes and responses |
