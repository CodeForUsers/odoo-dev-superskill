# Odoo 16.0 Module Manifest Template
# Replace all {{ placeholders }} with actual values.
{
    "name": "{{ module_title }}",
    "version": "16.0.1.0.0",
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
    "installable": True,
    "application": False,
    "auto_install": False,
    "development_status": "Alpha",
    # Odoo 16.0 specific:
    # - "license" accepts: GPL-2, GPL-2 or later, GPL-3, GPL-3 or later,
    #   AGPL-3, LGPL-3, Other OSI approved licence, OEEL-1, OPL-1, Other proprietary
    # - "development_status" accepts: Alpha, Beta, Production/Stable, Mature
}
