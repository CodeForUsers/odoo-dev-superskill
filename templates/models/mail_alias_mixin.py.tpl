# Mail Alias Mixin Template (Email Receiving) — Odoo 16.0–19.0
# Replace all {{ placeholders }} with actual values.
#
# USAGE:
# 1. Place in {{ module_name }}/models/{{ model_underscore }}.py
# 2. Inherit from 'mail.thread' and 'mail.alias.mixin'
# 3. Add "mail" to "depends" in __manifest__.py

from odoo import models, fields, api


class {{ ModelClassName }}(models.Model):
    _name = '{{ model.name }}'
    _description = '{{ Model Title }}'
    # Inherit mixins to enable chatter and email alias reception
    _inherit = ['mail.thread', 'mail.alias.mixin']

    name = fields.Char(string='Subject', required=True)
    description = fields.Html(string='Email Body')
    email_from = fields.Char(string='From Email')

    # 1. Configure the Alias Mixin
    def _alias_get_creation_values(self):
        """Override to provide default values when creating a record via email."""
        values = super()._alias_get_creation_values()
        values['alias_model_id'] = self.env['ir.model']._get('{{ model.name }}').id
        
        # Optional: Set default values for records created this way
        if self.id:
            values['alias_defaults'] = defaults = ast.literal_eval(self.alias_defaults or "{}")
            # defaults['project_id'] = self.id  # Example
            
        return values

    # 2. Intercept the incoming email to parse it
    @api.model
    def message_new(self, msg_dict, custom_values=None):
        """
        Called when a new email arrives to the alias.
        msg_dict contains the parsed email (subject, body, email_from).
        """
        if custom_values is None:
            custom_values = {}

        # Extract data from the incoming email
        subject = msg_dict.get('subject', 'No Subject')
        email_from = msg_dict.get('email_from')
        body = msg_dict.get('body')

        # Try to find an existing partner matching the email
        partner = self.env['res.partner'].search([('email', '=', email_from)], limit=1)
        
        # Override the values that will be used to create the new record
        custom_values.update({
            'name': subject,
            'description': body,
            'email_from': email_from,
        })
        
        if partner:
            custom_values['partner_id'] = partner.id

        # The super call creates the record and attaches the email to the chatter
        return super().message_new(msg_dict, custom_values)

    # 3. Intercept replies to existing records
    def message_update(self, msg_dict, update_vals=None):
        """
        Called when a reply is received for an existing record.
        """
        if update_vals is None:
            update_vals = {}
            
        # Example: if a user replies, reopen the ticket
        # if self.state == 'closed':
        #     update_vals['state'] = 'open'
            
        return super().message_update(msg_dict, update_vals)
