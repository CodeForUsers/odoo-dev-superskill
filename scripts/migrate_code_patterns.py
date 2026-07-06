#!/usr/bin/env python3
"""Wrapper script for odoo-module-migrator.

Automates code pattern migrations between Odoo versions.
Usage:
    python migrate_code_patterns.py --source 16.0 --target 18.0 --module my_module --repo ./ [--no-commit]
"""

import argparse
import os
import subprocess
import sys

def main():
    parser = argparse.ArgumentParser(description="Migrate code patterns using odoo-module-migrator")
    parser.add_argument("--source", required=True, help="Source Odoo version (e.g., 16.0)")
    parser.add_argument("--target", required=True, help="Target Odoo version (e.g., 18.0)")
    parser.add_argument("--module", required=True, help="Module name to migrate")
    parser.add_argument("--repo", required=True, help="Path to the repository")
    parser.add_argument("--no-commit", action="store_true", help="Do not commit changes")
    args = parser.parse_args()

    # Ensure odoo-module-migrator is installed
    try:
        subprocess.run(
            ["odoo-module-migrate", "--help"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True
        )
    except FileNotFoundError:
        print("❌ Error: 'odoo-module-migrator' is not installed.")
        print("Install it with: pip install git+https://github.com/OCA/odoo-module-migrator.git")
        sys.exit(1)

    print(f"🚀 Starting code migration for '{args.module}' from {args.source} to {args.target}...")

    cmd = [
        "odoo-module-migrate",
        "--directory", args.repo,
        "--modules", args.module,
        "--init-version-name", args.source,
        "--target-version", args.target,
    ]
    if args.no_commit:
        cmd.append("--no-commit")

    try:
        subprocess.run(cmd, check=True)
        print("\n✅ Code pattern migration completed.")
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Error during migration: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
