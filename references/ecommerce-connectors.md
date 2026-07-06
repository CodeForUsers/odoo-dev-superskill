# E-commerce Connectors — Odoo OCA Development

Design patterns for e-commerce connectors on Odoo (16.0–19.0).
Covers Amazon, eBay, WooCommerce, Mirakl, and Temu.

> **Note**: the architecture patterns are **agnostic of the Odoo version**,
> except for the configuration view syntax (`<tree>` in 16/17 vs `<list>`
> in 18/19). See `references/xml-conventions.md` for the correct tag.

---

## 1. General Connector Architecture

```text
my_connector/
├── __manifest__.py
├── models/
│   ├── __init__.py
│   ├── connector_backend.py       # Connection configuration
│   ├── connector_binding.py       # Local ↔ marketplace mapping
│   ├── product_mapping.py         # Product mapping
│   ├── order_mapping.py           # Order mapping
│   └── stock_sync.py              # Stock synchronization
├── views/
│   ├── connector_backend_views.xml
│   └── binding_views.xml
├── data/
│   ├── cron.xml                   # Synchronization crons
│   └── queue_job_channel.xml      # Queue channels
├── wizards/
│   └── sync_wizard.py             # Manual synchronization wizard
├── security/
│   ├── ir.model.access.csv
│   └── security.xml
└── tests/
    ├── __init__.py
    ├── test_product_mapping.py
    └── test_order_import.py
```

---

## 2. Backend Model (Configuration)

```python
from odoo import api, fields, models, _
from odoo.exceptions import UserError

import logging

_logger = logging.getLogger(__name__)


class ConnectorBackend(models.Model):
    _name = "connector.backend"
    _description = "E-commerce Connector Backend"
    _inherit = ["mail.thread"]

    # --- Configuration Attributes ---
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

    # --- Credentials (encrypted) ---
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

    # --- Sync Configuration ---
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

    # --- Actions ---
    def action_test_connection(self):
        """Test connection with the marketplace."""
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
        """Returns the marketplace specific adapter."""
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

## 3. Binding Model (Mapping)

The binding connects a local Odoo record with its counterpart in the marketplace.

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
        help="Record ID in the marketplace.",
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

    # --- Example: product binding ---
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
        """Retry synchronization."""
        for binding in self:
            binding.sync_state = "pending"
            binding.sync_error = False
```

---

## 4. Work Queues (`queue_job`)

Use the OCA module [`queue_job`](https://github.com/OCA/queue/) to process
synchronizations in the background.

### Manifest Dependency

```python
{
    "depends": ["queue_job"],
    "external_dependencies": {
        "python": ["requests"],
    },
}
```

### Queue Channel

```xml
<!-- data/queue_job_channel.xml -->
<odoo>
    <data noupdate="1">
        <record id="channel_connector" model="queue.job.channel">
            <field name="name">connector</field>
            <field name="parent_id" ref="queue_job.channel_root"/>
        </record>

        <!-- Sub-channels per marketplace (for independent rate-limiting) -->
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

### Using `queue_job` in Code

```python
from odoo.addons.queue_job.job import job


class ConnectorBinding(models.Model):
    _inherit = "connector.binding"

    @job(default_channel="root.connector.amazon")
    def job_import_product(self, backend_id, external_id):
        """Queued job: import product from marketplace."""
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
            raise  # queue_job will retry
        
    def _import_product_data(self, external_data):
        """Map external data to Odoo fields."""
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

## 5. Sync Logs

Create a `connector.sync.log` model with fields: `backend_id` (M2O),
`operation` (import/export), `model_name`, `external_id`, `state`
(success/error/skipped), `message` (Text) and `duration_seconds` (Float).
Sort by `create_date desc` to view the most recent logs first.

---

## 6. Rate-limiting

### Rate-limiter Pattern

Implement a rate-limiter with a sliding window (`deque`) per minute and per day.
Use a `Lock` for thread-safety. The logic: before each request, clear old
timestamps from the window, wait if the per-minute limit is exceeded, and raise
an exception if the daily limit is exceeded.

```python
# Usage in the adapter:
rate_limiter = RateLimiter(max_per_minute=60, max_per_day=10000)
rate_limiter.acquire()  # Waits if necessary
response = requests.get(url, headers=headers)
```

### Limits by Marketplace

| Marketplace | Requests/min | Requests/day | Notes |
|------------|-------------|-------------|-------|
| **Amazon SP-API** | 30–60 (varies by endpoint) | ~36,000 | Burst allowance; throttling with retry-after |
| **eBay** | 5,000/day per app | 5,000 | OAuth2; rate headers in response |
| **WooCommerce** | No official limit | No limit | Depends on hosting; 30/min recommended |
| **Mirakl** | 60 | ~50,000 | API key; `X-RateLimit-*` headers |
| **Temu** | 50 | ~10,000 | Token-based; retry with backoff |

---

## 7. Synchronization Cron

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

### Cron Implementation

```python
class ConnectorBackend(models.Model):
    _inherit = "connector.backend"

    @api.model
    def _cron_sync_products(self):
        """Cron: sync products from all active backends."""
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
                # Do not re-raise: allow other backends to sync
```

---

## 8. Specific Patterns by Marketplace

| Marketplace | Authentication | Key Endpoints | Precautions |
|------------|---------------|---------------|-------------|
| **Amazon SP-API** | OAuth2 + IAM role + refresh token | `getOrders`, `getListingsItem`, `submitFeed` | Stock/price feeds are asynchronous (submit → poll) |
| **eBay** | OAuth2 (user token + app token) | `getOrders`, `createOrUpdateInventoryItem` | Categories and policies change frequently |
| **WooCommerce** | Consumer key/secret (REST API keys) | `/wp-json/wc/v3/*` + webhooks | Pagination via `X-WP-Total`/`X-WP-TotalPages` headers |
| **Mirakl** | API key in header | `offers`, `orders`, `messages` | Order statuses do not map 1:1 with Odoo |
| **Temu** | Token-based with request signing | Products, orders, logistics | Limited docs, rapidly evolving API; exhaustive logging recommended |
