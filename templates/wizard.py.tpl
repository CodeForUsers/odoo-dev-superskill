# Wizard (TransientModel) Template — Odoo 16.0–19.0 (OCA Standard)
# Replace all {{ placeholders }} with actual values.
#
# USAGE:
#   - TransientModel for temporary dialogs/wizards
#   - Define a Many2one to the originating model ({{ origin_model }})
#   - The action method returns an ir.actions.act_window or closes the dialog
#   - Always define ACLs in ir.model.access.csv for the wizard model

from odoo import _, api, fields, models
from odoo.exceptions import UserError, ValidationError

import logging

_logger = logging.getLogger(__name__)


class {{ WizardClassName }}(models.TransientModel):
    """{{ wizard_description }}."""

    # =========================================================================
    # 1. Private attributes
    # =========================================================================
    _name = "{{ module_name }}.{{ wizard_suffix }}.wizard"
    _description = "{{ wizard_description }}"

    # =========================================================================
    # 2. Fields declaration
    # =========================================================================

    # Reference to the record(s) this wizard acts upon
    {{ origin_field }}_ids = fields.Many2many(
        "{{ origin_model }}",
        string="{{ OriginModelTitle }}",
        default=lambda self: self._default_{{ origin_field }}_ids(),
    )

    # Wizard-specific fields
    reason = fields.Text(
        string="Reason",
        help="Optional explanation for this action.",
    )
    date = fields.Date(
        string="Date",
        default=fields.Date.today,
        required=True,
    )
    note = fields.Html(
        string="Note",
        sanitize=True,
    )

    # =========================================================================
    # 4. Default methods
    # =========================================================================
    def _default_{{ origin_field }}_ids(self):
        """Pre-select the records from the active_ids context."""
        active_ids = self.env.context.get("active_ids", [])
        return self.env["{{ origin_model }}"].browse(active_ids)

    # =========================================================================
    # 7. Constraint methods
    # =========================================================================
    @api.constrains("{{ origin_field }}_ids")
    def _check_{{ origin_field }}_ids(self):
        for wizard in self:
            if not wizard.{{ origin_field }}_ids:
                raise ValidationError(
                    _("You must select at least one record to process.")
                )

    # =========================================================================
    # 9. Action methods (buttons)
    # =========================================================================
    def action_confirm(self):
        """Execute the wizard action and close the dialog."""
        self.ensure_one()

        if not self.{{ origin_field }}_ids:
            raise UserError(_("No records selected."))

        # --- Main wizard logic ---
        self.{{ origin_field }}_ids._do_{{ wizard_suffix }}(
            date=self.date,
            reason=self.reason or "",
        )

        _logger.info(
            "Wizard %s executed on %d records.",
            self._name,
            len(self.{{ origin_field }}_ids),
        )

        # Return action to refresh current view
        return {"type": "ir.actions.act_window_close"}

    def action_confirm_and_stay(self):
        """Execute and stay on the list (optional variant)."""
        self.ensure_one()
        self.action_confirm()
        return {
            "type": "ir.actions.act_window",
            "res_model": "{{ origin_model }}",
            "view_mode": "list,form",  # Use "tree,form" for Odoo 16/17
            "domain": [("id", "in", self.{{ origin_field }}_ids.ids)],
            "target": "current",
        }

    def action_cancel(self):
        """Close the wizard without doing anything."""
        return {"type": "ir.actions.act_window_close"}

    # =========================================================================
    # 10. Private/Business methods
    # =========================================================================
    def _prepare_result_values(self):
        """Prepare a dict of values to return to the caller model."""
        self.ensure_one()
        return {
            "date": self.date,
            "reason": self.reason,
        }
