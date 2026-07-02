<?xml version="1.0" encoding="UTF-8" ?>
<!-- Kanban View Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  KEY KANBAN CONCEPTS:
  - <kanban>: root tag; attributes control grouping, default groups, etc.
  - <templates>: defines QWeb templates used to render cards.
  - t-attf-class: dynamic CSS classes using string formatting.
  - t-if / t-else: conditional rendering.
  - record.field_name.value / record.field_name.raw_value: access field data.
  - widget: use "priority" for stars, "state_selection" for colored pills, etc.
-->
<odoo>

    <!-- Kanban View -->
    <record id="{{ module_name }}.view_{{ model_underscore }}_kanban" model="ir.ui.view">
        <field name="name">{{ model.name }}.kanban</field>
        <field name="model">{{ model.name }}</field>
        <field name="arch" type="xml">
            <kanban
                default_group_by="state"
                class="o_kanban_small_column"
                group_create="false"
                group_delete="false"
                group_fold="true"
                quick_create="false"
                records_draggable="true">

                <!-- Fields loaded for each card (must be declared here) -->
                <field name="id"/>
                <field name="name"/>
                <field name="state"/>
                <field name="user_id"/>
                <field name="priority"/>
                <field name="color"/>
                <field name="activity_state"/>

                <!-- Color configuration (uses the "color" Integer field) -->
                <templates>
                    <t t-name="kanban-box">
                        <div t-attf-class="
                            oe_kanban_card
                            oe_kanban_global_click
                            o_kanban_record_has_image_fill
                            {{color_for('color')}}
                        ">
                            <!-- Card body -->
                            <div class="oe_kanban_content">

                                <!-- Top row: priority + actions menu -->
                                <div class="o_kanban_record_top">
                                    <div class="o_kanban_record_headings">
                                        <strong class="o_kanban_record_title">
                                            <field name="name"/>
                                        </strong>
                                    </div>
                                    <div class="o_kanban_record_top_actions">
                                        <field name="priority" widget="priority"/>
                                        <!-- Action menu (kebab ···) -->
                                        <div class="o_dropdown_kanban dropdown">
                                            <a class="dropdown-toggle o-no-caret btn"
                                               role="button" data-bs-toggle="dropdown">
                                                <span class="fa fa-ellipsis-v"/>
                                            </a>
                                            <div class="dropdown-menu" role="menu">
                                                <t t-if="widget.editable">
                                                    <a role="menuitem"
                                                       class="dropdown-item o_kanban_action"
                                                       data-type="edit">Edit</a>
                                                </t>
                                                <t t-if="widget.deletable">
                                                    <a role="menuitem"
                                                       class="dropdown-item o_kanban_action"
                                                       data-type="delete">Delete</a>
                                                </t>
                                                <ul class="oe_kanban_colorpicker"
                                                    data-field="color"/>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Middle row: custom info -->
                                <div class="o_kanban_record_body">
                                    <!-- Assigned user avatar -->
                                    <field name="user_id" widget="many2one_avatar_user"/>
                                    <!-- Any other relevant field -->
                                </div>

                                <!-- Bottom row: activity & status badge -->
                                <div class="o_kanban_record_bottom">
                                    <div class="oe_kanban_bottom_left">
                                        <field name="activity_state"
                                               widget="kanban_activity"/>
                                    </div>
                                    <div class="oe_kanban_bottom_right">
                                        <field name="state"
                                               widget="label_selection"
                                               options="{
                                                   'classes': {
                                                       'draft': 'default',
                                                       'confirmed': 'info',
                                                       'done': 'success',
                                                       'cancelled': 'danger'
                                                   }
                                               }"/>
                                    </div>
                                </div>

                            </div>
                        </div>
                    </t>
                </templates>
            </kanban>
        </field>
    </record>

</odoo>
