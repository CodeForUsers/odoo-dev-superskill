# Security — Odoo OCA Development

Security guide for Odoo modules (16.0–19.0). Security rules are
**identical in all 4 versions** except for minor indicated differences.

---

## 1. Access Control Lists (ACL)

### `ir.model.access.csv` File

Every new model **must** have at least one ACL line. Without it, the model
is inaccessible and Odoo displays a security error.

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_sale_order_user,sale.order.user,model_sale_order,sales_team.group_sale_salesman,1,1,1,0
access_sale_order_manager,sale.order.manager,model_sale_order,sales_team.group_sale_manager,1,1,1,1
access_sale_order_line_user,sale.order.line.user,model_sale_order_line,sales_team.group_sale_salesman,1,1,1,0
access_sale_order_line_manager,sale.order.line.manager,model_sale_order_line,sales_team.group_sale_manager,1,1,1,1
```

### Naming Rules

| Field | Pattern |
|-------|---------|
| `id` | `access_<model_with_underscores>_<group>` |
| `name` | `<model.with.dots>.<group>` |
| `model_id:id` | `model_<model_with_underscores>` |
| `group_id:id` | `<module>.<xml_id_of_the_group>` |

### ACL Checklist

- [ ] Does every new model have at least one ACL?
- [ ] Do TransientModel models (wizards) have ACLs for the groups that use them?
- [ ] Are `unlink` permissions restricted to managers/admins?
- [ ] Have ACLs been defined for inherited abstract models with `_name`?

---

## 2. Security Groups

### Group Definition

```xml
<!-- security/security.xml -->
<odoo>
    <data noupdate="0">

        <!-- Category (module) -->
        <record id="module_category_my_module" model="ir.module.category">
            <field name="name">My Module</field>
            <field name="sequence">100</field>
        </record>

        <!-- User group -->
        <record id="group_my_module_user" model="res.groups">
            <field name="name">User</field>
            <field name="category_id" ref="module_category_my_module"/>
            <field name="implied_ids" eval="[(4, ref('base.group_user'))]"/>
        </record>

        <!-- Manager group (inherits from user) -->
        <record id="group_my_module_manager" model="res.groups">
            <field name="name">Manager</field>
            <field name="category_id" ref="module_category_my_module"/>
            <field name="implied_ids" eval="[(4, ref('group_my_module_user'))]"/>
            <field name="users" eval="[(4, ref('base.user_root')),
                                       (4, ref('base.user_admin'))]"/>
        </record>

    </data>
</odoo>
```

### Recommended Hierarchy

```text
base.group_user (Internal User)
  └── my_module.group_my_module_user
        └── my_module.group_my_module_manager
```

---

## 3. Record Rules (`ir.rule`)

Record rules filter which records each user can view/edit.

### Multi-company Rule (most common)

```xml
<record id="rule_my_model_company" model="ir.rule">
    <field name="name">My Model: multi-company</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="domain_force">
        ['|',
         ('company_id', '=', False),
         ('company_id', 'in', company_ids)]
    </field>
</record>
```

### Per-user Rule

```xml
<record id="rule_my_model_own" model="ir.rule">
    <field name="name">My Model: own records only</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="groups" eval="[(4, ref('group_my_module_user'))]"/>
    <field name="domain_force">
        [('user_id', '=', user.id)]
    </field>
    <field name="perm_read" eval="True"/>
    <field name="perm_write" eval="True"/>
    <field name="perm_create" eval="True"/>
    <field name="perm_unlink" eval="False"/>
</record>
```

### Variables available in `domain_force`

| Variable | Description |
|----------|-------------|
| `user` | Recordset of the current user (`res.users`) |
| `company_id` | ID of the user's active company |
| `company_ids` | IDs of all companies the user has access to |
| `time` | Python `time` module |

### `noupdate` Rules

```xml
<!-- Rules that MUST NOT be updated upon module reinstallation -->
<data noupdate="1">
    <record id="rule_sensitive_data" model="ir.rule">
        <!-- ... -->
    </record>
</data>
```

> **Best Practice**: Use `noupdate="1"` for security rules that an
> administrator might customize after installation.

---

## 4. HTTP Controllers

### Basic Controller

```python
from odoo import http
from odoo.http import request


class MyController(http.Controller):

    @http.route(
        "/my_module/api/records",
        type="json",
        auth="user",
        methods=["POST"],
    )
    def get_records(self, **kwargs):
        """Authenticated JSON endpoint."""
        records = request.env["my.model"].search([])
        return records.read(["name", "state"])

    @http.route(
        "/my_module/page",
        type="http",
        auth="public",
        website=True,
    )
    def my_page(self, **kwargs):
        """Public web page."""
        return request.render("my_module.my_template", {
            "records": request.env["my.model"].sudo().search([]),
        })
```

### Authentication Types

| `auth` | Description | When to use |
|--------|-------------|-------------|
| `user` | Authenticated user (session) | Internal APIs, backend actions |
| `public` | Access without login (portal/website) | Public website pages |
| `none` | No authentication verification | External webhooks (verify signature manually) |

### Controller Security

```python
# ✅ Correct: use sudo() only when necessary and with validated data
@http.route("/api/webhook", type="json", auth="none", csrf=False)
def webhook(self, **kwargs):
    # Verify signature/token before processing
    token = request.httprequest.headers.get("X-Webhook-Token")
    if not self._verify_token(token):
        return {"error": "Unauthorized"}, 401

    # Use sudo() only after verification
    request.env["my.model"].sudo().create(kwargs.get("data", {}))
    return {"status": "ok"}

# ❌ FORBIDDEN: sudo() without verification
@http.route("/api/data", type="json", auth="none")
def unsafe_endpoint(self, **kwargs):
    return request.env["res.partner"].sudo().search_read([])  # Data exposed!
```

### CSRF

- Endpoints with `type="http"` and `auth="user"` have CSRF protection enabled
  by default.
- For external webhooks, use `csrf=False` **only with manual verification of
  tokens/signatures**.

---

## 5. `sudo()` — Best Practices

```python
# ✅ Correct: sudo() scoped to the necessary operation
def action_send_email(self):
    template = self.env.ref("my_module.email_template").sudo()
    template.send_mail(self.id)

# ✅ Correct: sudo() with prior filtering
def _get_public_data(self):
    # Only expose safe fields
    return self.sudo().read(["name", "state"])

# ❌ FORBIDDEN: sudo() to bypass legitimate security
def action_delete_all(self):
    self.env["res.partner"].sudo().search([]).unlink()  # NEVER!
```

### General Rule

> Only use `sudo()` when business logic requires it (e.g., sending
> emails, creating cross-company records) and **never** to evade ACLs or
> record rules protecting sensitive data.

---

## 6. Security Checklist

- [ ] Does every new model have ACLs in `ir.model.access.csv`?
- [ ] Do models with sensitive data have `ir.rule` rules?
- [ ] Do multi-company models have the `company_id` rule?
- [ ] Do controllers use the appropriate `auth` (`user`, `public`, `none`)?
- [ ] Do `auth="none"` endpoints verify tokens/signatures manually?
- [ ] Is `sudo()` used only where strictly necessary?
- [ ] Are there no SQL queries using string concatenation? (see `python-conventions.md`)
- [ ] Are sensitive fields protected with `groups="base.group_system"`?
