<?xml version="1.0" encoding="UTF-8" ?>
<!-- Website Snippet Options Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  Snippet options define what settings appear in the right sidebar
  when a user clicks on the snippet in the builder.
  This file must be loaded in the 'data' section of __manifest__.py.
-->
<odoo>

    <!-- Define options for our custom snippet -->
    <template id="{{ module_name }}.snippet_{{ snippet_name }}_options" inherit_id="website.snippet_options">
        <xpath expr="." position="inside">
            
            <!-- Link these options to the main wrapper class of the snippet -->
            <div data-selector=".s_{{ snippet_name }}">
                
                <!-- Built-in option: Color Palettes -->
                <we-colorpicker string="Background Color" data-select-class="" data-css-property="background-color"/>
                
                <!-- Custom option group -->
                <we-select string="Alignment">
                    <!-- Removes classes to clear state, then adds the selected one -->
                    <we-button data-select-class="" data-name="align_left">Left</we-button>
                    <we-button data-select-class="text-center" data-name="align_center">Center</we-button>
                    <we-button data-select-class="text-end" data-name="align_right">Right</we-button>
                </we-select>

                <!-- Example of connecting to a JS widget -->
                <!-- <we-button string="Custom JS Action" data-custom-widget="my_custom_widget_name"/> -->
                
            </div>
            
        </xpath>
    </template>

</odoo>
