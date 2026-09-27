# Odoo 20.0 Module Manifest Template
# Replace all {{ placeholders }} with actual values.
{
    "name": "{{ module_title }}",
    "version": "20.0.1.0.0",
    "category": "{{ category }}",
    "summary": "{{ one_line_summary }}",
    "description": """
{{ long_description }}
    """,
    "author": "{{ author_name }}, Odoo Community Association (OCA)",
    "website": "https://github.com/OCA/{{ oca_project }}",
    "license": "LGPL-3",
    "depends": [
        # Odoo 20: List direct dependencies only.
        # Do not include 'base' explicitly unless needed.
        # "sale",
        # "account",
    ],
    "data": [
        "security/ir.model.access.csv",
        # "security/security.xml",
        # "views/model_views.xml",  # Use <list> (NOT <tree>)
        # "data/data.xml",
    ],
    "demo": [
        # "demo/demo.xml",
    ],
    "assets": {
        # Odoo 20.0: Organized by feature; Hoot unit/integration tests
        # "web.assets_backend": [
        #     "{{ module_name }}/static/src/**/*",
        # ],
        # "web.assets_unit_tests": [
        #     "{{ module_name }}/static/tests/**/*",  # Hoot tests
        # ],
    },
    "installable": True,
    "application": False,
    "auto_install": False,
    "development_status": "Alpha",
    # Odoo 20.0 specific:
    # - Views: <list> is mandatory (<tree> is obsolete)
    # - Record attributes: 'id' must precede 'model' in <record>
    # - Domain combining: use odoo.fields.Domain (&, |, ~, Domain.AND, Domain.OR)
    # - Translations: use self.env._(...) with static literals and keyword args
    # - Comments & Messages: plain ASCII punctuation only (no em dashes or curly quotes)
    # - Database: use odoo.tools.SQL wrapper for parameterized SQL
    # - Files: open files using odoo.tools.file_open instead of built-in open()
    # - Python runtime: Python 3.11+ (Ubuntu 24.04 / Debian 12)
}
