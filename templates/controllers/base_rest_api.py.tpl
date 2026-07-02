# REST API Controller Template (base_rest) — Odoo 16.0–19.0
# Replace all {{ placeholders }} with actual values.
#
# REQUIRES: 'base_rest' from OCA (https://github.com/OCA/rest-framework)
# USAGE:
# 1. Place in {{ module_name }}/controllers/api.py
# 2. Add "base_rest" to "depends" in __manifest__.py
#
# Swagger/OpenAPI docs will be automatically available at:
# http://localhost:8069/api-docs

from odoo.addons.base_rest.controllers import main
from odoo.addons.component.core import Component


# 1. Register the API Endpoint Collection
class {{ ModuleName }}ApiController(main.RestController):
    # This mounts the API at http://localhost:8069/api/{{ api_namespace }}
    _root_path = '/api/{{ api_namespace }}'
    _collection_name = '{{ module_name }}.api.services'
    _default_auth = 'api_key'  # Requires 'auth_api_key' OCA module


# 2. Define the API Service Component
class {{ ModuleName }}ApiService(Component):
    _inherit = 'base.rest.service'
    _name = '{{ module_name }}.api.service'
    _usage = '{{ entity_name }}'
    _collection = '{{ module_name }}.api.services'
    _description = 'API for managing {{ entity_name }} records'

    # 3. GET Method (Search / Read)
    # Accessible via GET /api/{{ api_namespace }}/{{ entity_name }}
    def search(self, name=None):
        """Search for records."""
        domain = []
        if name:
            domain.append(('name', 'ilike', name))
        
        records = self.env['{{ target_model }}'].search(domain, limit=100)
        
        # Build JSON response
        res = []
        for rec in records:
            res.append({
                'id': rec.id,
                'name': rec.name,
                'state': rec.state,
            })
        
        return {'data': res}

    # Define schema for automatic validation and Swagger generation
    # Uses Cerberus validation schema syntax
    def _validator_search(self):
        return {
            'name': {'type': 'string', 'required': False},
        }

    # 4. POST Method (Create)
    # Accessible via POST /api/{{ api_namespace }}/{{ entity_name }}
    def create(self, **params):
        """Create a new record."""
        record = self.env['{{ target_model }}'].create({
            'name': params.get('name'),
            # other fields...
        })
        
        return {
            'success': True,
            'id': record.id,
            'message': f"Created {record.name} successfully."
        }

    def _validator_create(self):
        return {
            'name': {'type': 'string', 'required': True, 'empty': False},
            'description': {'type': 'string', 'required': False},
            'quantity': {'type': 'integer', 'required': False, 'default': 1},
        }
