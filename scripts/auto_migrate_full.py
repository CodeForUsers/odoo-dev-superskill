#!/usr/bin/env python3
"""Orchestrator script for full Odoo module migration.

Executes both code pattern migration and commit porting in a single pipeline.
Usage:
    python auto_migrate_full.py --source origin/16.0 --target origin/18.0 --module my_module --repo ./
"""

import argparse
import os
import subprocess
import sys

def main():
    parser = argparse.ArgumentParser(description="Full Migration Pipeline (Code Patterns + Port Commits)")
    parser.add_argument("--source", required=True, help="Source branch (e.g., origin/16.0)")
    parser.add_argument("--target", required=True, help="Target branch (e.g., origin/18.0)")
    parser.add_argument("--module", required=True, help="Module name")
    parser.add_argument("--repo", required=True, help="Path to the repository")
    args = parser.parse_args()

    print("=" * 70)
    print("🚀 FULL ODOO MIGRATION PIPELINE")
    print("=" * 70)
    
    # Extract raw version numbers from branch names (e.g. 'origin/16.0' -> '16.0')
    source_ver = args.source.split('/')[-1]
    target_ver = args.target.split('/')[-1]

    print(f"\n[1/3] 🔍 Detecting Odoo versions...")
    print(f"  ✅ Source version: {source_ver}")
    print(f"  ✅ Target version: {target_ver}")

    script_dir = os.path.dirname(os.path.abspath(__file__))

    print(f"\n[2/3] 🔄 Migrating code patterns...")
    try:
        subprocess.run([
            sys.executable,
            os.path.join(script_dir, "migrate_code_patterns.py"),
            "--source", source_ver,
            "--target", target_ver,
            "--module", args.module,
            "--repo", args.repo
        ], check=True)
        print("  ✅ Code pattern migration completed")
    except subprocess.CalledProcessError:
        print("\n❌ Migration Pipeline Failed during code pattern migration.")
        sys.exit(1)

    print(f"\n[3/3] 📮 Porting commits...")
    try:
        # For a full automated migration, we assume they want to apply changes
        subprocess.run([
            sys.executable,
            os.path.join(script_dir, "port_addon.py"),
            "--source", args.source,
            "--target", args.target,
            "--module", os.path.join(args.repo, args.module) if not args.module.startswith(".") and not args.module.startswith("/") else args.module,
            "--no-dry-run",
            "--verbose"
        ], check=True)
        print("  ✅ Porting completed")
    except subprocess.CalledProcessError:
        print("\n❌ Migration Pipeline Failed during commit porting.")
        sys.exit(1)

    print("\n" + "=" * 70)
    print("✅ MIGRATION SUCCESSFULLY COMPLETED")
    print("=" * 70)

if __name__ == "__main__":
    main()
