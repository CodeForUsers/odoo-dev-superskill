/** @odoo-module **/
// OWL 2 Component Template — Odoo 16.0–19.0
// Replace all {{ placeholders }} with actual values.
//
// USAGE:
//   - Place this file in: {{ module_name }}/static/src/components/{{ component_file_name }}.js
//   - Register in manifest: "web.assets_backend": ["{{ module_name }}/static/src/components/**/*"]
//   - If this is a Client Action, register it in the registry (see bottom of file).

import { Component, useState, onWillStart } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";

export class {{ ComponentClassName }} extends Component {
    // Defines the XML template name (must match t-name in the .xml file)
    static template = "{{ module_name }}.{{ ComponentClassName }}";
    
    // Optional: import child components if this component uses them
    static components = {};

    // Define props validation (optional but recommended)
    static props = {
        title: { type: String, optional: true },
        // Add more props here
    };

    setup() {
        // 1. Inject services
        this.orm = useService("orm");
        this.action = useService("action");
        this.notification = useService("notification");

        // 2. Define reactive state
        this.state = useState({
            records: [],
            isLoading: true,
        });

        // 3. Lifecycle hooks
        onWillStart(async () => {
            await this.fetchData();
        });
    }

    // ─── Business Logic ──────────────────────────────────────────────────────

    async fetchData() {
        this.state.isLoading = true;
        try {
            // Example: fetch records from a model
            this.state.records = await this.orm.searchRead(
                "{{ target_model }}",
                [], // Domain
                ["name", "state"], // Fields
                { limit: 10 }
            );
        } catch (error) {
            this.notification.add(
                "Failed to fetch data",
                { type: "danger" }
            );
        } finally {
            this.state.isLoading = false;
        }
    }

    async onRecordClick(recordId) {
        // Example: open a form view for the clicked record
        this.action.doAction({
            type: "ir.actions.act_window",
            res_model: "{{ target_model }}",
            res_id: recordId,
            views: [[false, "form"]],
            target: "current", // or 'new' for dialog
        });
    }
}

// ─── Registration (Uncomment the one you need) ───────────────────────────────

/* 1. Register as a Client Action (accessed via an ir.actions.client)
import { registry } from "@web/core/registry";
registry.category("actions").add("{{ module_name }}.{{ action_tag_name }}", {{ ComponentClassName }});
*/

/* 2. Register as a Field Widget (accessed via widget="my_widget" in XML views)
import { registry } from "@web/core/registry";
import { standardFieldProps } from "@web/views/fields/standard_field_props";

{{ ComponentClassName }}.props = {
    ...standardFieldProps,
    // Add custom widget props
};
{{ ComponentClassName }}.supportedTypes = ["char", "text"]; // Fields that can use this widget
registry.category("fields").add("{{ widget_name }}", {{ ComponentClassName }});
*/
