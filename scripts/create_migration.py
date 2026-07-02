#!/usr/bin/env python3
"""Scaffold OpenUpgrade migration scripts for an Odoo module.

Generates the migrations directory structure and places pre-migration
and post-migration templates for the target version.

Usage:
    python create_migration.py --version <target_version> [path_to_module]

Examples:
    python create_migration.py --version 18.0.1.0.0
    python create_migration.py --version 18.0.1.0.0 /path/to/my_module

Exit codes:
    0 — Scripts created successfully.
    1 — An error occurred.
"""

import argparse
import os
import sys


PRE_MIGRATION_TPL = '''# Pre-migration script (OpenUpgrade)
from openupgradelib import openupgrade

@openupgrade.migrate(use_env=True)
def migrate(env, version):
    if not version:
        return
    # Add pre-migration logic here
'''

POST_MIGRATION_TPL = '''# Post-migration script (OpenUpgrade)
from openupgradelib import openupgrade

@openupgrade.migrate(use_env=True)
def migrate(env, version):
    if not version:
        return
    # Add post-migration logic here
'''


def scaffold_migration(module_path, target_version):
    """Create migration directory and files."""
    module_path = os.path.abspath(module_path)
    
    if not os.path.isfile(os.path.join(module_path, "__manifest__.py")):
        print(f"Error: '{module_path}' does not appear to be an Odoo module "
              f"(__manifest__.py not found).", file=sys.stderr)
        return False

    mig_dir = os.path.join(module_path, "migrations", target_version)
    
    if os.path.exists(mig_dir):
        print(f"Error: Migration directory '{mig_dir}' already exists.", file=sys.stderr)
        return False

    os.makedirs(mig_dir)

    # Write pre-migration.py
    pre_path = os.path.join(mig_dir, "pre-migration.py")
    with open(pre_path, "w", encoding="utf-8") as f:
        f.write(PRE_MIGRATION_TPL)
    
    # Write post-migration.py
    post_path = os.path.join(mig_dir, "post-migration.py")
    with open(post_path, "w", encoding="utf-8") as f:
        f.write(POST_MIGRATION_TPL)

    print(f"✅ Migration scripts scaffolded for version {target_version} in:")
    print(f"   {mig_dir}")
    return True


def main():
    parser = argparse.ArgumentParser(description="Scaffold Odoo migration scripts.")
    parser.add_argument("--version", required=True, 
                        help="Target version (e.g., 18.0.1.0.0)")
    parser.add_argument("path", nargs="?", default=os.getcwd(), 
                        help="Path to the Odoo module (default: current dir)")

    args = parser.parse_args()

    success = scaffold_migration(args.path, args.version)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
