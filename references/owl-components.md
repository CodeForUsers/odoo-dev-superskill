# Componentes OWL 2 en Odoo (16.0–19.0)

Odoo utiliza **OWL** (Odoo Web Library) para toda su interfaz desde la versión 16.0. OWL es un framework reactivo basado en clases y plantillas QWeb, fuertemente inspirado en React pero sin JSX (usa XML).

A partir de **Odoo 17.0**, la versión del framework es **OWL 2**, que consolida la sintaxis (desaparece `owl.tags.xml`, se usa un getter estático `template`).

## 1. Estructura de un Componente

Un componente típico consta de dos partes, idealmente separadas:
1. `component_name.js`: La lógica de la clase.
2. `component_name.xml`: La plantilla QWeb (no se incluye en manifests, sino que el JS la carga estáticamente o se compila en el bundle).

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

## 2. Inyección de Servicios (Hooks)

Odoo proporciona servicios globales (RPC, notificaciones, diálogos) a los que se accede mediante el hook `useService`:

- `this.orm = useService("orm");` → Para interactuar con modelos (searchRead, call).
- `this.rpc = useService("rpc");` → Para llamadas directas a controladores HTTP.
- `this.notification = useService("notification");` → Para mostrar popups tipo toast.
- `this.action = useService("action");` → Para ejecutar `do_action` (abrir vistas).
- `this.dialog = useService("dialog");` → Para abrir modales.

## 3. Estado Reactivo (`useState`)

Solo las variables dentro de un objeto `useState` provocarán que el componente se re-renderice cuando cambien. Las variables de clase normales (`this.foo = 1`) no son reactivas.

```javascript
this.state = useState({
    counter: 0,
    loading: false,
});
// Cambiar this.state.counter disparará el re-renderizado
```

## 4. Ciclo de Vida (Lifecycle Hooks)

En OWL 2, el ciclo de vida se maneja mediante hooks importados de `@odoo/owl` y llamados *dentro* del método `setup()`:

- `onWillStart(async () => {...})`: Antes del primer renderizado. Útil para hacer await de RPCs. El renderizado espera a que termine.
- `onMounted(() => {...})`: Después de que el componente se inserta en el DOM.
- `onWillUpdateProps((nextProps) => {...})`: Antes de recibir nuevas props.
- `onWillUnmount(() => {...})`: Antes de destruirse (limpiar timers, eventos de window).

## 5. Plantillas QWeb (Sintaxis OWL)

OWL utiliza QWeb para sus plantillas. Directivas clave:

- `t-esc` / `t-out`: Renderizar texto seguro (evita XSS).
- `t-if` / `t-elif` / `t-else`: Condicionales.
- `t-foreach` + `t-as` + `t-key`: Bucles. **Importante**: OWL exige `t-key` en los bucles para reconciliación eficiente del DOM.
- `t-on-click="methodName"`: Escuchar eventos nativos.
- `t-att-class="{'active': state.isActive}"`: Clases dinámicas.

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

## 6. Registro en el Registro (Registry) de Odoo

Para que Odoo pueda usar tu componente en una acción de cliente o como widget de campo, debes registrarlo:

**Como Acción de Cliente (Client Action):**
```javascript
import { registry } from "@web/core/registry";
registry.category("actions").add("my_module.dashboard", MyComponent);
```

**Como Widget de Campo (Field Widget):**
```javascript
import { registry } from "@web/core/registry";
import { standardFieldProps } from "@web/views/fields/standard_field_props";

export class MyFieldWidget extends Component { /* ... */ }
MyFieldWidget.props = { ...standardFieldProps };

registry.category("fields").add("my_widget", MyFieldWidget);
```

## 7. Integración en el Manifest (`__manifest__.py`)

Los archivos de OWL deben cargarse en la sección `assets` del manifest, dependiendo de dónde se vayan a usar:

```python
    "assets": {
        "web.assets_backend": [
            "my_module/static/src/components/**/*.js",
            "my_module/static/src/components/**/*.xml",
        ],
        "web.assets_frontend": [
            # Para la web pública (e-commerce, portal)
        ],
    },
```
