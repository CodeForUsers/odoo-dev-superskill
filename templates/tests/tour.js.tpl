/** @odoo-module **/
// Odoo UI Tour Template — Odoo 16.0–19.0
// Replace all {{ placeholders }} with actual values.
//
// USAGE:
// 1. Place in {{ module_name }}/static/src/tests/tours/{{ tour_name }}.js
// 2. Load in manifest:
//    "assets": {
//        "web.assets_tests": [
//            "{{ module_name }}/static/src/tests/tours/{{ tour_name }}.js"
//        ]
//    }
// 3. Trigger it from Python (see test_tour_python.py.tpl)

import { registry } from "@web/core/registry";

// For Odoo 18+, use Tour API from registry. 
// For Odoo 16/17, it's typically import tour from "web_tour.tour" (but registering in @web/core/registry works for both in modern setups).

registry.category("web_tour.tours").add('{{ tour_name }}', {
    url: '/web',
    // test: true prevents the tour from being run automatically by regular users
    test: true,
    steps: () => [
        // 1. Open the App Menu
        {
            trigger: '.o_app[data-menu-xmlid="{{ module_name }}.menu_root"]',
            content: 'Open the {{ Module Name }} app',
            run: 'click',
        },
        // 2. Click the Create Button in the list view
        {
            trigger: '.o_list_button_add',
            content: 'Click the create button',
            run: 'click',
        },
        // 3. Fill in a field (Form View)
        {
            trigger: 'div[name="name"] input',
            content: 'Insert a name',
            run: 'text My Test Record',
        },
        // 4. Save the record
        {
            trigger: '.o_form_button_save',
            content: 'Save the record',
            run: 'click',
        },
        // 5. Verify the state changed or an element exists
        {
            trigger: '.o_statusbar_status .o_arrow_button.btn-primary:contains("Draft")',
            content: 'Verify the state is draft',
            isCheck: true, // Just verify, don't interact
        },
    ]
});
