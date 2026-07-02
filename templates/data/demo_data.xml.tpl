<?xml version="1.0" encoding="UTF-8" ?>
<!-- Demo Data Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  Demo data is loaded ONLY when the database is created with demo data enabled.
  It should represent a realistic but fictional dataset.

  RULES:
  - Never reference user-specific data (e.g., specific companies/users may not exist)
  - Use base.main_company, base.user_admin, base.res_partner_* for safe references
  - Keep demo data simple: 3–10 records is usually enough
  - Always use noupdate="1" for demo data
-->
<odoo>
    <data noupdate="1">

        <!-- ── Demo records ───────────────────────────────────────────────── -->
        <record id="{{ module_name }}.demo_{{ model_underscore }}_1" model="{{ model.name }}">
            <field name="name">Demo Record 1</field>
            <field name="company_id" ref="base.main_company"/>
            <field name="state">draft</field>
            <!-- Add more fields as needed -->
        </record>

        <record id="{{ module_name }}.demo_{{ model_underscore }}_2" model="{{ model.name }}">
            <field name="name">Demo Record 2</field>
            <field name="company_id" ref="base.main_company"/>
            <field name="state">confirmed</field>
        </record>

        <record id="{{ module_name }}.demo_{{ model_underscore }}_3" model="{{ model.name }}">
            <field name="name">Demo Record 3</field>
            <field name="company_id" ref="base.main_company"/>
            <field name="state">done</field>
        </record>

    </data>
</odoo>
