<?xml version="1.0" encoding="utf-8"?>
<!-- Multi-Company Record Rules (ir.rule) Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  RULES FOR MULTI-COMPANY:
  - If a model has a `company_id` field, it almost certainly needs a rule
    so users in Company A cannot see records of Company B.
  - The standard domain for this is:
    ['|', ('company_id', '=', False), ('company_id', 'in', company_ids)]
  - `company_ids` is an evaluated variable containing the IDs of the companies
    the current user is operating in.
-->
<odoo>
    <data noupdate="1">

        <!-- Rule for Multi-Company visibility -->
        <record id="{{ module_name }}.rule_{{ model_underscore }}_company" model="ir.rule">
            <field name="name">{{ Model Title }} Multi-Company</field>
            <!-- Reference the model -->
            <field name="model_id" ref="{{ module_name }}.model_{{ model_underscore }}"/>
            <!-- Domain: Allow records with no company (shared) or matching user's active companies -->
            <field name="domain_force">
                ['|', ('company_id', '=', False), ('company_id', 'in', company_ids)]
            </field>
            <!-- Optional: Apply only to specific groups. 
                 If left empty (no groups), it applies globally. -->
            <field name="groups" eval="[(4, ref('base.group_user'))]"/>
            
            <!-- Permissions: Usually restrict everything -->
            <field name="perm_read" eval="True"/>
            <field name="perm_write" eval="True"/>
            <field name="perm_create" eval="True"/>
            <field name="perm_unlink" eval="True"/>
        </record>

    </data>
</odoo>

<!--
PYTHON REMINDER:
In your model ({{ model_underscore }}.py), ensure the company_id field is set up correctly:

class {{ ModelClassName }}(models.Model):
    _name = '{{ model.name }}'
    
    company_id = fields.Many2one(
        'res.company', 
        string='Company', 
        default=lambda self: self.env.company, 
        required=True, 
        index=True
    )
-->
