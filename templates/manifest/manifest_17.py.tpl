# Odoo 17.0 Module Manifest Template
# Replace all {{ placeholders }} with actual values.
{
    "name": "{{ module_title }}",
    "version": "17.0.1.0.0",
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
        # "views/model_views.xml",
        # "data/data.xml",
    ],
    "demo": [
        # "demo/demo.xml",
    ],
    "assets": {
        # Odoo 17.0: assets bundle for OWL 2 components
        # "web.assets_backend": [
        #     "{{ module_name }}/static/src/**/*",
        # ],
    },
    "installable": True,
    "application": False,
    "auto_install": False,
    "development_status": "Alpha",
    # Odoo 17.0 specific:
    # - OWL 2 is the standard frontend framework
    # - name_get() is deprecated; use _compute_display_name instead
    # - SQL() wrapper available for safe query composition
    # - "assets" key is the standard way to register JS/CSS
}
