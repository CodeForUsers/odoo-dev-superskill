<?xml version="1.0" encoding="UTF-8" ?>
<!-- Pivot View Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  KEY PIVOT CONCEPTS:
  - type="col":     column grouping dimension
  - type="row":     row grouping dimension
  - type="measure": the value field to aggregate
  - Odoo 19.0 supports GROUPING SETS for multi-level pivots (see note below)
-->
<odoo>

    <record id="{{ module_name }}.view_{{ model_underscore }}_pivot" model="ir.ui.view">
        <field name="name">{{ model.name }}.pivot</field>
        <field name="model">{{ model.name }}</field>
        <field name="arch" type="xml">
            <pivot string="{{ model_title }} Analysis" disable_linking="false">
                <!-- Row dimensions (left axis) -->
                <field name="{{ group_row_field }}" type="row"/>

                <!-- Column dimensions (top axis) -->
                <!-- <field name="{{ group_col_field }}" type="col"/> -->

                <!-- Measures (values to aggregate) -->
                <field name="{{ measure_field_1 }}" type="measure" string="{{ Measure 1 Label }}"/>
                <!-- <field name="{{ measure_field_2 }}" type="measure"/> -->
            </pivot>
        </field>
    </record>

    <!--
    ODOO 19.0 NOTE: GROUPING SETS
    ================================
    Odoo 19.0 supports multiple grouping levels via GROUPING SETS in SQL.
    The pivot view automatically uses this feature internally when multiple
    row/col dimensions are defined. No extra XML syntax is needed; just add
    multiple <field type="row"> elements:

    <field name="partner_id" type="row"/>
    <field name="date:month" type="row"/>

    For custom grouping sets at the ORM level, use _read_group() with the
    groupby argument as a list. See references/orm-changelog-16-19.md.
    -->

</odoo>
