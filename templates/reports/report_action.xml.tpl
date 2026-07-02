<?xml version="1.0" encoding="UTF-8" ?>
<!-- Report Action Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  REPORT ACTION FIELDS:
  - name:           Label shown in the Print menu
  - model:          The model this report is for
  - report_type:    "qweb-pdf" (PDF), "qweb-html" (HTML preview)
  - report_name:    Technical name of the QWeb template (must match t-name in template file)
  - binding_model_id: Adds the report to the Print button of this model's list/form
  - paperformat_id: Reference to a report.paperformat record (A4, Letter, etc.)
  - print_report_name: Python expression to generate the filename
-->
<odoo>

    <!-- ── Paper Format (optional: only define if not using standard A4) ── -->
    <!--
    <record id="{{ module_name }}.paperformat_{{ report_name }}" model="report.paperformat">
        <field name="name">{{ Module Title }} Paper Format</field>
        <field name="default" eval="False"/>
        <field name="format">A4</field>
        <field name="orientation">Portrait</field>
        <field name="margin_top">40</field>
        <field name="margin_bottom">28</field>
        <field name="margin_left">7</field>
        <field name="margin_right">7</field>
        <field name="header_line" eval="False"/>
        <field name="header_spacing">35</field>
        <field name="dpi">90</field>
    </record>
    -->

    <!-- ── Report Action ─────────────────────────────────────────────────── -->
    <record id="{{ module_name }}.action_report_{{ report_name }}" model="ir.actions.report">
        <field name="name">{{ Report Label }}</field>
        <field name="model">{{ model.name }}</field>
        <field name="report_type">qweb-pdf</field>
        <!-- Must match the t-name in report_qweb_template.xml.tpl -->
        <field name="report_name">{{ module_name }}.report_{{ report_name }}_document</field>
        <field name="report_file">{{ module_name }}.report_{{ report_name }}_document</field>
        <field name="binding_model_id" ref="{{ module_name }}.model_{{ model_underscore }}"/>
        <field name="binding_type">report</field>
        <!-- PDF filename expression (Python) -->
        <field name="print_report_name">
            (object.name or '{{ report_name }}').replace('/', '_')
        </field>
        <!-- Uncomment to use a custom paper format:
        <field name="paperformat_id" ref="{{ module_name }}.paperformat_{{ report_name }}"/>
        -->
    </record>

</odoo>
