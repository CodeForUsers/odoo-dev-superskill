#!/usr/bin/env python3
"""Scaffold a new Odoo module from templates.

Generates a complete, ready-to-use Odoo module directory structure including:
- __manifest__.py
- models/ (with the given model names)
- views/  (form + list/tree depending on version)
- security/ir.model.access.csv
- tests/
- README structure (readme/)

Usage:
    python scaffold_module.py --name <module_name> \\
                               --title "Human Title" \\
                               --version <odoo_version> \\
                               --models model.one model.two \\
                               --output <output_dir>

Examples:
    python scaffold_module.py \\
        --name sale_custom \\
        --title "Sale Customization" \\
        --version 18.0 \\
        --models sale.custom.line sale.custom.header \\
        --output /path/to/addons

    python scaffold_module.py \\
        --name my_module \\
        --version 16.0 \\
        --models my.module.record \\
        --output /path/to/addons

Exit codes:
    0 — Module scaffolded successfully.
    1 — An error occurred.
"""

import argparse
import os
import sys
from datetime import date

# ─── Configuration ────────────────────────────────────────────────────────────

SUPPORTED_VERSIONS = {"16.0", "17.0", "18.0", "19.0"}
CURRENT_YEAR = date.today().year

# ─── Template Strings ─────────────────────────────────────────────────────────

MANIFEST_TEMPLATE = '''{{
    "name": "{module_title}",
    "version": "{odoo_version}.1.0.0",
    "category": "Uncategorized",
    "summary": "Short description of {module_title}.",
    "author": "OCA, Your Name",
    "website": "https://github.com/OCA/",
    "license": "LGPL-3",
    "depends": [
        "base",
        "mail",
    ],
    "data": [
        "security/ir.model.access.csv",
        "security/security.xml",
{views_data}    ],
    "demo": [
        "demo/demo_data.xml",
    ],
    "installable": True,
    "application": False,
    "auto_install": False,
    "development_status": "Alpha",
}}
'''

MODEL_TEMPLATE = '''from odoo import _, api, fields, models
from odoo.exceptions import UserError, ValidationError

import logging

_logger = logging.getLogger(__name__)


class {class_name}(models.Model):
    """{model_description}."""

    _name = "{model_name}"
    _description = "{model_description}"
    _inherit = ["mail.thread", "mail.activity.mixin"]
    _order = "sequence, id"

    # ── Fields ─────────────────────────────────────────────────────────────
    name = fields.Char(string="Name", required=True, tracking=True)
    sequence = fields.Integer(default=10)
    active = fields.Boolean(default=True)
    company_id = fields.Many2one(
        "res.company",
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
        default="draft",
        tracking=True,
    )
    # TODO: add your fields here

    # ── SQL Constraints ─────────────────────────────────────────────────────
    _sql_constraints = [
        (
            "name_unique",
            "UNIQUE(name, company_id)",
            "Name must be unique per company.",
        ),
    ]

    # ── CRUD ────────────────────────────────────────────────────────────────
    @api.model_create_multi
    def create(self, vals_list):
        return super().create(vals_list)

    def unlink(self):
        for rec in self:
            if rec.state not in ("draft", "cancelled"):
                raise UserError(
                    _("Cannot delete record '%s' in state '%s'.")
                    % (rec.name, rec.state)
                )
        return super().unlink()

    # ── Actions ─────────────────────────────────────────────────────────────
    def action_confirm(self):
        for rec in self:
            rec.state = "confirmed"

    def action_cancel(self):
        for rec in self:
            rec.state = "cancelled"

    def action_reset_to_draft(self):
        for rec in self:
            rec.state = "draft"
'''

VIEWS_TEMPLATE_18 = '''<?xml version="1.0" encoding="UTF-8" ?>
<odoo>

    <record id="{module_name}.view_{model_under}_list" model="ir.ui.view">
        <field name="name">{model_name}.list</field>
        <field name="model">{model_name}</field>
        <field name="arch" type="xml">
            <list string="{model_title}" editable="bottom"
                  decoration-success="state == 'done'"
                  decoration-muted="state == 'cancelled'">
                <field name="sequence" widget="handle"/>
                <field name="name"/>
                <field name="state" widget="badge"/>
            </list>
        </field>
    </record>

    <record id="{module_name}.view_{model_under}_form" model="ir.ui.view">
        <field name="name">{model_name}.form</field>
        <field name="model">{model_name}</field>
        <field name="arch" type="xml">
            <form string="{model_title}">
                <header>
                    <button name="action_confirm" type="object" string="Confirm"
                            class="btn-primary" invisible="state != 'draft'"/>
                    <button name="action_cancel" type="object" string="Cancel"
                            invisible="state in ('done', 'cancelled')"/>
                    <button name="action_reset_to_draft" type="object"
                            string="Reset to Draft" invisible="state != 'cancelled'"/>
                    <field name="state" widget="statusbar"
                           statusbar_visible="draft,confirmed,done"/>
                </header>
                <sheet>
                    <div class="oe_title">
                        <h1><field name="name" placeholder="Name..."/></h1>
                    </div>
                    <group>
                        <group>
                            <field name="company_id" groups="base.group_multi_company"/>
                        </group>
                    </group>
                </sheet>
                <div class="oe_chatter">
                    <field name="message_follower_ids"/>
                    <field name="activity_ids"/>
                    <field name="message_ids"/>
                </div>
            </form>
        </field>
    </record>

    <record id="{module_name}.view_{model_under}_search" model="ir.ui.view">
        <field name="name">{model_name}.search</field>
        <field name="model">{model_name}</field>
        <field name="arch" type="xml">
            <search>
                <field name="name"/>
                <filter name="filter_draft" string="Draft" domain="[('state','=','draft')]"/>
                <filter name="filter_done" string="Done" domain="[('state','=','done')]"/>
                <filter name="filter_archived" string="Archived"
                        domain="[('active','=',False)]"/>
                <group expand="0" string="Group By">
                    <filter name="group_state" string="Status"
                            context="{{'group_by': 'state'}}"/>
                </group>
            </search>
        </field>
    </record>

    <record id="{module_name}.action_{model_under}" model="ir.actions.act_window">
        <field name="name">{model_title}</field>
        <field name="res_model">{model_name}</field>
        <field name="view_mode">list,form</field>
    </record>

</odoo>
'''

VIEWS_TEMPLATE_16_17 = VIEWS_TEMPLATE_18.replace(
    '<list string="{model_title}"', '<tree string="{model_title}"'
).replace(
    '</list>', '</tree>'
).replace(
    'view_mode">list,form', 'view_mode">tree,form'
)

ACL_HEADER = "id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink\n"

SECURITY_XML = '''<?xml version="1.0" encoding="UTF-8" ?>
<odoo>
    <data noupdate="0">
        <record id="{module_name}.module_category_{module_name}" model="ir.module.category">
            <field name="name">{module_title}</field>
            <field name="sequence">100</field>
        </record>
        <record id="{module_name}.group_{module_name}_user" model="res.groups">
            <field name="name">User</field>
            <field name="category_id" ref="{module_name}.module_category_{module_name}"/>
            <field name="implied_ids" eval="[(4, ref('base.group_user'))]"/>
        </record>
        <record id="{module_name}.group_{module_name}_manager" model="res.groups">
            <field name="name">Manager</field>
            <field name="category_id" ref="{module_name}.module_category_{module_name}"/>
            <field name="implied_ids" eval="[(4, ref('{module_name}.group_{module_name}_user'))]"/>
            <field name="users" eval="[(4, ref('base.user_root')), (4, ref('base.user_admin'))]"/>
        </record>
    </data>
</odoo>
'''

TEST_TEMPLATE = '''from odoo.tests.common import TransactionCase
from odoo.tests import tagged


@tagged("post_install", "-at_install")
class Test{class_name}(TransactionCase):
    """Tests for {model_name}."""

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.record = cls.env["{model_name}"].create({{
            "name": "Test Record",
            "company_id": cls.env.company.id,
        }})

    def test_create_{model_under}(self):
        """Test: create a record."""
        self.assertTrue(self.record.exists())
        self.assertEqual(self.record.state, "draft")

    def test_action_confirm_{model_under}(self):
        """Test: confirm transitions to confirmed state."""
        self.record.action_confirm()
        self.assertEqual(self.record.state, "confirmed")
'''

README_DESCRIPTION = """{module_title}
{"=" * len(module_title)}

{module_title} module for Odoo {odoo_version}.
"""

# ─── Helpers ──────────────────────────────────────────────────────────────────

def model_to_class_name(model_name):
    """Convert 'sale.order.line' to 'SaleOrderLine'."""
    return "".join(part.capitalize() for part in model_name.replace(".", "_").split("_"))


def model_to_underscore(model_name):
    """Convert 'sale.order.line' to 'sale_order_line'."""
    return model_name.replace(".", "_")


def model_to_title(model_name):
    """Convert 'sale.order.line' to 'Sale Order Line'."""
    return " ".join(part.capitalize() for part in model_name.split("."))


def create_file(path, content, dry_run=False):
    """Create a file with given content."""
    if dry_run:
        print(f"  [DRY RUN] Would create: {path}")
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"  ✅ Created: {os.path.basename(path)}")


# ─── Scaffold Logic ───────────────────────────────────────────────────────────

def scaffold_module(module_name, module_title, odoo_version, models, output_dir, dry_run=False):
    """Generate the complete module structure."""
    base = os.path.join(output_dir, module_name)

    if os.path.exists(base) and not dry_run:
        print(f"❌ Directory already exists: {base}")
        print("   Remove it or choose a different output directory.")
        return False

    print(f"\n🚀 Scaffolding module '{module_name}' (Odoo {odoo_version})...")
    print(f"   Output: {base}\n")

    use_list = odoo_version in ("18.0", "19.0")
    view_tag = "list" if use_list else "tree"
    views_template = VIEWS_TEMPLATE_18 if use_list else VIEWS_TEMPLATE_16_17

    # ── __manifest__.py ────────────────────────────────────────────────────
    views_data_lines = []
    for model_name in models:
        model_under = model_to_underscore(model_name)
        views_data_lines.append(f'        "views/{model_under}_views.xml",')
    views_data = "\n".join(views_data_lines) + "\n"

    manifest = MANIFEST_TEMPLATE.format(
        module_title=module_title,
        odoo_version=odoo_version,
        views_data=views_data,
    )
    create_file(os.path.join(base, "__manifest__.py"), manifest, dry_run)

    # ── __init__.py (root) ─────────────────────────────────────────────────
    root_init = "from . import controllers, models\n"
    create_file(os.path.join(base, "__init__.py"), root_init, dry_run)

    # ── models/ ────────────────────────────────────────────────────────────
    model_imports = "\n".join(
        f"from . import {model_to_underscore(m)}" for m in models
    )
    create_file(os.path.join(base, "models", "__init__.py"), model_imports + "\n", dry_run)

    for model_name in models:
        class_name = model_to_class_name(model_name)
        model_code = MODEL_TEMPLATE.format(
            class_name=class_name,
            model_name=model_name,
            model_description=model_to_title(model_name),
        )
        create_file(
            os.path.join(base, "models", f"{model_to_underscore(model_name)}.py"),
            model_code, dry_run,
        )

    # ── views/ ─────────────────────────────────────────────────────────────
    for model_name in models:
        model_under = model_to_underscore(model_name)
        model_title = model_to_title(model_name)
        view_content = views_template.format(
            module_name=module_name,
            model_name=model_name,
            model_under=model_under,
            model_title=model_title,
        )
        create_file(
            os.path.join(base, "views", f"{model_under}_views.xml"),
            view_content, dry_run,
        )

    # ── security/ ──────────────────────────────────────────────────────────
    acl_lines = [ACL_HEADER]
    for model_name in models:
        model_under = model_to_underscore(model_name)
        acl_lines.append(
            f"access_{model_under}_user,{model_name}.user,"
            f"model_{model_under},{module_name}.group_{module_name}_user,1,1,1,0\n"
        )
        acl_lines.append(
            f"access_{model_under}_manager,{model_name}.manager,"
            f"model_{model_under},{module_name}.group_{module_name}_manager,1,1,1,1\n"
        )

    create_file(
        os.path.join(base, "security", "ir.model.access.csv"),
        "".join(acl_lines), dry_run,
    )
    create_file(
        os.path.join(base, "security", "security.xml"),
        SECURITY_XML.format(module_name=module_name, module_title=module_title),
        dry_run,
    )

    # ── tests/ ─────────────────────────────────────────────────────────────
    test_imports = "\n".join(
        f"from . import test_{model_to_underscore(m)}" for m in models
    )
    create_file(
        os.path.join(base, "tests", "__init__.py"),
        test_imports + "\n", dry_run,
    )
    for model_name in models:
        model_under = model_to_underscore(model_name)
        class_name = model_to_class_name(model_name)
        test_code = TEST_TEMPLATE.format(
            class_name=class_name,
            model_name=model_name,
            model_under=model_under,
        )
        create_file(
            os.path.join(base, "tests", f"test_{model_under}.py"),
            test_code, dry_run,
        )

    # ── controllers/ ───────────────────────────────────────────────────────
    create_file(
        os.path.join(base, "controllers", "__init__.py"),
        "# from . import main\n", dry_run,
    )

    # ── data/ ──────────────────────────────────────────────────────────────
    create_file(
        os.path.join(base, "data", ".gitkeep"),
        "", dry_run,
    )

    # ── demo/ ──────────────────────────────────────────────────────────────
    demo_records = "\n".join(
        f'        <record id="{module_name}.demo_{model_to_underscore(m)}_1" model="{m}">\n'
        f'            <field name="name">Demo {model_to_title(m)} 1</field>\n'
        f'        </record>'
        for m in models
    )
    demo_content = f'<?xml version="1.0" encoding="UTF-8" ?>\n<odoo>\n    <data noupdate="1">\n{demo_records}\n    </data>\n</odoo>\n'
    create_file(os.path.join(base, "demo", "demo_data.xml"), demo_content, dry_run)

    # ── readme/ ────────────────────────────────────────────────────────────
    for filename, content in [
        ("DESCRIPTION.rst", f"{module_title}\n{'=' * len(module_title)}\n\n{module_title} for Odoo {odoo_version}.\n"),
        ("CONFIGURE.rst", "To configure this module, go to Settings → ...\n"),
        ("USAGE.rst", "Go to the main menu and click on ...\n"),
        ("CONTRIBUTORS.rst", "* Your Name <your@email.com>\n"),
    ]:
        create_file(os.path.join(base, "readme", filename), content, dry_run)

    # ── static/ placeholder ────────────────────────────────────────────────
    create_file(os.path.join(base, "static", "description", ".gitkeep"), "", dry_run)

    print(f"\n✅ Module '{module_name}' scaffolded successfully!")
    print(f"   {base}")
    print(f"\n📋 Next steps:")
    print(f"   1. Review and customize the generated models in models/")
    print(f"   2. Add your business logic and views")
    print(f"   3. Run: python scripts/validate_manifest.py {base}")
    print(f"   4. Run: python scripts/check_anti_patterns.py {base} --version {odoo_version}")
    print(f"   5. Set development_status to 'Alpha' in __manifest__.py")
    return True


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Scaffold a new Odoo module from OCA templates.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--name", required=True, help="Technical name (e.g. sale_custom)")
    parser.add_argument("--title", help="Human-readable title (e.g. 'Sale Customization')")
    parser.add_argument(
        "--version", required=True,
        choices=sorted(SUPPORTED_VERSIONS),
        help="Target Odoo version",
    )
    parser.add_argument(
        "--models", nargs="+", required=True,
        help="Model names (e.g. sale.custom.line sale.custom.header)",
    )
    parser.add_argument(
        "--output", default=os.getcwd(),
        help="Output directory (default: current directory)",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Show what would be created without actually creating files",
    )

    args = parser.parse_args()

    module_title = args.title or " ".join(
        part.capitalize() for part in args.name.split("_")
    )

    success = scaffold_module(
        module_name=args.name,
        module_title=module_title,
        odoo_version=args.version,
        models=args.models,
        output_dir=args.output,
        dry_run=args.dry_run,
    )
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
