# Odoo 19.0 Module Manifest Template
# Replace all {{ placeholders }} with actual values.
{
    "name": "{{ module_title }}",
    "version": "19.0.1.0.0",
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
        # "views/model_views.xml",  # Use <list> (NOT <tree>)
        # "data/data.xml",
    ],
    "demo": [
        # "demo/demo.xml",
    ],
    "assets": {
        # Odoo 19.0: OWL 2 continuation, Hoot testing
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
    # Odoo 19.0 specific:
    # - Views: <list> is the standard (same as 18.0)
    # - record._cr, record._uid, record._context are deprecated
    #   → use self.env.cr, self.env.uid, self.env.context
    # - _search_display_name replaces name_search()
    # - GROUPING SETS support for pivot views
    # - odoo.osv is deprecated
    # - name_get() is removed (use _compute_display_name)
    # - read_group() is removed (use _read_group())
}
