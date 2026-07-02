<?xml version="1.0" encoding="UTF-8" ?>
<!-- Tree (List) View Template for Odoo 16.0 / 17.0 -->
<!-- In these versions, use <tree> as the root tag for list views. -->
<!-- Replace all {{ placeholders }} with actual values. -->
<odoo>

    <!-- Tree View -->
    <record id="{{ module_name }}.view_{{ model_underscore }}_tree" model="ir.ui.view">
        <field name="name">{{ model.name }}.tree</field>
        <field name="model">{{ model.name }}</field>
        <field name="arch" type="xml">
            <tree string="{{ model_title }}"
                  editable="bottom"
                  decoration-info="state == 'draft'"
                  decoration-success="state == 'confirmed'"
                  decoration-muted="state == 'cancelled'">
                <field name="sequence" widget="handle"/>
                <field name="name"/>
                <!-- Add more fields here -->
                <field name="state"
                       decoration-info="state == 'draft'"
                       decoration-success="state == 'confirmed'"
                       decoration-danger="state == 'cancelled'"
                       widget="badge"/>
            </tree>
        </field>
    </record>

    <!-- Form View -->
    <record id="{{ module_name }}.view_{{ model_underscore }}_form" model="ir.ui.view">
        <field name="name">{{ model.name }}.form</field>
        <field name="model">{{ model.name }}</field>
        <field name="arch" type="xml">
            <form string="{{ model_title }}">
                <header>
                    <button name="action_confirm"
                            type="object"
                            string="Confirm"
                            class="btn-primary"
                            invisible="state != 'draft'"/>
                    <button name="action_done"
                            type="object"
                            string="Done"
                            invisible="state != 'confirmed'"/>
                    <button name="action_cancel"
                            type="object"
                            string="Cancel"
                            invisible="state in ('done', 'cancelled')"/>
                    <button name="action_reset_to_draft"
                            type="object"
                            string="Reset to Draft"
                            invisible="state not in ('cancelled',)"/>
                    <field name="state" widget="statusbar"
                           statusbar_visible="draft,confirmed,done"/>
                </header>
                <sheet>
                    <div class="oe_button_box" name="button_box">
                        <!-- Smart buttons go here -->
                    </div>
                    <div class="oe_title">
                        <h1>
                            <field name="name" placeholder="Name..."/>
                        </h1>
                    </div>
                    <group>
                        <group>
                            <!-- Left column fields -->
                            <field name="company_id"
                                   groups="base.group_multi_company"/>
                        </group>
                        <group>
                            <!-- Right column fields -->
                            <field name="active" invisible="1"/>
                        </group>
                    </group>
                    <notebook>
                        <page string="Details" name="details">
                            <field name="description"/>
                        </page>
                    </notebook>
                </sheet>
                <div class="oe_chatter">
                    <field name="message_follower_ids"/>
                    <field name="activity_ids"/>
                    <field name="message_ids"/>
                </div>
            </form>
        </field>
    </record>

    <!-- Search View -->
    <record id="{{ module_name }}.view_{{ model_underscore }}_search" model="ir.ui.view">
        <field name="name">{{ model.name }}.search</field>
        <field name="model">{{ model.name }}</field>
        <field name="arch" type="xml">
            <search string="{{ model_title }}">
                <field name="name"/>
                <separator/>
                <filter name="filter_draft"
                        string="Draft"
                        domain="[('state', '=', 'draft')]"/>
                <filter name="filter_confirmed"
                        string="Confirmed"
                        domain="[('state', '=', 'confirmed')]"/>
                <separator/>
                <filter name="filter_active"
                        string="Archived"
                        domain="[('active', '=', False)]"/>
                <group expand="0" string="Group By">
                    <filter name="group_state"
                            string="Status"
                            context="{'group_by': 'state'}"/>
                    <filter name="group_company"
                            string="Company"
                            context="{'group_by': 'company_id'}"/>
                </group>
            </search>
        </field>
    </record>

    <!-- Action -->
    <record id="{{ module_name }}.action_{{ model_underscore }}" model="ir.actions.act_window">
        <field name="name">{{ model_title }}</field>
        <field name="res_model">{{ model.name }}</field>
        <field name="view_mode">tree,form</field>
        <field name="search_view_id" ref="{{ module_name }}.view_{{ model_underscore }}_search"/>
        <field name="context">{}</field>
        <field name="domain">[]</field>
        <field name="help" type="html">
            <p class="o_view_nocontent_smiling_face">
                Create your first {{ model_title }}
            </p>
        </field>
    </record>

    <!-- Menu Items -->
    <menuitem id="{{ module_name }}.menu_root"
              name="{{ module_title }}"
              sequence="100"/>

    <menuitem id="{{ module_name }}.menu_{{ model_underscore }}"
              name="{{ model_title }}"
              parent="{{ module_name }}.menu_root"
              action="{{ module_name }}.action_{{ model_underscore }}"
              sequence="10"/>

</odoo>
