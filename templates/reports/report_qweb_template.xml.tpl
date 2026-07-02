<?xml version="1.0" encoding="UTF-8" ?>
<!-- QWeb Report Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  KEY CONCEPTS:
  - t-name must match the report_name field in the ir.actions.report record.
  - web.external_layout wraps the content in the company's standard header/footer.
  - docs is the variable holding the recordset to print.
  - t-foreach / t-as iterate over records (one page per document is common).
  - t-field renders Odoo field values with proper formatting (dates, currency, etc.)
  - t-out renders a raw Python expression as HTML-escaped text.
  - class="page": marks a page break point (when printing multiple records).

  QWeb EXPRESSION SYNTAX:
    t-field="doc.field_name"       → renders field with widget formatting
    t-out="doc.field_name"         → renders raw value (no widget)
    t-if="condition"               → conditional rendering
    t-foreach="doc.lines" t-as="l" → loop
    t-attf-class="... #{val} ..."  → dynamic attribute via f-string

  AVAILABLE VARIABLES IN REPORT CONTEXT:
    docs          → recordset to print
    doc_ids       → list of IDs
    doc_model     → model name (string)
    time          → Python time module
    user          → res.users of current user
    company       → res.company of current user
-->
<odoo>
    <template id="{{ module_name }}.report_{{ report_name }}_document">
        <!-- Outer wrapper: iterates over each document -->
        <t t-foreach="docs" t-as="doc">
            <t t-call="web.external_layout">
                <div class="page">

                    <!-- ── Report Title ───────────────────────────────────── -->
                    <div class="row">
                        <div class="col-6">
                            <h2>{{ Report Title }}</h2>
                            <p class="text-muted">
                                Reference: <strong t-field="doc.name"/>
                            </p>
                        </div>
                        <div class="col-6 text-end">
                            <p>Date: <span t-field="doc.date"
                                           t-options='{"widget": "date"}'/></p>
                            <p>Status:
                                <span t-field="doc.state"
                                      class="badge"
                                      t-attf-class="badge text-bg-{{
                                          'success' if doc.state == 'done' else
                                          'warning' if doc.state == 'confirmed' else
                                          'secondary'
                                      }}"/>
                            </p>
                        </div>
                    </div>

                    <hr/>

                    <!-- ── Partner / Header Info ─────────────────────────── -->
                    <div class="row mb-3">
                        <div class="col-6">
                            <strong>Customer:</strong>
                            <address t-field="doc.partner_id"
                                     t-options='{"widget": "contact",
                                                 "fields": ["name", "address", "phone", "email"],
                                                 "no_marker": True}'/>
                        </div>
                        <div class="col-6">
                            <!-- Add more header fields here -->
                        </div>
                    </div>

                    <!-- ── Lines Table ────────────────────────────────────── -->
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th>Description</th>
                                <th class="text-end">Quantity</th>
                                <th class="text-end">Unit Price</th>
                                <th class="text-end">Subtotal</th>
                            </tr>
                        </thead>
                        <tbody>
                            <t t-foreach="doc.line_ids" t-as="line">
                                <tr>
                                    <td><span t-field="line.name"/></td>
                                    <td class="text-end">
                                        <span t-field="line.quantity"
                                              t-options='{"widget": "float",
                                                          "precision": 2}'/>
                                    </td>
                                    <td class="text-end">
                                        <span t-field="line.price_unit"
                                              t-options='{"widget": "monetary",
                                                          "display_currency": doc.currency_id}'/>
                                    </td>
                                    <td class="text-end">
                                        <span t-field="line.price_subtotal"
                                              t-options='{"widget": "monetary",
                                                          "display_currency": doc.currency_id}'/>
                                    </td>
                                </tr>
                            </t>
                        </tbody>
                        <!-- Totals -->
                        <tfoot>
                            <tr>
                                <td colspan="3" class="text-end">
                                    <strong>Total:</strong>
                                </td>
                                <td class="text-end">
                                    <strong>
                                        <span t-field="doc.amount_total"
                                              t-options='{"widget": "monetary",
                                                          "display_currency": doc.currency_id}'/>
                                    </strong>
                                </td>
                            </tr>
                        </tfoot>
                    </table>

                    <!-- ── Notes / Terms ─────────────────────────────────── -->
                    <t t-if="doc.note">
                        <div class="mt-3">
                            <strong>Notes:</strong>
                            <p t-field="doc.note"/>
                        </div>
                    </t>

                </div>
            </t>
        </t>
    </template>
</odoo>
