/* Custom Stylesheet Template (SCSS) — Odoo 16.0–19.0
   Replace all {{ placeholders }} with actual values.

   USAGE:
     1. Place this file in {{ module_name }}/static/src/scss/custom_styles.scss
     2. Register in __manifest__.py under assets:
        "assets": {
            "web.assets_backend": [
                "{{ module_name }}/static/src/scss/custom_styles.scss",
            ],
        }

   TIPS:
   - Always prefix your classes with your module name to avoid collisions
     (e.g., .o_{{ module_name }}_custom_class).
   - You can use Odoo's Bootstrap variables ($primary, $secondary, etc.).
*/

// Example 1: Styling a specific view element
.o_{{ module_name }}_highlight {
    background-color: lighten($primary, 40%);
    border-left: 4px solid $primary;
    padding: 8px;
    margin-bottom: 16px;
    border-radius: 4px;
}

// Example 2: Styling a Kanban card
.o_kanban_record {
    &.o_{{ module_name }}_kanban_urgent {
        border-color: $danger;
        box-shadow: 0 0 5px rgba($danger, 0.5);
        
        .o_kanban_record_title {
            color: $danger;
            font-weight: bold;
        }
    }
}

// Example 3: Modifying a field widget specifically in your view
.o_form_view {
    .o_field_widget.o_{{ module_name }}_large_text {
        font-size: 1.2em;
        font-family: monospace;
        color: $info;
    }
}

// Example 4: A custom OWL component's styles
.o_{{ module_name }}_dashboard_container {
    padding: 24px;
    background-color: #f8f9fa;
    
    .dashboard-card {
        transition: transform 0.2s, box-shadow 0.2s;
        
        &:hover {
            transform: translateY(-2px);
            box-shadow: 0 .5rem 1rem rgba(0,0,0,.15)!important;
        }
    }
}
