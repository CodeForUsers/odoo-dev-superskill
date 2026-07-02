# Security — Odoo OCA Development

Guía de seguridad para módulos Odoo (16.0–19.0). Las reglas de seguridad son
**idénticas en las 4 versiones** salvo diferencias menores indicadas.

---

## 1. Listas de Control de Acceso (ACL)

### Archivo `ir.model.access.csv`

Cada modelo nuevo **debe** tener al menos una línea de ACL. Sin ella, el modelo
es inaccesible y Odoo muestra un error de seguridad.

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_sale_order_user,sale.order.user,model_sale_order,sales_team.group_sale_salesman,1,1,1,0
access_sale_order_manager,sale.order.manager,model_sale_order,sales_team.group_sale_manager,1,1,1,1
access_sale_order_line_user,sale.order.line.user,model_sale_order_line,sales_team.group_sale_salesman,1,1,1,0
access_sale_order_line_manager,sale.order.line.manager,model_sale_order_line,sales_team.group_sale_manager,1,1,1,1
```

### Reglas de nomenclatura

| Campo | Patrón |
|-------|--------|
| `id` | `access_<modelo_con_underscores>_<grupo>` |
| `name` | `<modelo.con.puntos>.<grupo>` |
| `model_id:id` | `model_<modelo_con_underscores>` |
| `group_id:id` | `<modulo>.<xml_id_del_grupo>` |

### Checklist ACL

- [ ] ¿Cada modelo nuevo tiene al menos una ACL?
- [ ] ¿Los modelos TransientModel (wizards) tienen ACL para los grupos que los usan?
- [ ] ¿Los permisos de `unlink` están restringidos a managers/admins?
- [ ] ¿Se han definido ACLs para modelos abstractos heredados con `_name`?

---

## 2. Grupos de seguridad

### Definición de grupos

```xml
<!-- security/security.xml -->
<odoo>
    <data noupdate="0">

        <!-- Categoría (módulo) -->
        <record id="module_category_my_module" model="ir.module.category">
            <field name="name">My Module</field>
            <field name="sequence">100</field>
        </record>

        <!-- Grupo usuario -->
        <record id="group_my_module_user" model="res.groups">
            <field name="name">User</field>
            <field name="category_id" ref="module_category_my_module"/>
            <field name="implied_ids" eval="[(4, ref('base.group_user'))]"/>
        </record>

        <!-- Grupo manager (hereda de user) -->
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

### Jerarquía recomendada

```
base.group_user (Internal User)
  └── my_module.group_my_module_user
        └── my_module.group_my_module_manager
```

---

## 3. Reglas de registro (`ir.rule`)

Las reglas de registro filtran qué registros puede ver/editar cada usuario.

### Regla de multi-compañía (la más común)

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

### Regla por usuario

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

### Variables disponibles en `domain_force`

| Variable | Descripción |
|----------|-------------|
| `user` | Recordset del usuario actual (`res.users`) |
| `company_id` | ID de la compañía activa del usuario |
| `company_ids` | IDs de todas las compañías del usuario |
| `time` | Módulo `time` de Python |

### Reglas `noupdate`

```xml
<!-- Reglas que NO deben ser actualizadas al reinstalar el módulo -->
<data noupdate="1">
    <record id="rule_sensitive_data" model="ir.rule">
        <!-- ... -->
    </record>
</data>
```

> **Buena práctica**: usa `noupdate="1"` para reglas de seguridad que el
> administrador podría personalizar después de la instalación.

---

## 4. Controladores HTTP

### Controlador básico

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
        """Endpoint JSON autenticado."""
        records = request.env["my.model"].search([])
        return records.read(["name", "state"])

    @http.route(
        "/my_module/page",
        type="http",
        auth="public",
        website=True,
    )
    def my_page(self, **kwargs):
        """Página web pública."""
        return request.render("my_module.my_template", {
            "records": request.env["my.model"].sudo().search([]),
        })
```

### Tipos de autenticación

| `auth` | Descripción | Cuándo usar |
|--------|-------------|-------------|
| `user` | Usuario autenticado (sesión) | APIs internas, acciones del backend |
| `public` | Acceso sin login (portal/website) | Páginas públicas del website |
| `none` | Sin verificación de autenticación | Webhooks externos (verificar firma manualmente) |

### Seguridad en controladores

```python
# ✅ Correcto: usar sudo() solo cuando es necesario y con datos validados
@http.route("/api/webhook", type="json", auth="none", csrf=False)
def webhook(self, **kwargs):
    # Verificar firma/token antes de procesar
    token = request.httprequest.headers.get("X-Webhook-Token")
    if not self._verify_token(token):
        return {"error": "Unauthorized"}, 401

    # Usar sudo() solo después de verificar
    request.env["my.model"].sudo().create(kwargs.get("data", {}))
    return {"status": "ok"}

# ❌ PROHIBIDO: sudo() sin verificación
@http.route("/api/data", type="json", auth="none")
def unsafe_endpoint(self, **kwargs):
    return request.env["res.partner"].sudo().search_read([])  # ¡Datos expuestos!
```

### CSRF

- Los endpoints `type="http"` con `auth="user"` tienen protección CSRF activada
  por defecto.
- Para webhooks externos, usa `csrf=False` **solo con verificación manual de
  tokens/firmas**.

---

## 5. `sudo()` — Buenas prácticas

```python
# ✅ Correcto: sudo() acotado a la operación necesaria
def action_send_email(self):
    template = self.env.ref("my_module.email_template").sudo()
    template.send_mail(self.id)

# ✅ Correcto: sudo() con filtrado previo
def _get_public_data(self):
    # Solo exponer campos seguros
    return self.sudo().read(["name", "state"])

# ❌ PROHIBIDO: sudo() para saltarse seguridad legítima
def action_delete_all(self):
    self.env["res.partner"].sudo().search([]).unlink()  # ¡NUNCA!
```

### Regla general

> Solo usar `sudo()` cuando la lógica de negocio lo requiere (ej. enviar
> correos, crear registros cross-company) y **nunca** para evadir ACLs o
> reglas de registro que protegen datos sensibles.

---

## 6. Checklist de seguridad

- [ ] ¿Cada modelo nuevo tiene ACLs en `ir.model.access.csv`?
- [ ] ¿Los modelos con datos sensibles tienen reglas `ir.rule`?
- [ ] ¿Los modelos multi-compañía tienen la regla de `company_id`?
- [ ] ¿Los controladores usan el `auth` apropiado (`user`, `public`, `none`)?
- [ ] ¿Los endpoints `auth="none"` verifican tokens/firmas manualmente?
- [ ] ¿`sudo()` se usa solo donde es estrictamente necesario?
- [ ] ¿No hay SQL con concatenación de strings? (ver `python-conventions.md`)
- [ ] ¿Los campos sensibles están protegidos con `groups="base.group_system"`?
