<?xml version="1.0" encoding="UTF-8" ?>
<!-- Calendar View Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  KEY CALENDAR CONCEPTS:
  - date_start: field that marks the event start (required)
  - date_stop:  field that marks the event end (optional; makes event span multiple days)
  - date_delay: duration in hours (alternative to date_stop)
  - color:      field used to color events (usually Many2one or Selection)
  - mode:       default view: "day", "week", "month" (default), "year"
  - quick_add:  if True, shows a quick-create form on click
  - filters:    defines which many2one fields can be used as sidebar filters
-->
<odoo>

    <record id="{{ module_name }}.view_{{ model_underscore }}_calendar" model="ir.ui.view">
        <field name="name">{{ model.name }}.calendar</field>
        <field name="model">{{ model.name }}</field>
        <field name="arch" type="xml">
            <calendar
                string="{{ model_title }} Calendar"
                date_start="{{ date_start_field }}"
                date_stop="{{ date_stop_field }}"
                color="{{ color_field }}"
                mode="month"
                quick_add="false"
                event_open_popup="true">

                <!-- Fields shown as text on each calendar event card -->
                <field name="name"/>
                <field name="{{ user_or_partner_field }}" filters="1" avatar_field="avatar_128"/>
                <field name="state"/>

                <!--
                OPTIONAL: date_delay instead of date_stop:
                    date_delay="{{ duration_field }}"
                    This field should be a Float representing hours.

                OPTIONAL: show all-day events:
                    all_day="{{ all_day_boolean_field }}"
                -->
            </calendar>
        </field>
    </record>

</odoo>
