<?xml version="1.0" encoding="UTF-8" ?>
<!-- Cron (Scheduled Action) Template — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<!--
  KEY FIELDS:
  - name:             Human-readable description of the cron job
  - model_id:         The model that has the method to call
  - code:             Python expression that calls the method
  - interval_number:  How many units between executions
  - interval_type:    'minutes', 'hours', 'days', 'weeks', 'months'
  - numbercall:       -1 = run indefinitely; N = run N times then deactivate
  - nextcall:         First execution datetime (defaults to next interval)
  - active:           False = paused
  - priority:         Lower number = higher priority (default 5)
  - noupdate="1":     Admin can modify the cron after install without losing changes

  SECURITY:
  - Cron methods should use @api.model decorator
  - Avoid very long-running crons; use queue_job for heavy processing
  - cr.commit() is allowed inside cron methods (for large batch processing)
-->
<odoo>
    <data noupdate="1">

        <!-- ── Daily Cron ────────────────────────────────────────────────── -->
        <record id="{{ module_name }}.cron_{{ action_name }}_daily" model="ir.cron">
            <field name="name">{{ module_title }}: {{ action_label }} (Daily)</field>
            <field name="model_id" ref="{{ module_name }}.model_{{ model_underscore }}"/>
            <field name="code">model._cron_{{ action_name }}()</field>
            <field name="interval_number">1</field>
            <field name="interval_type">days</field>
            <field name="numbercall">-1</field>
            <field name="active" eval="True"/>
            <field name="priority">5</field>
        </record>

        <!-- ── Hourly Cron ───────────────────────────────────────────────── -->
        <!--
        <record id="{{ module_name }}.cron_{{ action_name }}_hourly" model="ir.cron">
            <field name="name">{{ module_title }}: {{ action_label }} (Hourly)</field>
            <field name="model_id" ref="{{ module_name }}.model_{{ model_underscore }}"/>
            <field name="code">model._cron_{{ action_name }}()</field>
            <field name="interval_number">1</field>
            <field name="interval_type">hours</field>
            <field name="numbercall">-1</field>
            <field name="active" eval="True"/>
            <field name="priority">5</field>
        </record>
        -->

        <!-- ── Every N minutes ──────────────────────────────────────────── -->
        <!--
        <record id="{{ module_name }}.cron_{{ action_name }}_minutes" model="ir.cron">
            <field name="name">{{ module_title }}: {{ action_label }} (30 min)</field>
            <field name="model_id" ref="{{ module_name }}.model_{{ model_underscore }}"/>
            <field name="code">model._cron_{{ action_name }}()</field>
            <field name="interval_number">30</field>
            <field name="interval_type">minutes</field>
            <field name="numbercall">-1</field>
            <field name="active" eval="True"/>
        </record>
        -->

    </data>
</odoo>

<!--
CORRESPONDING PYTHON METHOD (in models/{{ model_underscore }}.py):

    @api.model
    def _cron_{{ action_name }}(self):
        """Scheduled action: {{ action_label }}."""
        _logger.info("Cron _cron_{{ action_name }} started.")
        records = self.search([("state", "=", "pending")])

        # For large batches, use commits to avoid long DB locks
        batch_size = 100
        for i in range(0, len(records), batch_size):
            batch = records[i : i + batch_size]
            batch._process_batch()
            # cr.commit() is acceptable here (cron context):
            self.env.cr.commit()
            _logger.info(
                "Cron progress: %d/%d records.", i + len(batch), len(records)
            )

        _logger.info("Cron _cron_{{ action_name }} finished.")
-->
