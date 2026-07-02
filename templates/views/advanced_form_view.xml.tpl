<?xml version="1.0" encoding="utf-8"?>
<!-- Advanced Form View (Mega Form) Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  FEATURES INCLUDED:
  - Header (Statusbar & Buttons)
  - Sheet (Main content wrapper)
  - Smart Buttons (Top right stat buttons)
  - Title & Image (Left side)
  - Group Grid (2-column layout)
  - Notebook (Tabs)
  - One2many inline list (Lines)
  - Chatter (Mail thread & Activities)
-->
<odoo>

    <record id="{{ module_name }}.view_{{ model_underscore }}_form_advanced" model="ir.ui.view">
        <field name="name">{{ model_name }}.form.advanced</field>
        <field name="model">{{ model_name }}</field>
        <field name="arch" type="xml">
            <form string="{{ Model Title }}">
                
                <!-- 1. HEADER: Actions and State -->
                <header>
                    <button name="action_confirm" type="object" string="Confirm" class="btn-primary" invisible="state != 'draft'"/>
                    <button name="action_cancel" type="object" string="Cancel" invisible="state in ('done', 'cancel')"/>
                    <field name="state" widget="statusbar" statusbar_visible="draft,confirmed,done"/>
                </header>
                
                <!-- 2. SHEET: Main Card Content -->
                <sheet>
                    <!-- Smart Buttons (Stat Buttons) Top Right -->
                    <div class="oe_button_box" name="button_box">
                        <button name="action_view_related" type="object" class="oe_stat_button" icon="fa-list">
                            <field name="related_count" widget="statinfo" string="Related Items"/>
                        </button>
                    </div>

                    <!-- Avatar / Image (Optional) -->
                    <!-- <field name="image_1920" widget="image" class="oe_avatar" options="{'preview_image': 'image_128'}"/> -->

                    <!-- Title -->
                    <div class="oe_title">
                        <label for="name" class="oe_edit_only"/>
                        <h1>
                            <field name="name" placeholder="e.g. Project Alpha"/>
                        </h1>
                    </div>

                    <!-- Group Grid -->
                    <group>
                        <!-- Left Column -->
                        <group name="group_left">
                            <field name="partner_id" widget="res_partner_many2one"/>
                            <field name="date_start"/>
                        </group>
                        <!-- Right Column -->
                        <group name="group_right">
                            <field name="user_id" widget="many2one_avatar_user"/>
                            <field name="company_id" groups="base.group_multi_company"/>
                        </group>
                    </group>

                    <!-- 3. NOTEBOOK: Tabs -->
                    <notebook>
                        <!-- Tab 1: Inline One2many List -->
                        <page string="Lines" name="page_lines">
                            <!-- In 18.0+, child view uses <list> instead of <tree> -->
                            <field name="line_ids" mode="list,kanban">
                                <!-- Odoo 18 = list, Odoo 16/17 = tree -->
                                <list string="Lines" editable="bottom">
                                    <field name="sequence" widget="handle"/>
                                    <field name="product_id"/>
                                    <field name="quantity"/>
                                    <field name="price_unit"/>
                                    <field name="price_subtotal"/>
                                </list>
                                <!-- Basic Form view for popup editing -->
                                <form string="Line">
                                    <group>
                                        <field name="product_id"/>
                                        <field name="quantity"/>
                                    </group>
                                </form>
                            </field>
                            
                            <!-- Totals block at the bottom right of the tab -->
                            <group name="note_group" col="6" class="mt-2 mt-md-0">
                                <group colspan="4">
                                    <field name="note" nolabel="1" placeholder="Terms and conditions..."/>
                                </group>
                                <group class="oe_subtotal_footer oe_right" colspan="2" name="total">
                                    <field name="amount_total" class="oe_subtotal_footer_separator"/>
                                </group>
                            </group>
                        </page>
                        
                        <!-- Tab 2: Settings / Other Info -->
                        <page string="Other Info" name="page_other">
                            <group>
                                <field name="reference"/>
                            </group>
                        </page>
                    </notebook>
                </sheet>
                
                <!-- 4. CHATTER: History, Activities and Messages -->
                <!-- Requires inherit from 'mail.thread', 'mail.activity.mixin' in Python -->
                <div class="oe_chatter">
                    <field name="message_follower_ids"/>
                    <field name="activity_ids"/>
                    <field name="message_ids"/>
                </div>
            </form>
        </field>
    </record>

</odoo>
