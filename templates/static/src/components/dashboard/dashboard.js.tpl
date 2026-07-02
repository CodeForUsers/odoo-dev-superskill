/** @odoo-module **/
// Dashboard Client Action Component (JS) — Odoo 16.0–19.0
// Replace all {{ placeholders }} with actual values.
//
// USAGE:
// 1. Place in {{ module_name }}/static/src/components/dashboard/dashboard.js
// 2. Load in manifest under "web.assets_backend"
// 3. Define an XML action:
//    <record id="action_my_dashboard" model="ir.actions.client">
//        <field name="name">My Dashboard</field>
//        <field name="tag">{{ module_name }}.dashboard</field>
//    </record>

import { Component, useState, onWillStart } from "@odoo/owl";
import { registry } from "@web/core/registry";
import { useService } from "@web/core/utils/hooks";

export class {{ DashboardClassName }} extends Component {
    static template = "{{ module_name }}.{{ DashboardClassName }}";

    setup() {
        this.orm = useService("orm");
        this.action = useService("action");
        
        this.state = useState({
            kpi_orders: 0,
            kpi_revenue: 0.0,
            recent_items: [],
            isLoading: true,
        });

        onWillStart(async () => {
            await this.loadData();
        });
    }

    async loadData() {
        this.state.isLoading = true;
        try {
            // Example 1: Call a custom python method on a model
            // const stats = await this.orm.call("{{ model.name }}", "get_dashboard_stats", []);
            
            // Example 2: Simple search_read and search_count
            this.state.kpi_orders = await this.orm.searchCount("sale.order", [["state", "=", "sale"]]);
            
            this.state.recent_items = await this.orm.searchRead(
                "sale.order", 
                [], 
                ["name", "amount_total", "state"], 
                { limit: 5, order: "create_date desc" }
            );
            
            // Simulated Revenue
            this.state.kpi_revenue = this.state.recent_items.reduce((sum, order) => sum + order.amount_total, 0);

        } catch (error) {
            console.error("Dashboard failed to load:", error);
        } finally {
            this.state.isLoading = false;
        }
    }

    openRecord(resId) {
        this.action.doAction({
            type: "ir.actions.act_window",
            res_model: "sale.order",
            res_id: resId,
            views: [[false, "form"]],
            target: "current",
        });
    }
}

// Register as a Client Action
registry.category("actions").add("{{ module_name }}.dashboard", {{ DashboardClassName }});
