# Post-migration script template — Odoo OpenUpgrade
# Replace {{ placeholders }} with actual values.
#
# USAGE:
#   - Place in: migrations/{{ target_version }}/post-migration.py
#   - E.g., migrations/18.0.1.0.0/post-migration.py
#
# POST-MIGRATION is executed AFTER the module is updated.
# The new database schema is in place. New fields exist, old ones (not renamed) are dropped.
#
# COMMON TASKS:
#   - Compute new field values based on old legacy data.
#   - Clean up temporary data or legacy columns.
#   - Recompute stored computed fields if logic changed.
#
# OpenUpgrade API: https://github.com/OCA/OpenUpgrade/tree/16.0/openupgradelib

from openupgradelib import openupgrade


@openupgrade.migrate(use_env=True)
def migrate(env, version):
    """Post-migration logic."""
    if not version:
        return

    # 1. Update data based on legacy columns
    # (assuming pre-migration renamed it using rename_columns)
    # env.cr.execute("""
    #     UPDATE {{ table_name }}
    #     SET new_column_name = (
    #         SELECT id FROM related_table
    #         WHERE old_name = {{ table_name }}.{legacy_col}
    #     )
    #     WHERE {legacy_col} IS NOT NULL
    # """.format(
    #     legacy_col=openupgrade.get_legacy_name("old_column_name")
    # ))

    # 2. Recompute a field for all records if logic changed
    # records = env["{{ model.name }}"].search([])
    # records._compute_my_field()

    # 3. Update view archs manually if automatic migration missed something
    # openupgrade.logged_query(
    #     env.cr,
    #     """
    #     UPDATE ir_ui_view
    #     SET arch_db = REPLACE(arch_db, 'old_string', 'new_string')
    #     WHERE id = %s
    #     """,
    #     [env.ref("{{ module_name }}.view_id").id]
    # )
