/** @odoo-module **/
// Hoot Frontend Test Template — Odoo 18.0 / 19.0
// Replace all {{ placeholders }} with actual values.
//
// USAGE:
//   - Place this file in: {{ module_name }}/static/tests/{{ component_name }}.test.js
//   - Register in manifest assets:
//       "web.assets_unit_tests": [
//           "{{ module_name }}/static/tests/**/*.test.js",
//       ]
//   - Run via Odoo test runner or: odoo-bin --test-tags hoot
//
// NOTE: Hoot replaces QUnit as of Odoo 18.0. For Odoo 16.0/17.0, use QUnit.
// See references/testing.md for the QUnit ↔ Hoot migration table.

import {
    describe,
    expect,
    test,
    beforeEach,
    afterEach,
} from "@odoo/hoot";
import { contains, mountWithCleanup } from "@web/../tests/web_test_helpers";
import { {{ ComponentName }} } from "@{{ module_name }}/components/{{ component_file_name }}/{{ component_file_name }}";

// ─── Test suite ───────────────────────────────────────────────────────────────

describe("{{ ComponentName }}", () => {

    // Setup & Teardown
    beforeEach(async () => {
        // Runs before each test in this describe block
        // e.g., mock server responses, set up state
    });

    afterEach(() => {
        // Runs after each test
        // e.g., clean up subscriptions, clear mocks
    });

    // ── Rendering tests ───────────────────────────────────────────────────────

    test("renders correctly with default props", async () => {
        await mountWithCleanup({{ ComponentName }}, {
            props: {
                // Provide required props here
                title: "Test Title",
                record: { id: 1, name: "Test Record" },
            },
        });

        // Verify the component mounts without errors
        expect(".{{ component_css_class }}").toHaveCount(1);
        expect(".{{ component_css_class }}-title").toHaveText("Test Title");
    });

    test("shows empty state when no records", async () => {
        await mountWithCleanup({{ ComponentName }}, {
            props: { records: [] },
        });

        expect(".o_empty_state").toHaveCount(1);
        expect(".{{ component_css_class }}-list").toHaveCount(0);
    });

    // ── Interaction tests ─────────────────────────────────────────────────────

    test("clicking the main button triggers the callback", async () => {
        let clicked = false;
        await mountWithCleanup({{ ComponentName }}, {
            props: {
                onButtonClick: () => { clicked = true; },
            },
        });

        await contains(".{{ component_css_class }}-btn-main").click();
        expect(clicked).toBe(true);
    });

    test("input field updates the model on change", async () => {
        await mountWithCleanup({{ ComponentName }}, {
            props: { value: "initial" },
        });

        // Simulate typing in an input
        await contains(".{{ component_css_class }}-input").edit("new value");
        expect(".{{ component_css_class }}-input").toHaveValue("new value");
    });

    // ── Conditional rendering tests ───────────────────────────────────────────

    test("displays loading spinner while fetching", async () => {
        await mountWithCleanup({{ ComponentName }}, {
            props: { isLoading: true },
        });

        expect(".o_loading_indicator").toHaveCount(1);
        expect(".{{ component_css_class }}-content").toHaveCount(0);
    });

    test("displays error message on failure", async () => {
        await mountWithCleanup({{ ComponentName }}, {
            props: { error: "Something went wrong" },
        });

        expect(".{{ component_css_class }}-error").toHaveCount(1);
        expect(".{{ component_css_class }}-error").toHaveText("Something went wrong");
    });

});

// ─── Migration guide: QUnit → Hoot ───────────────────────────────────────────
//
// QUnit.module("Name", hooks => { ... })   →  describe("Name", () => { ... })
// QUnit.test("Name", async assert => {...}) →  test("Name", async () => { ... })
// assert.strictEqual(a, b, msg)            →  expect(a).toBe(b)
// assert.containsOnce(target, ".sel")      →  expect(".sel").toHaveCount(1)
// assert.containsNone(target, ".sel")      →  expect(".sel").toHaveCount(0)
// assert.hasClass(el, "cls")               →  expect(el).toHaveClass("cls")
// assert.isVisible(el)                     →  expect(el).toBeVisible()
// hooks.beforeEach(async () => { ... })    →  beforeEach(async () => { ... })
