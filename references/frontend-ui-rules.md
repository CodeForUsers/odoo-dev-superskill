# Frontend & UI Development Rules (Odoo v16.0 - v20.0)

This guide consolidates all XML view conventions, OWL 2 component guidelines, web asset rules, and Point of Sale (POS) architecture guidelines.

---

## 1. XML Views & Architecture

### Conditional view tags: `<tree>` vs `<list>`
* **Odoo 16.0 & 17.0**: Use `<tree>` tags.
* **Odoo 18.0, 19.0 & 20.0**: Use `<list>` tags. `<tree>` is obsolete and triggers syntax errors.
* **ID Naming**: Use `_list` suffix in views for 18.0+ (e.g. `view_sale_order_list`).

```xml
<!-- Odoo 16.0 / 17.0 View -->
<record id="view_partner_tree" model="ir.ui.view">
    <field name="name">res.partner.tree</field>
    <field name="model">res.partner</field>
    <field name="arch" type="xml">
        <tree string="Partners" editable="bottom">
            <field name="name"/>
        </tree>
    </field>
</record>

<!-- Odoo 18.0 / 19.0 / 20.0 View -->
<record id="view_partner_list" model="ir.ui.view">
    <field name="name">res.partner.list</field>
    <field name="model">res.partner</field>
    <field name="arch" type="xml">
        <list string="Partners" editable="bottom">
            <field name="name"/>
        </list>
    </field>
</record>
```

### XML Record Conventions (Odoo 20 House Rules)
* **Attribute Order**: In `<record>` tags, always place `id` before `model`:
  `<record id="my_record_id" model="my.model">`
* **Syntactic Sugar**: Prefer syntactic-sugar tags `<menuitem>`, `<template>`, and `<asset>` over raw `<record>`.
* **Field Order**: Inside `<field>`, specify `name` first, followed by the value (tag body or `eval`), then optional attributes.
* **View Inheritance**: Re-use the original XML id for inheriting views and append `.inherit.<details>` to the view name.
* **Anchor View Inheritance on Names, Not Position**: Anchor xpaths on identifying attributes like `field[@name='...']`, never on brittle document positions like `//group[2]/field[3]`.

### Manual View Migration checklist (16/17 -> 18/19/20)
1. Replace `<tree` with `<list` and `</tree>` with `</list>` in all files.
2. Keep attributes (`editable`, `create`, `delete`, `default_order`, `multi_edit`, `decoration-*`) inside the root tag.
3. Update window actions: `<field name="view_mode">list,form</field>` (replaces `tree,form`).
4. Update inheritance xpaths: `<xpath expr="//list" position="inside">` (replaces `//tree`).

### Indentation and XPath
* Use **4 spaces** indentation.
* Use robust `xpath` expressions based on field names: `<xpath expr="//field[@name='partner_id']" position="after">`.
* Standard position keywords: `inside`, `before`, `after`, `replace`, `attributes`.

### XML ID Naming Standards
Follow the Technical pattern: `<module_name>.<type>_<model_with_underscores>_<variant>`.
* View: `my_module.view_sale_order_form`
* Action: `my_module.action_sale_order`
* Menuitem: `my_module.menu_sale_order`
* Security group: `my_module.group_sale_manager`

### The `invisible` Attribute syntax
Starting from Odoo 16.0+, direct domain evaluation replaces the old `attrs` dictionary:
```xml
<!-- ✅ Correct (Odoo 16.0 - 20.0) -->
<field name="my_field" invisible="state != 'draft'"/>
<field name="my_field" invisible="state != 'draft' or not partner_id"/>
```

---

## 2. OWL 2 Component Development & Web Rules

### Organize by Feature, Not by Type (Odoo 20 Standard)
Do not split web assets into generic `components/`, `services/`, and `styles/` folders. Instead, organize by feature:
```text
static/src/
└── order_summary/
    ├── order_summary.js       # Component logic
    ├── order_summary.xml      # Owl QWeb template
    └── order_summary.scss     # Feature-specific styles
```

### Component Structure
A standard component is split into JS logic and a QWeb template. Avoid getters (`get total()`); use plain methods or Owl computed state instead.

```javascript
/** @odoo-module **/
import { Component, useState, onWillStart } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";

export class MyComponent extends Component {
    static template = "my_module.MyComponent";
    static props = {
        title: { type: String, optional: true },
    };

    setup() {
        this.orm = useService("orm");
        this.state = useState({ records: [] });

        onWillStart(async () => {
            this.state.records = await this.orm.searchRead("res.partner", [], ["name"]);
        });
    }

    // ✅ Use a method instead of a getter
    getRecordCount() {
        return this.state.records.length;
    }
}
```

### Avoid Patching JavaScript Code
Prefer standard extension mechanisms (registries, component props, slots) rather than monkey-patching core JavaScript classes unless strictly necessary.

### Hooks & Services
Always use `useService` inside `setup()` to fetch dependencies:
* `this.orm = useService("orm")` - Model ORM calls.
* `this.notification = useService("notification")` - Global toasts.
* `this.action = useService("action")` - Trigger views/actions.

### Lifecycle Hooks
Must be declared inside the `setup()` method:
* `onWillStart`: Await asynchronous RPC calls before rendering.
* `onMounted`: Triggered when the component DOM element is fully rendered and attached.
* `onWillUnmount`: Cleanup timers or window event listeners.

### QWeb OWL Directives
* Loops require `t-key` for rendering efficiency:
  `<t t-foreach="state.records" t-as="record" t-key="record.id">`
* Event listening: `t-on-click="() => this.onRecordClick(record.id)"`.
* Escaping and rendering text: `<span t-esc="record.name"/>`.

### Registering OWL Components
```javascript
import { registry } from "@web/core/registry";
// Register as a backend client action
registry.category("actions").add("my_module.dashboard", MyComponent);
```

---

## 3. Point of Sale (POS) Architecture

### Offline Paradigm & State
Odoo's POS runs offline-first. Order creation does not execute direct RPC database operations. It constructs the orders inside in-memory JavaScript models and later synchronizes them to the backend in batches using the `pos.order` method `create_from_ui`.

### Extending POS Models (JS patches)
Use `patch` to extend Backbone models (v16) or JS classes (v17/18+):

```javascript
import { Order } from "@point_of_sale/app/store/models";
import { patch } from "@web/core/utils/patch";

patch(Order.prototype, {
    setup() {
        super.setup(...arguments);
        this.custom_field = this.custom_field || false;
    },
    export_as_JSON() {
        const json = super.export_as_JSON(...arguments);
        json.custom_field = this.custom_field;
        return json;
    }
});
```

### Custom POS Data Loading
In Odoo 16.0, inject fields to session loaders via Python:
```python
class PosSession(models.Model):
    _inherit = 'pos.session'
    def _loader_params_res_partner(self):
        result = super()._loader_params_res_partner()
        result['search_params']['fields'].append('custom_field')
        return result
```
In Odoo 17.0+, patch `_processData` in `PosStore` (JS).

### Backend Receiving logic
Hook order val creation in Python to save custom JSON fields:
```python
class PosOrder(models.Model):
    _inherit = 'pos.order'
    custom_field = fields.Boolean("Custom")

    @api.model
    def _order_fields(self, ui_order):
        res = super()._order_fields(ui_order)
        res['custom_field'] = ui_order.get('custom_field', False)
        return res
```

---

## 4. Manifest Assets Bundles
Web assets are grouped by context:
* **Backend UI**: Register files under `web.assets_backend`.
* **POS UI**: Register files under `point_of_sale._assets_pos` (Odoo 17+) or `point_of_sale.assets` (Odoo 16).
