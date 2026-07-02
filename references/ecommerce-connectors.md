# E-commerce Connectors — Odoo OCA Development

Patrones de diseño para conectores de e-commerce sobre Odoo (16.0–19.0).
Cubre Amazon, eBay, WooCommerce, Mirakl y Temu.

> **Nota**: los patrones de arquitectura son **agnósticos de la versión de Odoo**,
> salvo por la sintaxis de vistas de configuración (`<tree>` en 16/17 vs `<list>`
> en 18/19). Consulta `references/xml-conventions.md` para el tag correcto.

---

## 1. Arquitectura general de un conector

```
my_connector/
├── __manifest__.py
├── models/
│   ├── __init__.py
│   ├── connector_backend.py       # Configuración de la conexión
│   ├── connector_binding.py       # Mapping local ↔ marketplace
│   ├── product_mapping.py         # Mapping de productos
│   ├── order_mapping.py           # Mapping de pedidos
│   └── stock_sync.py              # Sincronización de stock
├── views/
│   ├── connector_backend_views.xml
│   └── binding_views.xml
├── data/
│   ├── cron.xml                   # Crons de sincronización
│   └── queue_job_channel.xml      # Canales de cola
├── wizards/
│   └── sync_wizard.py             # Wizard de sincronización manual
├── security/
│   ├── ir.model.access.csv
│   └── security.xml
└── tests/
    ├── __init__.py
    ├── test_product_mapping.py
    └── test_order_import.py
```

---

## 2. Modelo de backend (configuración)

```python
from odoo import api, fields, models, _
from odoo.exceptions import UserError

import logging

_logger = logging.getLogger(__name__)


class ConnectorBackend(models.Model):
    _name = "connector.backend"
    _description = "E-commerce Connector Backend"
    _inherit = ["mail.thread"]

    # --- Atributos de configuración ---
    name = fields.Char(string="Name", required=True)
    marketplace = fields.Selection(
        selection=[
            ("amazon", "Amazon"),
            ("ebay", "eBay"),
            ("woocommerce", "WooCommerce"),
            ("mirakl", "Mirakl"),
            ("temu", "Temu"),
        ],
        string="Marketplace",
        required=True,
    )
    state = fields.Selection(
        selection=[
            ("draft", "Draft"),
            ("connected", "Connected"),
            ("error", "Error"),
        ],
        default="draft",
        tracking=True,
    )

    # --- Credenciales (encriptadas) ---
    api_key = fields.Char(string="API Key", groups="base.group_system")
    api_secret = fields.Char(string="API Secret", groups="base.group_system")
    api_url = fields.Char(string="API URL")
    environment = fields.Selection(
        selection=[
            ("sandbox", "Sandbox"),
            ("production", "Production"),
        ],
        default="sandbox",
    )

    # --- Configuración de sincronización ---
    sync_products = fields.Boolean(default=True)
    sync_orders = fields.Boolean(default=True)
    sync_stock = fields.Boolean(default=True)
    sync_interval_minutes = fields.Integer(
        string="Sync Interval (minutes)",
        default=30,
    )
    last_sync_date = fields.Datetime(
        string="Last Sync",
        readonly=True,
    )

    # --- Rate limiting ---
    max_requests_per_minute = fields.Integer(
        string="Max Requests/min",
        default=60,
    )
    max_requests_per_day = fields.Integer(
        string="Max Requests/day",
        default=10000,
    )

    # --- Acciones ---
    def action_test_connection(self):
        """Probar conexión con el marketplace."""
        self.ensure_one()
        try:
            adapter = self._get_adapter()
            adapter.test_connection()
            self.state = "connected"
            return {
                "type": "ir.actions.client",
                "tag": "display_notification",
                "params": {
                    "title": _("Connection Successful"),
                    "message": _("Connected to %s.") % self.name,
                    "type": "success",
                },
            }
        except Exception as e:
            self.state = "error"
            _logger.exception("Connection test failed for %s: %s", self.name, e)
            raise UserError(
                _("Connection failed: %s") % str(e)
            ) from e

    def _get_adapter(self):
        """Retorna el adaptador específico del marketplace."""
        self.ensure_one()
        adapter_map = {
            "amazon": "connector.adapter.amazon",
            "ebay": "connector.adapter.ebay",
            "woocommerce": "connector.adapter.woocommerce",
            "mirakl": "connector.adapter.mirakl",
            "temu": "connector.adapter.temu",
        }
        adapter_model = adapter_map.get(self.marketplace)
        if not adapter_model:
            raise UserError(
                _("No adapter found for marketplace '%s'.") % self.marketplace
            )
        return self.env[adapter_model].new({"backend_id": self.id})
```

---

## 3. Modelo de binding (mapping)

El binding conecta un registro local de Odoo con su contraparte en el marketplace.

```python
class ConnectorBinding(models.Model):
    _name = "connector.binding"
    _description = "Connector Binding"
    _rec_name = "external_id"

    backend_id = fields.Many2one(
        "connector.backend",
        string="Backend",
        required=True,
        ondelete="cascade",
    )
    external_id = fields.Char(
        string="External ID",
        index=True,
        help="ID del registro en el marketplace.",
    )
    sync_state = fields.Selection(
        selection=[
            ("pending", "Pending"),
            ("synced", "Synced"),
            ("error", "Error"),
        ],
        default="pending",
    )
    sync_date = fields.Datetime(string="Last Sync Date")
    sync_error = fields.Text(string="Last Sync Error")

    # --- Ejemplo: binding de producto ---
    product_id = fields.Many2one(
        "product.product",
        string="Product",
        ondelete="cascade",
    )

    _sql_constraints = [
        (
            "unique_external_per_backend",
            "UNIQUE(backend_id, external_id)",
            "External ID must be unique per backend.",
        ),
    ]

    def action_retry_sync(self):
        """Reintentar sincronización."""
        for binding in self:
            binding.sync_state = "pending"
            binding.sync_error = False
```

---

## 4. Colas de trabajo (`queue_job`)

Usa el módulo OCA [`queue_job`](https://github.com/OCA/queue/) para procesar
sincronizaciones en segundo plano.

### Dependencia en manifest

```python
{
    "depends": ["queue_job"],
    "external_dependencies": {
        "python": ["requests"],
    },
}
```

### Canal de cola

```xml
<!-- data/queue_job_channel.xml -->
<odoo>
    <data noupdate="1">
        <record id="channel_connector" model="queue.job.channel">
            <field name="name">connector</field>
            <field name="parent_id" ref="queue_job.channel_root"/>
        </record>

        <!-- Sub-canales por marketplace (para rate-limiting independiente) -->
        <record id="channel_connector_amazon" model="queue.job.channel">
            <field name="name">connector.amazon</field>
            <field name="parent_id" ref="channel_connector"/>
        </record>

        <record id="channel_connector_ebay" model="queue.job.channel">
            <field name="name">connector.ebay</field>
            <field name="parent_id" ref="channel_connector"/>
        </record>
    </data>
</odoo>
```

### Uso de `queue_job` en código

```python
from odoo.addons.queue_job.job import job


class ConnectorBinding(models.Model):
    _inherit = "connector.binding"

    @job(default_channel="root.connector.amazon")
    def job_import_product(self, backend_id, external_id):
        """Job en cola: importar producto desde marketplace."""
        backend = self.env["connector.backend"].browse(backend_id)
        adapter = backend._get_adapter()

        try:
            external_data = adapter.read_product(external_id)
            self._import_product_data(external_data)
            self.sync_state = "synced"
            self.sync_date = fields.Datetime.now()
        except Exception as e:
            self.sync_state = "error"
            self.sync_error = str(e)
            _logger.exception(
                "Failed to import product %s from %s: %s",
                external_id, backend.name, e,
            )
            raise  # queue_job reintentará

    def _import_product_data(self, external_data):
        """Mapear datos externos a campos de Odoo."""
        self.ensure_one()
        vals = {
            "name": external_data.get("title"),
            "list_price": external_data.get("price", 0.0),
            "default_code": external_data.get("sku"),
            "barcode": external_data.get("ean"),
        }
        if self.product_id:
            self.product_id.write(vals)
        else:
            product = self.env["product.product"].create(vals)
            self.product_id = product
```

---

## 5. Logs de sincronización

Crear un modelo `connector.sync.log` con campos: `backend_id` (M2O),
`operation` (import/export), `model_name`, `external_id`, `state`
(success/error/skipped), `message` (Text) y `duration_seconds` (Float).
Ordenar por `create_date desc` para ver los logs más recientes primero.

---

## 6. Rate-limiting

### Patrón de rate-limiter

Implementar un rate-limiter con ventana deslizante (`deque`) por minuto y por día.
Usar un `Lock` para thread-safety. La lógica: antes de cada request, limpiar
timestamps antiguos de la ventana, esperar si se excede el límite por minuto, y
lanzar excepción si se excede el límite diario.

```python
# Uso en el adaptador:
rate_limiter = RateLimiter(max_per_minute=60, max_per_day=10000)
rate_limiter.acquire()  # Espera si es necesario
response = requests.get(url, headers=headers)
```

### Límites por marketplace

| Marketplace | Requests/min | Requests/día | Notas |
|------------|-------------|-------------|-------|
| **Amazon SP-API** | 30–60 (varía por endpoint) | ~36,000 | Burst allowance; throttling con retry-after |
| **eBay** | 5,000/día por app | 5,000 | OAuth2; rate headers en respuesta |
| **WooCommerce** | Sin límite oficial | Sin límite | Depende del hosting; recomendado 30/min |
| **Mirakl** | 60 | ~50,000 | API key; headers `X-RateLimit-*` |
| **Temu** | 50 | ~10,000 | Token-based; reintentar con backoff |

---

## 7. Cron de sincronización

```xml
<!-- data/cron.xml -->
<odoo>
    <data noupdate="1">
        <record id="cron_sync_products" model="ir.cron">
            <field name="name">Connector: Sync Products</field>
            <field name="model_id" ref="model_connector_backend"/>
            <field name="code">model._cron_sync_products()</field>
            <field name="interval_number">30</field>
            <field name="interval_type">minutes</field>
            <field name="numbercall">-1</field>
            <field name="active" eval="True"/>
        </record>
        <!-- Create similar records for orders (15 min) and stock (60 min) -->
    </data>
</odoo>
```

### Implementación del cron

```python
class ConnectorBackend(models.Model):
    _inherit = "connector.backend"

    @api.model
    def _cron_sync_products(self):
        """Cron: sincronizar productos de todos los backends activos."""
        backends = self.search([
            ("state", "=", "connected"),
            ("sync_products", "=", True),
        ])
        for backend in backends:
            try:
                backend._sync_products()
                backend.last_sync_date = fields.Datetime.now()
            except Exception as e:
                _logger.exception(
                    "Product sync failed for backend %s: %s",
                    backend.name, e,
                )
                backend.state = "error"
                # No re-lanzar: permitir que otros backends se sincronicen
```

---

## 8. Patrones específicos por marketplace

| Marketplace | Autenticación | Endpoints clave | Precauciones |
|------------|---------------|-----------------|-------------|
| **Amazon SP-API** | OAuth2 + IAM role + refresh token | `getOrders`, `getListingsItem`, `submitFeed` | Feeds de stock/precios son asincrónicos (submit → poll) |
| **eBay** | OAuth2 (user token + app token) | `getOrders`, `createOrUpdateInventoryItem` | Categorías y políticas cambian frecuentemente |
| **WooCommerce** | Consumer key/secret (REST API keys) | `/wp-json/wc/v3/*` + webhooks | Paginación vía headers `X-WP-Total`/`X-WP-TotalPages` |
| **Mirakl** | API key en header | `offers`, `orders`, `messages` | Estados de orden no mapean 1:1 con Odoo |
| **Temu** | Token-based con firma de request | Productos, pedidos, logística | Documentación limitada, API en evolución rápida; logging exhaustivo recomendado |
