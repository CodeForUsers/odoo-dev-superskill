<?xml version="1.0" encoding="UTF-8" ?>
<!-- Security Template — Groups & Record Rules — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  noupdate="0": Groups reset on module update (recommended for groups)
  noupdate="1": Rules are NOT reset on update (lets admins customize them)

  GROUP HIERARCHY (recommended pattern):
    base.group_user (Internal User)
      └── {{ module_name }}.group_{{ module_name }}_user
            └── {{ module_name }}.group_{{ module_name }}_manager

  RECORD RULE VARIABLES available in domain_force:
    user          → res.users recordset of current user
    company_id    → ID of the active company
    company_ids   → IDs of all companies the user belongs to
    time          → Python time module
-->
<odoo>

    <!-- ──────────────────────────────────────────────────────────────────── -->
    <!-- GROUPS                                                               -->
    <!-- ──────────────────────────────────────────────────────────────────── -->
    <data noupdate="0">

        <!-- Module category (shown in Settings → Users → Access Rights) -->
        <record id="{{ module_name }}.module_category_{{ module_name }}" model="ir.module.category">
            <field name="name">{{ module_title }}</field>
            <field name="description">{{ module_description }}</field>
            <field name="sequence">100</field>
        </record>

        <!-- User group: can read/write/create but NOT delete -->
        <record id="{{ module_name }}.group_{{ module_name }}_user" model="res.groups">
            <field name="name">User</field>
            <field name="category_id" ref="{{ module_name }}.module_category_{{ module_name }}"/>
            <field name="implied_ids" eval="[(4, ref('base.group_user'))]"/>
        </record>

        <!-- Manager group: full permissions, inherits from User -->
        <record id="{{ module_name }}.group_{{ module_name }}_manager" model="res.groups">
            <field name="name">Manager</field>
            <field name="category_id" ref="{{ module_name }}.module_category_{{ module_name }}"/>
            <field name="implied_ids" eval="[(4, ref('{{ module_name }}.group_{{ module_name }}_user'))]"/>
            <!-- Auto-assign admin users to manager group -->
            <field name="users" eval="[(4, ref('base.user_root')), (4, ref('base.user_admin'))]"/>
        </record>

    </data>

    <!-- ──────────────────────────────────────────────────────────────────── -->
    <!-- RECORD RULES (ir.rule)                                               -->
    <!-- noupdate="1" so admins can customize rules post-install              -->
    <!-- ──────────────────────────────────────────────────────────────────── -->
    <data noupdate="1">

        <!-- Multi-company rule: users only see records from their company/ies -->
        <record id="{{ module_name }}.rule_{{ model_underscore }}_company" model="ir.rule">
            <field name="name">{{ model_title }}: multi-company</field>
            <field name="model_id" ref="{{ module_name }}.model_{{ model_underscore }}"/>
            <field name="domain_force">
                ['|',
                 ('company_id', '=', False),
                 ('company_id', 'in', company_ids)]
            </field>
        </record>

        <!-- User rule: users only see their OWN records (restrict User group) -->
        <record id="{{ module_name }}.rule_{{ model_underscore }}_user_own" model="ir.rule">
            <field name="name">{{ model_title }}: own records (Users)</field>
            <field name="model_id" ref="{{ module_name }}.model_{{ model_underscore }}"/>
            <field name="groups" eval="[(4, ref('{{ module_name }}.group_{{ module_name }}_user'))]"/>
            <field name="domain_force">[('user_id', '=', user.id)]</field>
            <field name="perm_read" eval="True"/>
            <field name="perm_write" eval="True"/>
            <field name="perm_create" eval="True"/>
            <field name="perm_unlink" eval="False"/>
        </record>

        <!-- Manager rule: managers see ALL records (no filter) -->
        <record id="{{ module_name }}.rule_{{ model_underscore }}_manager_all" model="ir.rule">
            <field name="name">{{ model_title }}: all records (Managers)</field>
            <field name="model_id" ref="{{ module_name }}.model_{{ model_underscore }}"/>
            <field name="groups" eval="[(4, ref('{{ module_name }}.group_{{ module_name }}_manager'))]"/>
            <field name="domain_force">[(1, '=', 1)]</field>
        </record>

    </data>

</odoo>
