# OWL 2 Components in Odoo (16.0–19.0)

Odoo uses **OWL** (Odoo Web Library) for its entire interface since version 16.0. OWL is a reactive framework based on classes and QWeb templates, heavily inspired by React but without JSX (it uses XML).

Starting from **Odoo 17.0**, the framework version is **OWL 2**, which consolidates the syntax (`owl.tags.xml` disappears, a static `template` getter is used).

## 1. Component Structure

A typical component consists of two parts, ideally separated:
1. `component_name.js`: The class logic.
2. `component_name.xml`: The QWeb template (not included in manifests, but statically loaded by JS or compiled into the bundle).

```javascript
/** @odoo-module **/
import { Component, useState, onWillStart } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";

export class MyComponent extends Component {
    static template = "my_module.MyComponent";
    static props = {
        title: { type: String, optional: true },
    };

    setup() {
        this.orm = useService("orm");
        this.state = useState({ records: [] });

        onWillStart(async () => {
            this.state.records = await this.orm.searchRead("res.partner", [], ["name"]);
        });
    }
}
```

## 2. Service Injection (Hooks)

Odoo provides global services (RPC, notifications, dialogs) accessed via the `useService` hook:

- `this.orm = useService("orm");` → To interact with models (searchRead, call).
- `this.rpc = useService("rpc");` → For direct HTTP controller calls.
- `this.notification = useService("notification");` → To show toast notifications.
- `this.action = useService("action");` → To execute `do_action` (open views).
- `this.dialog = useService("dialog");` → To open modals.

## 3. Reactive State (`useState`)

Only variables inside a `useState` object will trigger the component to re-render when they change. Normal class variables (`this.foo = 1`) are not reactive.

```javascript
this.state = useState({
    counter: 0,
    loading: false,
});
// Changing this.state.counter will trigger a re-render
```

## 4. Lifecycle Hooks

In OWL 2, the lifecycle is managed by hooks imported from `@odoo/owl` and called *inside* the `setup()` method:

- `onWillStart(async () => {...})`: Before the first render. Useful to await RPCs. Rendering waits for it to finish.
- `onMounted(() => {...})`: After the component is attached to the DOM.
- `onWillUpdateProps((nextProps) => {...})`: Before receiving new props.
- `onWillUnmount(() => {...})`: Before being destroyed (cleanup timers, window events).

## 5. QWeb Templates (OWL Syntax)

OWL uses QWeb for its templates. Key directives:

- `t-esc` / `t-out`: Render safe text (prevents XSS).
- `t-if` / `t-elif` / `t-else`: Conditionals.
- `t-foreach` + `t-as` + `t-key`: Loops. **Important**: OWL requires `t-key` in loops for efficient DOM reconciliation.
- `t-on-click="methodName"`: Listen to native events.
- `t-att-class="{'active': state.isActive}"`: Dynamic classes.

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<templates xml:space="preserve">
    <t t-name="my_module.MyComponent">
        <div class="my_component">
            <h1 t-esc="props.title || 'Default Title'"/>
            <ul>
                <t t-foreach="state.records" t-as="record" t-key="record.id">
                    <li t-esc="record.name" t-on-click="() => this.openRecord(record.id)"/>
                </t>
            </ul>
        </div>
    </t>
</templates>
```

## 6. Registering in the Odoo Registry

For Odoo to use your component in a client action or as a field widget, you must register it:

**As a Client Action:**
```javascript
import { registry } from "@web/core/registry";
registry.category("actions").add("my_module.dashboard", MyComponent);
```

**As a Field Widget:**
```javascript
import { registry } from "@web/core/registry";
import { standardFieldProps } from "@web/views/fields/standard_field_props";

export class MyFieldWidget extends Component { /* ... */ }
MyFieldWidget.props = { ...standardFieldProps };

registry.category("fields").add("my_widget", MyFieldWidget);
```

## 7. Manifest Integration (`__manifest__.py`)

OWL files must be loaded in the `assets` section of the manifest, depending on where they will be used:

```python
    "assets": {
        "web.assets_backend": [
            "my_module/static/src/components/**/*.js",
            "my_module/static/src/components/**/*.xml",
        ],
        "web.assets_frontend": [
            # For public web (e-commerce, portal)
        ],
    },
```
