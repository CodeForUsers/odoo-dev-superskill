# XML Conventions — Odoo OCA Development

Convenciones de XML para vistas, datos y seguridad en módulos Odoo (16.0–19.0).

---

## 1. Regla condicional: `<tree>` vs `<list>`

> **Regla explícita**: si la versión objetivo es **16.0 o 17.0**, usar `<tree>`.
> Si es **18.0 o 19.0**, usar `<list>`.

### Ejemplo lado a lado

```xml
<!-- ===== Odoo 16.0 / 17.0 ===== -->
<record id="my_module.view_partner_tree" model="ir.ui.view">
    <field name="name">res.partner.tree</field>
    <field name="model">res.partner</field>
    <field name="arch" type="xml">
        <tree string="Partners" editable="bottom" create="true" delete="true" default_order="name">
            <field name="name"/>
            <field name="email"/>
            <field name="phone"/>
            <field name="company_id"/>
        </tree>
    </field>
</record>

<!-- ===== Odoo 18.0 / 19.0 ===== -->
<record id="my_module.view_partner_list" model="ir.ui.view">
    <field name="name">res.partner.list</field>
    <field name="model">res.partner</field>
    <field name="arch" type="xml">
        <list string="Partners" editable="bottom" create="true" delete="true" default_order="name">
            <field name="name"/>
            <field name="email"/>
            <field name="phone"/>
            <field name="company_id"/>
        </list>
    </field>
</record>
```

> **Nota sobre el `id` de la vista**: en 18.0+ se recomienda cambiar el sufijo
> `_tree` por `_list` en los IDs de las vistas para mantener coherencia, aunque
> Odoo no lo exige técnicamente.

---

## 2. Migración de `<tree>` a `<list>` (manual)

Cuando migres un módulo de 16.0/17.0 a 18.0/19.0, sigue estos pasos:

### Paso 1: Reemplazar tags

Reemplaza `<tree` por `<list` y `</tree>` por `</list>` en todos los archivos XML.

### Paso 2: Verificar atributos (CRÍTICO)

Asegúrate de que estos atributos se mantengan **dentro del tag `<list>`**:
- `editable="bottom"` o `editable="top"`
- `create="true"` o `create="false"`
- `delete="true"` o `delete="false"`
- `default_order="campo [asc|desc]"`
- `decoration-*` (ej. `decoration-danger="state == 'cancel'"`)
- `multi_edit="1"`

```xml
<!-- ❌ Bug común tras upgrade_code: atributos perdidos -->
<list string="Orders">
    <field name="name"/>
    <field name="state"/>
</list>
<!-- ¿Dónde quedaron editable, create, delete? -->

<!-- ✅ Correcto: todos los atributos migrados -->
<list string="Orders" editable="bottom" create="true" delete="false"
      decoration-danger="state == 'cancel'">
    <field name="name"/>
    <field name="state"/>
</list>
```

### Paso 3: Actualizar acciones de ventana

```xml
<!-- Si la acción referenciaba view_mode con "tree", cambiar a "list" -->

<!-- ❌ Puede fallar en 18.0 -->
<field name="view_mode">tree,form</field>

<!-- ✅ Correcto en 18.0/19.0 -->
<field name="view_mode">list,form</field>
```

### Paso 4: Actualizar herencias con xpath

```xml
<!-- 16.0/17.0 -->
<xpath expr="//tree" position="inside">
    <field name="my_field"/>
</xpath>

<!-- 18.0/19.0 -->
<xpath expr="//list" position="inside">
    <field name="my_field"/>
</xpath>
```

### ⚠️ Advertencia sobre `upgrade_code`

El script `odoo-bin upgrade_code --addons-path=<ruta>` puede hacer el reemplazo
automáticamente, **pero tiene un bug conocido**: puede colocar atributos como
`create`, `delete`, `editable`, `default_order` fuera del tag `<list>` o
perderlos por completo.

**Siempre revisa manualmente el resultado** después de ejecutar `upgrade_code`.

---

## 3. Convenciones de indentación

- **4 espacios** de indentación (nunca tabuladores).
- Atributos largos en líneas separadas, alineados:

```xml
<record id="my_module.view_order_form"
        model="ir.ui.view">
    <field name="name">sale.order.form</field>
    <field name="model">sale.order</field>
    <field name="arch" type="xml">
        <form string="Sale Order">
            <header>
                <button name="action_confirm"
                        type="object"
                        string="Confirm"
                        class="btn-primary"
                        invisible="state != 'draft'"/>
            </header>
            <sheet>
                <group>
                    <group>
                        <field name="partner_id"/>
                        <field name="date_order"/>
                    </group>
                    <group>
                        <field name="state"/>
                        <field name="amount_total"/>
                    </group>
                </group>
            </sheet>
        </form>
    </field>
</record>
```

---

## 4. Convenciones de `xpath`

### Posiciones disponibles

| Posición | Efecto |
|----------|--------|
| `inside` | Añade dentro, al final |
| `before` | Añade justo antes |
| `after` | Añade justo después |
| `replace` | Reemplaza el nodo completo |
| `attributes` | Modifica atributos del nodo |

### Ejemplos

```xml
<!-- Añadir campo después de otro -->
<xpath expr="//field[@name='partner_id']" position="after">
    <field name="my_custom_field"/>
</xpath>

<!-- Reemplazar un campo -->
<xpath expr="//field[@name='old_field']" position="replace">
    <field name="new_field"/>
</xpath>

<!-- Modificar atributos -->
<xpath expr="//field[@name='name']" position="attributes">
    <attribute name="required">1</attribute>
    <attribute name="invisible">state != 'draft'</attribute>
</xpath>

<!-- Añadir botón en el header -->
<xpath expr="//header" position="inside">
    <button name="action_custom"
            type="object"
            string="Custom Action"
            invisible="state != 'draft'"/>
</xpath>
```

### Buenas prácticas en xpath

- Prefiere selectores por `name` de campo: `//field[@name='partner_id']`.
- Evita selectores posicionales frágiles: `//group[2]/field[3]`.
- Si el nodo no tiene nombre, usa clases o IDs descriptivos.

---

## 5. Nomenclatura de IDs XML

### Patrón estándar

```
<nombre_módulo>.<tipo>_<modelo_con_underscores>_<variante>
```

### Ejemplos

```xml
<!-- Vistas -->
<record id="my_module.view_sale_order_form" model="ir.ui.view">
<record id="my_module.view_sale_order_tree" model="ir.ui.view">   <!-- 16/17 -->
<record id="my_module.view_sale_order_list" model="ir.ui.view">   <!-- 18/19 -->
<record id="my_module.view_sale_order_search" model="ir.ui.view">
<record id="my_module.view_sale_order_kanban" model="ir.ui.view">
<record id="my_module.view_sale_order_pivot" model="ir.ui.view">

<!-- Acciones -->
<record id="my_module.action_sale_order" model="ir.actions.act_window">

<!-- Menús -->
<menuitem id="my_module.menu_sale_order_root" .../>
<menuitem id="my_module.menu_sale_order_list" .../>

<!-- Datos -->
<record id="my_module.sale_order_template_basic" model="sale.order.template">

<!-- Seguridad -->
<record id="my_module.group_sale_manager" model="res.groups">
<record id="my_module.rule_sale_order_company" model="ir.rule">
```

---

## 6. Atributo `invisible` (cambio en 16.0+)

A partir de Odoo 16.0, el atributo `invisible` acepta expresiones de dominio
directamente (sin `attrs`):

```xml
<!-- ❌ Antiguo (pre-16.0): usar attrs -->
<field name="my_field" attrs="{'invisible': [('state', '!=', 'draft')]}"/>

<!-- ✅ Correcto (16.0+): expresión directa -->
<field name="my_field" invisible="state != 'draft'"/>

<!-- ✅ Correcto: expresiones complejas -->
<field name="my_field" invisible="state != 'draft' or not partner_id"/>
```

> **Aplica a las 4 versiones** (16, 17, 18, 19). En 16.0 ambas sintaxis funcionan;
> en 17.0+ la forma con `attrs` está deprecada.

---

## 7. Estructura de archivos XML

```
views/
├── sale_order_views.xml        # Todas las vistas de sale.order
├── res_partner_views.xml       # Herencia de vistas de res.partner
├── menuitems.xml               # Menús
└── templates.xml               # Templates QWeb (si aplica)

security/
├── ir.model.access.csv         # ACLs
└── security.xml                # Grupos y reglas de registro

data/
├── data.xml                    # Datos iniciales
└── cron.xml                    # Acciones programadas
```
