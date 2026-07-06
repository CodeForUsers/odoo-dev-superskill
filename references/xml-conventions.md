# XML Conventions — Odoo OCA Development

XML conventions for views, data, and security in Odoo modules (16.0–19.0).

---

## 1. Conditional Rule: `<tree>` vs `<list>`

> **Explicit Rule**: if the target version is **16.0 or 17.0**, use `<tree>`.
> If it is **18.0 or 19.0**, use `<list>`.

### Side-by-side Example

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

> **Note on the view `id`**: in 18.0+ it is recommended to change the `_tree` suffix
> to `_list` in view IDs to maintain consistency, although
> Odoo does not technically require it.

---

## 2. Migrating from `<tree>` to `<list>` (manual)

When migrating a module from 16.0/17.0 to 18.0/19.0, follow these steps:

### Step 1: Replace tags

Replace `<tree` with `<list` and `</tree>` with `</list>` in all XML files.

### Step 2: Verify attributes (CRITICAL)

Make sure these attributes are kept **inside the `<list>` tag**:
- `editable="bottom"` or `editable="top"`
- `create="true"` or `create="false"`
- `delete="true"` or `delete="false"`
- `default_order="field [asc|desc]"`
- `decoration-*` (e.g. `decoration-danger="state == 'cancel'"`)
- `multi_edit="1"`

```xml
<!-- ❌ Common bug after upgrade_code: lost attributes -->
<list string="Orders">
    <field name="name"/>
    <field name="state"/>
</list>
<!-- Where did editable, create, delete go? -->

<!-- ✅ Correct: all attributes migrated -->
<list string="Orders" editable="bottom" create="true" delete="false"
      decoration-danger="state == 'cancel'">
    <field name="name"/>
    <field name="state"/>
</list>
```

### Step 3: Update window actions

```xml
<!-- If the action referenced view_mode with "tree", change it to "list" -->

<!-- ❌ May fail in 18.0 -->
<field name="view_mode">tree,form</field>

<!-- ✅ Correct in 18.0/19.0 -->
<field name="view_mode">list,form</field>
```

### Step 4: Update xpath inheritances

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

### ⚠️ Warning about `upgrade_code`

The script `odoo-bin upgrade_code --addons-path=<path>` can do the replacement
automatically, **but it has a known bug**: it might place attributes like
`create`, `delete`, `editable`, `default_order` outside the `<list>` tag or
lose them entirely.

**Always manually review the result** after running `upgrade_code`.

---

## 3. Indentation Conventions

- **4 spaces** indentation (never tabs).
- Long attributes on separate, aligned lines:

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

## 4. `xpath` Conventions

### Available Positions

| Position | Effect |
|----------|--------|
| `inside` | Adds inside, at the end |
| `before` | Adds just before |
| `after` | Adds just after |
| `replace` | Replaces the entire node |
| `attributes` | Modifies node attributes |

### Examples

```xml
<!-- Add field after another -->
<xpath expr="//field[@name='partner_id']" position="after">
    <field name="my_custom_field"/>
</xpath>

<!-- Replace a field -->
<xpath expr="//field[@name='old_field']" position="replace">
    <field name="new_field"/>
</xpath>

<!-- Modify attributes -->
<xpath expr="//field[@name='name']" position="attributes">
    <attribute name="required">1</attribute>
    <attribute name="invisible">state != 'draft'</attribute>
</xpath>

<!-- Add button in the header -->
<xpath expr="//header" position="inside">
    <button name="action_custom"
            type="object"
            string="Custom Action"
            invisible="state != 'draft'"/>
</xpath>
```

### Best Practices in xpath

- Prefer selectors by field `name`: `//field[@name='partner_id']`.
- Avoid fragile positional selectors: `//group[2]/field[3]`.
- If the node has no name, use descriptive classes or IDs.

---

## 5. XML ID Naming Conventions

### Standard Pattern

```text
<module_name>.<type>_<model_with_underscores>_<variant>
```

### Examples

```xml
<!-- Views -->
<record id="my_module.view_sale_order_form" model="ir.ui.view">
<record id="my_module.view_sale_order_tree" model="ir.ui.view">   <!-- 16/17 -->
<record id="my_module.view_sale_order_list" model="ir.ui.view">   <!-- 18/19 -->
<record id="my_module.view_sale_order_search" model="ir.ui.view">
<record id="my_module.view_sale_order_kanban" model="ir.ui.view">
<record id="my_module.view_sale_order_pivot" model="ir.ui.view">

<!-- Actions -->
<record id="my_module.action_sale_order" model="ir.actions.act_window">

<!-- Menus -->
<menuitem id="my_module.menu_sale_order_root" .../>
<menuitem id="my_module.menu_sale_order_list" .../>

<!-- Data -->
<record id="my_module.sale_order_template_basic" model="sale.order.template">

<!-- Security -->
<record id="my_module.group_sale_manager" model="res.groups">
<record id="my_module.rule_sale_order_company" model="ir.rule">
```

---

## 6. `invisible` Attribute (change in 16.0+)

Starting from Odoo 16.0, the `invisible` attribute accepts domain expressions
directly (without `attrs`):

```xml
<!-- ❌ Old (pre-16.0): use attrs -->
<field name="my_field" attrs="{'invisible': [('state', '!=', 'draft')]}"/>

<!-- ✅ Correct (16.0+): direct expression -->
<field name="my_field" invisible="state != 'draft'"/>

<!-- ✅ Correct: complex expressions -->
<field name="my_field" invisible="state != 'draft' or not partner_id"/>
```

> **Applies to all 4 versions** (16, 17, 18, 19). In 16.0 both syntaxes work;
> in 17.0+ the `attrs` form is deprecated.

---

## 7. XML File Structure

```text
views/
├── sale_order_views.xml        # All sale.order views
├── res_partner_views.xml       # res.partner view inheritance
├── menuitems.xml               # Menus
└── templates.xml               # QWeb templates (if applicable)

security/
├── ir.model.access.csv         # ACLs
└── security.xml                # Groups and record rules

data/
├── data.xml                    # Initial data
└── cron.xml                    # Scheduled actions
```
