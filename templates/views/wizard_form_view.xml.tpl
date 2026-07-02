<?xml version="1.0" encoding="UTF-8" ?>
<!-- Wizard Form View Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  WIZARD FORM VIEW KEY POINTS:
  - No header / statusbar: wizards use the dialog footer for buttons
  - target="new" in the action launches this as a modal dialog
  - Buttons use special_field="action_confirm" etc. for dialog management
  - class="btn-primary" marks the main action button
  - class="btn-secondary" marks the cancel/close button
-->
<odoo>

    <!-- Wizard Form View -->
    <record id="{{ module_name }}.view_{{ wizard_suffix }}_wizard_form" model="ir.ui.view">
        <field name="name">{{ module_name }}.{{ wizard_suffix }}.wizard.form</field>
        <field name="model">{{ module_name }}.{{ wizard_suffix }}.wizard</field>
        <field name="arch" type="xml">
            <form string="{{ wizard_title }}">
                <sheet>
                    <group>
                        <group string="Records to Process">
                            <field name="{{ origin_field }}_ids"
                                   nolabel="1"
                                   widget="many2many_tags"/>
                        </group>
                        <group string="Parameters">
                            <field name="date"/>
                            <!-- Add more wizard fields here -->
                        </group>
                    </group>

                    <group string="Additional Information" invisible="not reason">
                        <field name="reason"
                               nolabel="1"
                               placeholder="Optional reason or notes..."/>
                    </group>
                </sheet>

                <!-- Dialog footer with action buttons -->
                <footer>
                    <button name="action_confirm"
                            type="object"
                            string="Confirm"
                            class="btn-primary"
                            data-hotkey="v"/>
                    <button string="Cancel"
                            class="btn-secondary"
                            special="cancel"/>
                </footer>
            </form>
        </field>
    </record>

    <!-- Action to open the wizard as a dialog (target="new") -->
    <record id="{{ module_name }}.action_{{ wizard_suffix }}_wizard" model="ir.actions.act_window">
        <field name="name">{{ wizard_title }}</field>
        <field name="res_model">{{ module_name }}.{{ wizard_suffix }}.wizard</field>
        <field name="view_mode">form</field>
        <field name="view_id" ref="{{ module_name }}.view_{{ wizard_suffix }}_wizard_form"/>
        <field name="target">new</field>
        <field name="binding_model_id" ref="{{ module_name }}.model_{{ origin_model_underscore }}"/>
        <field name="binding_view_types">list,form</field>
        <!-- binding_model_id adds this wizard to the Action menu of {{ origin_model }} -->
    </record>

</odoo>
