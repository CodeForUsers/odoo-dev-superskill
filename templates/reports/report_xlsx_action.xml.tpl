<?xml version="1.0" encoding="UTF-8" ?>
<!-- Excel Report Action Template (report_xlsx) — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  REQUIRES: The 'report_xlsx' module from OCA (https://github.com/OCA/reporting-engine)
  Add "report_xlsx" to the "depends" list in __manifest__.py.
-->
<odoo>

    <!-- ── Report Action ─────────────────────────────────────────────────── -->
    <record id="{{ module_name }}.action_report_{{ report_name }}_xlsx" model="ir.actions.report">
        <field name="name">{{ Report Label }} (Excel)</field>
        <field name="model">{{ model.name }}</field>
        <!-- The critical part: report_type must be xlsx -->
        <field name="report_type">xlsx</field>
        <!-- The report_name must match the technical name registered in the Python model -->
        <field name="report_name">{{ module_name }}.report_{{ report_name }}_xlsx</field>
        <field name="report_file">{{ module_name }}.report_{{ report_name }}_xlsx</field>
        <field name="binding_model_id" ref="{{ module_name }}.model_{{ model_underscore }}"/>
        <field name="binding_type">report</field>
        <!-- Excel filename expression (Python) -->
        <field name="print_report_name">
            (object.name or '{{ report_name }}').replace('/', '_') + '.xlsx'
        </field>
    </record>

</odoo>
