<?xml version="1.0" encoding="UTF-8" ?>
<!-- OWL 2 Component QWeb Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  KEY CONCEPTS:
  - The t-name MUST match exactly the `static template` property in the JS class.
  - No <odoo> or <data> wrapper tags are needed for OWL templates.
  - Use t-esc or t-out for rendering values.
  - Events use t-on-event="handler" (e.g., t-on-click, t-on-change).
  - Use t-att-class for dynamic CSS classes.
  - Use t-key inside t-foreach loops.
-->
<templates xml:space="preserve">

    <t t-name="{{ module_name }}.{{ ComponentClassName }}">
        <div class="o_{{ component_css_class }}_container container-fluid p-3">
            
            <!-- Header -->
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h2 t-esc="props.title || '{{ Default Component Title }}'"/>
                <button class="btn btn-primary" t-on-click="fetchData">
                    <i class="fa fa-refresh me-1"/> Refresh
                </button>
            </div>

            <!-- Loading State -->
            <t t-if="state.isLoading">
                <div class="d-flex justify-content-center p-5">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                </div>
            </t>

            <!-- Data State -->
            <t t-else="">
                <t t-if="state.records.length === 0">
                    <div class="alert alert-info text-center">
                        No records found.
                    </div>
                </t>
                
                <div class="row" t-else="">
                    <!-- Iterating over records -->
                    <t t-foreach="state.records" t-as="record" t-key="record.id">
                        <div class="col-md-4 mb-3">
                            <div class="card shadow-sm cursor-pointer"
                                 t-on-click="() => this.onRecordClick(record.id)">
                                <div class="card-body">
                                    <h5 class="card-title" t-esc="record.name"/>
                                    <span class="badge rounded-pill" 
                                          t-att-class="record.state === 'done' ? 'text-bg-success' : 'text-bg-secondary'"
                                          t-esc="record.state"/>
                                </div>
                            </div>
                        </div>
                    </t>
                </div>
            </t>

        </div>
    </t>

</templates>
