<?xml version="1.0" encoding="utf-8"?>
<!-- View Inheritance Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  RULES FOR VIEW INHERITANCE:
  - inherit_id MUST point to the external ID of the original view.
  - Use <xpath> to target specific nodes.
  - Use position="after|before|inside|replace|attributes".
  - Prefer targeting by name="field_name" instead of string structure.
-->
<odoo>

    <record id="{{ module_name }}.view_{{ model_underscore }}_form_inherit" model="ir.ui.view">
        <field name="name">{{ target.model.name }}.form.inherit.{{ module_name }}</field>
        <field name="model">{{ target.model.name }}</field>
        <!-- External ID of the view you are inheriting -->
        <field name="inherit_id" ref="{{ target_module }}.{{ original_view_id }}"/>
        <field name="arch" type="xml">
            
            <!-- 1. Add a field AFTER an existing field -->
            <xpath expr="//field[@name='{{ existing_field_1 }}']" position="after">
                <field name="{{ new_field_1 }}"/>
            </xpath>

            <!-- 2. Add a field BEFORE an existing field -->
            <xpath expr="//field[@name='{{ existing_field_2 }}']" position="before">
                <field name="{{ new_field_2 }}"/>
            </xpath>

            <!-- 3. Add a completely new Notebook Page (Tab) -->
            <xpath expr="//notebook" position="inside">
                <page string="{{ New Tab Name }}" name="{{ page_name }}">
                    <group>
                        <field name="{{ new_field_3 }}"/>
                    </group>
                </page>
            </xpath>

            <!-- 4. Add a Button to the Header -->
            <xpath expr="//header" position="inside">
                <button name="action_{{ custom_action }}" type="object" 
                        string="{{ Action Name }}" class="btn-primary" 
                        invisible="state != 'draft'"/>
            </xpath>

            <!-- 5. Modify an existing field's attributes (e.g., make it readonly) -->
            <!-- Note: In Odoo 17+, use invisible="...", in 16 use attrs="{'invisible': ...}" -->
            <xpath expr="//field[@name='{{ existing_field_3 }}']" position="attributes">
                <attribute name="readonly">state != 'draft'</attribute>
                <!-- <attribute name="invisible">custom_boolean == False</attribute> -->
            </xpath>

        </field>
    </record>

    <!-- Example of inheriting a List/Tree view -->
    <record id="{{ module_name }}.view_{{ model_underscore }}_list_inherit" model="ir.ui.view">
        <field name="name">{{ target.model.name }}.list.inherit.{{ module_name }}</field>
        <field name="model">{{ target.model.name }}</field>
        <field name="inherit_id" ref="{{ target_module }}.{{ original_list_view_id }}"/>
        <field name="arch" type="xml">
            <!-- Add a column at the end of the list -->
            <!-- Odoo 18 uses <list>, older uses <tree> -->
            <xpath expr="//list | //tree" position="inside">
                <field name="{{ new_list_field }}" optional="show"/>
            </xpath>
        </field>
    </record>

    <!-- Example of inheriting a Search view -->
    <record id="{{ module_name }}.view_{{ model_underscore }}_search_inherit" model="ir.ui.view">
        <field name="name">{{ target.model.name }}.search.inherit.{{ module_name }}</field>
        <field name="model">{{ target.model.name }}</field>
        <field name="inherit_id" ref="{{ target_module }}.{{ original_search_view_id }}"/>
        <field name="arch" type="xml">
            <!-- Add a custom filter -->
            <xpath expr="//search" position="inside">
                <filter string="{{ My Filter }}" name="filter_{{ custom }}" 
                        domain="[('{{ custom_field }}', '=', True)]"/>
            </xpath>
        </field>
    </record>

</odoo>
