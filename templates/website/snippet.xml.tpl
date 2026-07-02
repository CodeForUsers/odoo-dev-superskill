<?xml version="1.0" encoding="UTF-8" ?>
<!-- Website Snippet Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  Snippets are building blocks for the website builder.
  This file must be loaded in the 'data' section of __manifest__.py.
-->
<odoo>
    
    <!-- 1. The Snippet Structure -->
    <!-- Defines the HTML structure that is dropped onto the page -->
    <template id="{{ module_name }}.snippet_{{ snippet_name }}" name="{{ Snippet Title }}">
        <section class="s_{{ snippet_name }} pt32 pb32">
            <div class="container">
                <div class="row align-items-center">
                    <div class="col-lg-6">
                        <h2>{{ Catchy Title }}</h2>
                        <p class="lead">{{ Subtitle description goes here. }}</p>
                        <a href="/contactus" class="btn btn-primary mb-2">Call to Action</a>
                    </div>
                    <div class="col-lg-6">
                        <img src="/web/image/website.s_banner_default_image" class="img-fluid rounded" alt="Snippet Image"/>
                    </div>
                </div>
            </div>
        </section>
    </template>

    <!-- 2. Register the Snippet in the Website Builder -->
    <!-- This injects our snippet into the blocks sidebar -->
    <template id="{{ module_name }}.snippet_options_register" inherit_id="website.snippets" name="Register {{ snippet_name }}">
        <!-- Use an XPath to place it in a specific category (e.g., inner content, features) -->
        <xpath expr="//div[@id='snippet_content']" position="inside">
            <div class="o_panel_body">
                <t t-snippet="{{ module_name }}.snippet_{{ snippet_name }}"
                   t-thumbnail="/{{ module_name }}/static/src/img/snippets/{{ snippet_name }}.png"/>
            </div>
        </xpath>
    </template>

</odoo>
