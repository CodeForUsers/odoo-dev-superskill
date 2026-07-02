<?xml version="1.0" encoding="UTF-8" ?>
<!-- Graph View Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  KEY GRAPH CONCEPTS:
  - type="col":     X-axis grouping dimension
  - type="row":     Series grouping dimension (creates multiple lines/bars)
  - type="measure": Y-axis value to aggregate
  - graph_type:     "bar" (default), "line", or "pie"
-->
<odoo>

    <record id="{{ module_name }}.view_{{ model_underscore }}_graph" model="ir.ui.view">
        <field name="name">{{ model.name }}.graph</field>
        <field name="model">{{ model.name }}</field>
        <field name="arch" type="xml">
            <graph string="{{ model_title }} Graph"
                   type="bar"
                   stacked="false"
                   disable_linking="false">

                <!-- X-axis: date or category field -->
                <field name="{{ date_or_category_field }}" type="col"/>

                <!-- Series (one line/bar per value): comment out if not needed -->
                <!-- <field name="{{ series_field }}" type="row"/> -->

                <!-- Measure (Y-axis value) -->
                <field name="{{ measure_field }}" type="measure" string="{{ Measure Label }}"/>

            </graph>
        </field>
    </record>

    <!--
    GRAPH TYPES:
      type="bar"   → Vertical bar chart (default, best for comparisons)
      type="line"  → Line chart (best for time series)
      type="pie"   → Pie chart (best for proportions; ignores X-axis field)

    COMMON DATE FIELDS WITH GROUPING:
      <field name="date_order:month" type="col"/>
      <field name="date_order:week"  type="col"/>
      <field name="date_order:year"  type="col"/>

    ADDING A SECOND MEASURE (shown in the measure selector, not default):
      <field name="{{ other_measure_field }}" type="measure" string="Label" invisible="1"/>
    -->

</odoo>
