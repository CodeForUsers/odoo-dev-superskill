# Odoo Model Skeleton Template (OCA Standard)
# Replace all {{ placeholders }} with actual values.
# This template follows the OCA attribute ordering convention.
# Compatible with Odoo 16.0–19.0.

from odoo import _, api, fields, models
from odoo.exceptions import UserError, ValidationError

import logging

_logger = logging.getLogger(__name__)


class {{ ModelClassName }}(models.Model):
    """{{ model_description }}."""

    # =========================================================================
    # 1. Private attributes
    # =========================================================================
    _name = "{{ model.name }}"
    _description = "{{ model_description }}"
    _inherit = ["mail.thread", "mail.activity.mixin"]
    _order = "sequence, id"
    # _rec_name = "name"  # Uncomment if different from 'name'

    # =========================================================================
    # 2. Fields declaration
    # =========================================================================
    name = fields.Char(
        string="Name",
        required=True,
        tracking=True,
    )
    sequence = fields.Integer(
        string="Sequence",
        default=10,
    )
    active = fields.Boolean(
        string="Active",
        default=True,
    )
    company_id = fields.Many2one(
        "res.company",
        string="Company",
        default=lambda self: self.env.company,
        required=True,
    )
    state = fields.Selection(
        selection=[
            ("draft", "Draft"),
            ("confirmed", "Confirmed"),
            ("done", "Done"),
            ("cancelled", "Cancelled"),
        ],
        string="Status",
        default="draft",
        tracking=True,
        copy=False,
    )
    description = fields.Html(
        string="Description",
        sanitize=True,
    )
    # --- Related fields ---
    # currency_id = fields.Many2one(
    #     related="company_id.currency_id",
    #     store=True,
    # )

    # --- Computed fields ---
    # display_name = fields.Char(compute="_compute_display_name")

    # =========================================================================
    # 3. SQL Constraints
    # =========================================================================
    _sql_constraints = [
        (
            "name_unique",
            "UNIQUE(name, company_id)",
            "Name must be unique per company.",
        ),
    ]

    # =========================================================================
    # 4. Default methods
    # =========================================================================
    # def _default_{{ field }}(self):
    #     return self.env["..."].search([], limit=1)

    # =========================================================================
    # 5. Compute methods
    # =========================================================================
    # --- For Odoo 17.0+: use _compute_display_name instead of name_get() ---
    # @api.depends("name")
    # def _compute_display_name(self):
    #     for rec in self:
    #         rec.display_name = rec.name

    # =========================================================================
    # 6. Onchange methods
    # =========================================================================
    # @api.onchange("{{ field }}")
    # def _onchange_{{ field }}(self):
    #     if self.{{ field }}:
    #         self.name = self.{{ field }}.display_name

    # =========================================================================
    # 7. Constraint methods
    # =========================================================================
    # @api.constrains("{{ field }}")
    # def _check_{{ field }}(self):
    #     for rec in self:
    #         if not rec.{{ field }}:
    #             raise ValidationError(
    #                 _("{{ field }} is required for record '%s'.") % rec.name
    #             )

    # =========================================================================
    # 8. CRUD methods
    # =========================================================================
    @api.model_create_multi
    def create(self, vals_list):
        # Add custom logic before creation
        return super().create(vals_list)

    def write(self, vals):
        # Add custom logic before write
        return super().write(vals)

    def unlink(self):
        for rec in self:
            if rec.state not in ("draft", "cancelled"):
                raise UserError(
                    _("Cannot delete record '%s' in state '%s'.")
                    % (rec.name, rec.state)
                )
        return super().unlink()

    # =========================================================================
    # 9. Action methods (buttons)
    # =========================================================================
    def action_confirm(self):
        """Confirm the record."""
        for rec in self:
            if rec.state != "draft":
                raise UserError(_("Only draft records can be confirmed."))
            rec.state = "confirmed"

    def action_done(self):
        """Mark the record as done."""
        for rec in self:
            rec.state = "done"

    def action_cancel(self):
        """Cancel the record."""
        for rec in self:
            rec.state = "cancelled"

    def action_reset_to_draft(self):
        """Reset to draft state."""
        for rec in self:
            rec.state = "draft"

    # =========================================================================
    # 10. Private/Business methods
    # =========================================================================
    # def _prepare_{{ related_record }}(self):
    #     """Prepare values for creating a related record."""
    #     self.ensure_one()
    #     return {
    #         "name": self.name,
    #         "origin_id": self.id,
    #     }
