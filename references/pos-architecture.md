# Arquitectura del Punto de Venta (POS) — Odoo 16.0–19.0

El POS de Odoo es una **aplicación offline** diseñada para seguir funcionando aunque se caiga el servidor. Por tanto, su arquitectura es drásticamente diferente al del resto del ERP.

## 1. El Paradigma Offline

- **Carga inicial**: Al abrir el POS, Odoo emite llamadas RPC masivas para descargar al navegador (IndexedDB / LocalStorage) un subconjunto completo de datos (Productos, Clientes, Impuestos).
- **Operación Local**: Cuando se cobra a un cliente, NO se hace un RPC para crear el pedido. Todo se calcula en JS usando los modelos locales.
- **Sincronización (Sync)**: Periódicamente o al presionar "Cerrar Caja", el POS agrupa los pedidos locales y los envía al backend (método `create_from_ui` del modelo `pos.order`) en un gran payload JSON.

## 2. Modelos Locales (JavaScript)

En el POS, los modelos no viven en la base de datos de PostgreSQL (durante la operación), sino en colecciones en memoria. En Odoo 16/17, residen en `models.js` (Backbone.js heredado). En Odoo 18+, se refactoriza usando clases nativas JS.

Ejemplo de cómo extender un modelo local en Odoo 16/17/18 para añadir un campo al pedido:

```javascript
/** @odoo-module **/
import { Order } from "@point_of_sale/app/store/models";
import { patch } from "@web/core/utils/patch";

patch(Order.prototype, {
    setup() {
        super.setup(...arguments);
        this.custom_field = this.custom_field || false;
    },
    
    // El método export_as_JSON define qué datos viajan al backend al sincronizar
    export_as_JSON() {
        const json = super.export_as_JSON(...arguments);
        json.custom_field = this.custom_field;
        return json;
    },
    
    // El método init_from_JSON lee datos restaurados (ej. tras recargar pestaña)
    init_from_JSON(json) {
        super.init_from_JSON(...arguments);
        this.custom_field = json.custom_field;
    }
});
```

## 3. Carga de Datos desde el Backend al Frontend (JS)

Si añades un campo a `res.partner` y necesitas verlo en el POS, debes inyectarlo durante la carga inicial. 

**En Odoo 16:** (Vía Python `pos.session`)
```python
# models/pos_session.py
class PosSession(models.Model):
    _inherit = 'pos.session'

    def _loader_params_res_partner(self):
        result = super()._loader_params_res_partner()
        result['search_params']['fields'].append('custom_field')
        return result
```

**En Odoo 17/18/19:** (Vía JS `PosStore` model load)
```javascript
// La carga se gestiona directamente en JS en versiones más modernas
import { PosStore } from "@point_of_sale/app/store/pos_store";
import { patch } from "@web/core/utils/patch";

patch(PosStore.prototype, {
    async _processData(loadedData) {
        await super._processData(...arguments);
        // custom logic after load
    }
});
```

## 4. UI del POS (OWL)

La interfaz del POS utiliza componentes OWL. El patrón más habitual es añadir botones a la pantalla de productos (`ProductScreen`) o a la pantalla de pago (`PaymentScreen`).

*(Ver `templates/pos/pos_button.js.tpl` para un ejemplo completo de inyección de un botón).*

## 5. Recibir Pedidos en el Backend (Python)

Cuando el POS envía el JSON con el pedido, Python debe extraer tus campos personalizados antes de crear el `pos.order` real.

```python
# models/pos_order.py
class PosOrder(models.Model):
    _inherit = 'pos.order'

    custom_field = fields.Boolean(string="Custom Boolean")

    @api.model
    def _order_fields(self, ui_order):
        """Extrae campos del JSON (ui_order) al diccionario vals de creación."""
        res = super()._order_fields(ui_order)
        res['custom_field'] = ui_order.get('custom_field', False)
        return res
```

## 6. Manifest Assets

El código JS/XML del POS NO se carga en `web.assets_backend`, sino en `point_of_sale.assets`:

```python
    "assets": {
        "point_of_sale._assets_pos": [
            "my_module/static/src/pos/**/*.js",
            "my_module/static/src/pos/**/*.xml",
        ],
    }
```
