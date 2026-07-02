<?xml version="1.0" encoding="UTF-8" ?>
<!-- Initial Data Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  WHEN TO USE noupdate:
    noupdate="0": Records are recreated/updated on every module update (default).
                  Use for configuration data that MUST match the code.
    noupdate="1": Records are only created on FIRST install, not on updates.
                  Use for data the admin may want to customize after install.

  RECORD ID NAMING:
    Always prefix with your module name: {{ module_name }}.xml_id
    This avoids collisions with other modules.

  COMMON USE CASES for data.xml:
    - Default stages / states / configurations
    - Email templates (mail.template)
    - Server actions (ir.actions.server)
    - Paper formats (report.paperformat)
    - ir.config_parameter defaults
-->
<odoo>
    <data noupdate="0">

        <!-- ── Configuration parameters ──────────────────────────────────── -->
        <record id="{{ module_name }}.param_{{ param_name }}" model="ir.config_parameter">
            <field name="key">{{ module_name }}.{{ param_name }}</field>
            <field name="value">{{ param_default_value }}</field>
        </record>

        <!-- ── Default stages / selection data ───────────────────────────── -->
        <!--
        <record id="{{ module_name }}.{{ stage_name }}_stage" model="{{ stage_model }}">
            <field name="name">{{ Stage Label }}</field>
            <field name="sequence">10</field>
            <field name="is_default" eval="True"/>
        </record>
        -->

    </data>
    <data noupdate="1">

        <!-- ── Email template ─────────────────────────────────────────────── -->
        <record id="{{ module_name }}.email_template_{{ event_name }}" model="mail.template">
            <field name="name">{{ Module Title }}: {{ Event Label }}</field>
            <field name="model_id" ref="{{ module_name }}.model_{{ model_underscore }}"/>
            <field name="subject">{{ email_subject }}</field>
            <field name="body_html"><![CDATA[
<p>Dear <t t-out="object.partner_id.name"/>,</p>
<p>{{ email_body_placeholder }}</p>
<p>Best regards,<br/>{{ company_name }}</p>
            ]]></field>
            <field name="auto_delete" eval="True"/>
        </record>

        <!-- ── Server action ─────────────────────────────────────────────── -->
        <!--
        <record id="{{ module_name }}.action_server_{{ action_name }}" model="ir.actions.server">
            <field name="name">{{ Action Label }}</field>
            <field name="model_id" ref="{{ module_name }}.model_{{ model_underscore }}"/>
            <field name="binding_model_id" ref="{{ module_name }}.model_{{ model_underscore }}"/>
            <field name="binding_view_types">list</field>
            <field name="state">code</field>
            <field name="code">records.action_{{ action_name }}()</field>
        </record>
        -->

    </data>
</odoo>
