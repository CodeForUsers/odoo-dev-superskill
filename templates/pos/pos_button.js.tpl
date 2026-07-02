/** @odoo-module */
// POS Custom Button Component — Odoo 16.0-19.0
// Replace all {{ placeholders }} with actual values.
//
// USAGE:
//   - Place in: {{ module_name }}/static/src/pos/{{ button_name }}.js
//   - Load in manifest under "point_of_sale._assets_pos"

import { ProductScreen } from "@point_of_sale/app/screens/product_screen/product_screen";
import { usePos } from "@point_of_sale/app/store/pos_hook";
import { Component } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";

// 1. Define the Button Component
export class {{ ButtonClassName }} extends Component {
    static template = "{{ module_name }}.{{ ButtonClassName }}";

    setup() {
        this.pos = usePos();
        this.popup = useService("popup");
    }

    async onClick() {
        // Example: Get the current order
        const order = this.pos.get_order();
        if (!order) return;

        // Example: Show a confirmation popup
        const { confirmed } = await this.popup.add(ConfirmPopup, {
            title: this.env._t("Custom Action"),
            body: this.env._t("Do you want to apply this custom action?"),
        });

        if (confirmed) {
            // Modify order, call RPC, etc.
            // order.set_custom_flag(true);
        }
    }
}

// 2. Register the component to the Product Screen Control Panel
ProductScreen.addControlButton({
    component: {{ ButtonClassName }},
    condition: function () {
        // E.g., only show if a specific setting is enabled
        return true; 
    },
});

/*
And the corresponding XML (e.g., in {{ button_name }}.xml):

<?xml version="1.0" encoding="UTF-8"?>
<templates id="template" xml:space="preserve">
    <t t-name="{{ module_name }}.{{ ButtonClassName }}" owl="1">
        <button class="control-button btn btn-light rounded-0 fw-bolder" t-on-click="onClick">
            <i class="fa fa-star me-1" role="img" aria-label="Custom Action" title="Custom Action" />
            <span>Custom Action</span>
        </button>
    </t>
</templates>
*/
