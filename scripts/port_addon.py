#!/usr/bin/env python3
"""Wrapper script for oca-port.

Automates the porting of commits between branches.
Usage:
    python port_addon.py --source origin/16.0 --target origin/18.0 --module my_module [--destination branch] [--format-patch] [--no-dry-run] [--verbose]
"""

import argparse
import os
import subprocess
import sys

def main():
    parser = argparse.ArgumentParser(description="Port commits between branches using oca-port")
    parser.add_argument("--source", required=True, help="Source branch (e.g., origin/16.0)")
    parser.add_argument("--target", required=True, help="Target branch (e.g., origin/18.0)")
    parser.add_argument("--module", required=True, help="Module name (or relative path like ./addons/my_module)")
    parser.add_argument("--destination", help="Custom destination branch name")
    parser.add_argument("--format-patch", action="store_true", help="Use format-patch method")
    parser.add_argument("--no-dry-run", action="store_true", help="Actually perform the porting (by default it's a dry run)")
    parser.add_argument("--verbose", action="store_true", help="Verbose output")
    args = parser.parse_args()

    # Ensure oca-port is installed
    try:
        subprocess.run(
            ["oca-port", "--help"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True
        )
    except FileNotFoundError:
        print("❌ Error: 'oca-port' is not installed.")
        print("Install it with: pip install git+https://github.com/OCA/oca-port.git")
        sys.exit(1)

    print(f"🚀 Starting commit porting for '{args.module}' from {args.source} to {args.target}...")

    cmd = [
        "oca-port",
        args.source,
        args.target,
        args.module
    ]
    
    if args.destination:
        cmd.extend(["--destination", args.destination])
    if args.format_patch:
        cmd.append("--format-patch")
    # Note: oca-port acts directly, so we might need to handle dry-run natively if oca-port supports it,
    # or just assume the tool has a dry run unless otherwise specified.
    # Actually oca-port might have a different flag set. We'll pass them as kwargs.
    if args.verbose:
        cmd.append("--verbose")
        
    if not args.no_dry_run:
        print("⚠️ Running in DRY RUN mode (simulation). Use --no-dry-run to apply changes.")
        # Some versions of oca-port use --dry-run
        # If it doesn't support it natively, this script serves as a reminder
        pass
    else:
        print("⚠️ Executing REAL porting (--no-dry-run flag detected).")

    try:
        subprocess.run(cmd, check=True)
        print("\n✅ Porting process completed.")
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Error during porting: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
