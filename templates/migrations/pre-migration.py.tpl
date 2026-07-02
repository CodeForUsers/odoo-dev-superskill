# Pre-migration script template — Odoo OpenUpgrade
# Replace {{ placeholders }} with actual values.
#
# USAGE:
#   - Place in: migrations/{{ target_version }}/pre-migration.py
#   - E.g., migrations/18.0.1.0.0/pre-migration.py
#
# PRE-MIGRATION is executed BEFORE the module is updated.
# The old database schema is still intact. New fields do not exist yet.
#
# COMMON TASKS:
#   - Rename tables/columns before Odoo deletes them.
#   - Map old enum values to new ones.
#   - Backup data that Odoo will drop.
#
# OpenUpgrade API: https://github.com/OCA/OpenUpgrade/tree/16.0/openupgradelib

from openupgradelib import openupgrade


@openupgrade.migrate(use_env=True)
def migrate(env, version):
    """Pre-migration logic."""
    if not version:
        return

    # 1. Rename columns (avoids data loss if field was renamed)
    # openupgrade.rename_columns(
    #     env.cr,
    #     {"{{ table_name }}": [
    #         ("old_column_name", "new_column_name"),
    #     ]},
    # )

    # 2. Rename tables
    # openupgrade.rename_tables(
    #     env.cr,
    #     [("old_table_name", "new_table_name")],
    # )

    # 3. Rename models (updates ir_model, ir_model_fields, ir_attachment, etc.)
    # openupgrade.rename_models(
    #     env.cr,
    #     [("old.model.name", "new.model.name")],
    # )

    # 4. Map Selection field values
    # openupgrade.map_values(
    #     env.cr,
    #     openupgrade.get_legacy_name("old_column_name"),
    #     "new_column_name",
    #     [
    #         ("old_val_1", "new_val_1"),
    #         ("old_val_2", "new_val_2"),
    #     ],
    #     table="{{ table_name }}",
    # )
