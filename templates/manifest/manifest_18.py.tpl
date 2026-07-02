# Odoo 18.0 Module Manifest Template
# Replace all {{ placeholders }} with actual values.
{
    "name": "{{ module_title }}",
    "version": "18.0.1.0.0",
    "category": "{{ category }}",
    "summary": "{{ one_line_summary }}",
    "description": """
{{ long_description }}
    """,
    "author": "{{ author_name }}, Odoo Community Association (OCA)",
    "website": "https://github.com/OCA/{{ oca_project }}",
    "license": "LGPL-3",
    "depends": [
        "base",
        # Add dependencies here
    ],
    "data": [
        "security/ir.model.access.csv",
        # "security/security.xml",
        # "views/model_views.xml",  # IMPORTANT: use <list> instead of <tree>
        # "data/data.xml",
    ],
    "demo": [
        # "demo/demo.xml",
    ],
    "assets": {
        # Odoo 18.0: OWL 2, Hoot for testing
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
    # Odoo 18.0 specific:
    # - BREAKING: <tree> is renamed to <list> in all views
    # - BREAKING: view_mode "tree" is renamed to "list"
    # - read_group() is deprecated; use _read_group() instead
    # - Frontend tests use Hoot instead of QUnit
    # - html_editor is split into separate modules
}
