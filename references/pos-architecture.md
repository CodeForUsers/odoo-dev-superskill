# Point of Sale (POS) Architecture — Odoo 16.0–19.0

Odoo's POS is an **offline-first application** designed to keep working even if the server goes down. Therefore, its architecture is drastically different from the rest of the ERP.

## 1. The Offline Paradigm

- **Initial Load**: Upon opening the POS, Odoo makes massive RPC calls to download a complete subset of data (Products, Customers, Taxes) into the browser (IndexedDB / LocalStorage).
- **Local Operation**: When checking out a customer, it does NOT make an RPC call to create the order. Everything is calculated in JS using local models.
- **Synchronization (Sync)**: Periodically or when pressing "Close Session", the POS groups local orders and sends them to the backend (`create_from_ui` method of the `pos.order` model) in a large JSON payload.

## 2. Local Models (JavaScript)

In the POS, models do not live in the PostgreSQL database (during operation), but in in-memory collections. In Odoo 16/17, they reside in `models.js` (legacy Backbone.js). In Odoo 18+, this is refactored using native JS classes.

Example of extending a local model in Odoo 16/17/18 to add a field to the order:

```javascript
/** @odoo-module **/
import { Order } from "@point_of_sale/app/store/models";
import { patch } from "@web/core/utils/patch";

patch(Order.prototype, {
    setup() {
        super.setup(...arguments);
        this.custom_field = this.custom_field || false;
    },
    
    // The export_as_JSON method defines what data travels to the backend when syncing
    export_as_JSON() {
        const json = super.export_as_JSON(...arguments);
        json.custom_field = this.custom_field;
        return json;
    },
    
    // The init_from_JSON method reads restored data (e.g., after reloading the tab)
    init_from_JSON(json) {
        super.init_from_JSON(...arguments);
        this.custom_field = json.custom_field;
    }
});
```

## 3. Data Loading from Backend to Frontend (JS)

If you add a field to `res.partner` and need to see it in the POS, you must inject it during the initial load. 

**In Odoo 16:** (Via Python `pos.session`)
```python
# models/pos_session.py
class PosSession(models.Model):
    _inherit = 'pos.session'

    def _loader_params_res_partner(self):
        result = super()._loader_params_res_partner()
        result['search_params']['fields'].append('custom_field')
        return result
```

**In Odoo 17/18/19:** (Via JS `PosStore` model load)
```javascript
// Loading is managed directly in JS in more modern versions
import { PosStore } from "@point_of_sale/app/store/pos_store";
import { patch } from "@web/core/utils/patch";

patch(PosStore.prototype, {
    async _processData(loadedData) {
        await super._processData(...arguments);
        // custom logic after load
    }
});
```

## 4. POS UI (OWL)

The POS interface uses OWL components. The most common pattern is adding buttons to the product screen (`ProductScreen`) or the payment screen (`PaymentScreen`).

*(See `templates/pos/pos_button.js.tpl` for a complete button injection example).*

## 5. Receiving Orders in the Backend (Python)

When the POS sends the JSON with the order, Python must extract your custom fields before creating the real `pos.order`.

```python
# models/pos_order.py
class PosOrder(models.Model):
    _inherit = 'pos.order'

    custom_field = fields.Boolean(string="Custom Boolean")

    @api.model
    def _order_fields(self, ui_order):
        """Extracts fields from the JSON (ui_order) into the creation vals dictionary."""
        res = super()._order_fields(ui_order)
        res['custom_field'] = ui_order.get('custom_field', False)
        return res
```

## 6. Manifest Assets

POS JS/XML code is NOT loaded into `web.assets_backend`, but into `point_of_sale.assets`:

```python
    "assets": {
        "point_of_sale._assets_pos": [
            "my_module/static/src/pos/**/*.js",
            "my_module/static/src/pos/**/*.xml",
        ],
    }
```
