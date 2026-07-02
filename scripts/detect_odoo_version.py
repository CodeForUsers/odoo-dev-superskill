#!/usr/bin/env python3
"""Detect the Odoo version from a module's manifest or environment.

This script searches for version clues in the following order:
1. __manifest__.py — extracts the MAJOR.MINOR prefix from the 'version' key.
2. requirements.txt — looks for 'odoo>=XX' or similar patterns.
3. odoo-bin --version — attempts to run the Odoo binary.
4. If nothing is found, prints a clear message asking the user to specify.

Usage:
    python detect_odoo_version.py [path_to_module_or_project]

If no path is provided, the current working directory is used.

Exit codes:
    0 — Version detected successfully.
    1 — Could not detect version.
"""

import ast
import os
import re
import subprocess
import sys

# Supported Odoo versions
SUPPORTED_VERSIONS = {"16.0", "17.0", "18.0", "19.0"}


def detect_from_manifest(module_path):
    """Detect Odoo version from __manifest__.py.

    Args:
        module_path: Path to the module directory.

    Returns:
        str or None: Detected version (e.g. '18.0') or None.
    """
    manifest_path = os.path.join(module_path, "__manifest__.py")
    if not os.path.isfile(manifest_path):
        return None

    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Parse manifest as a Python literal (dict)
        manifest = ast.literal_eval(content)

        if not isinstance(manifest, dict):
            return None

        version = manifest.get("version", "")
        if not version:
            return None

        # Extract MAJOR.MINOR prefix (e.g. '18.0.1.2.0' -> '18.0')
        match = re.match(r"^(\d+\.\d+)", version)
        if match:
            detected = match.group(1)
            if detected in SUPPORTED_VERSIONS:
                return detected
            else:
                print(
                    f"Warning: Version prefix '{detected}' found in manifest "
                    f"is not in the supported list: {sorted(SUPPORTED_VERSIONS)}",
                    file=sys.stderr,
                )
                return detected

    except (SyntaxError, ValueError) as e:
        print(
            f"Warning: Could not parse {manifest_path}: {e}",
            file=sys.stderr,
        )
    except OSError as e:
        print(
            f"Warning: Could not read {manifest_path}: {e}",
            file=sys.stderr,
        )

    return None


def detect_from_requirements(project_path):
    """Detect Odoo version from requirements.txt.

    Looks for patterns like:
        odoo>=18.0
        odoo==17.0
        odoo~=16.0

    Args:
        project_path: Path to the project directory.

    Returns:
        str or None: Detected version (e.g. '17.0') or None.
    """
    req_path = os.path.join(project_path, "requirements.txt")
    if not os.path.isfile(req_path):
        return None

    try:
        with open(req_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("#") or not line:
                    continue

                # Match patterns: odoo>=18.0, odoo==17.0, odoo~=16.0, odoo>=18
                match = re.match(
                    r"odoo\s*[><=~!]+\s*(\d+)(?:\.(\d+))?", line, re.IGNORECASE
                )
                if match:
                    major = match.group(1)
                    minor = match.group(2) or "0"
                    detected = f"{major}.{minor}"
                    if detected in SUPPORTED_VERSIONS:
                        return detected

    except OSError as e:
        print(
            f"Warning: Could not read {req_path}: {e}",
            file=sys.stderr,
        )

    return None


def detect_from_odoo_bin():
    """Detect Odoo version by running odoo-bin --version.

    Returns:
        str or None: Detected version (e.g. '18.0') or None.
    """
    for cmd in ["odoo-bin", "odoo", "openerp-server"]:
        try:
            result = subprocess.run(
                [cmd, "--version"],
                capture_output=True,
                text=True,
                timeout=10,
            )
            output = result.stdout.strip()
            # Output format: "Odoo Server 18.0" or similar
            match = re.search(r"(\d+\.\d+)", output)
            if match:
                detected = match.group(1)
                if detected in SUPPORTED_VERSIONS:
                    return detected

        except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
            continue

    return None


def detect_odoo_version(path=None):
    """Detect Odoo version using all available strategies.

    Args:
        path: Path to the module or project directory.
              Defaults to the current working directory.

    Returns:
        str or None: Detected version (e.g. '18.0') or None.
    """
    if path is None:
        path = os.getcwd()

    path = os.path.abspath(path)

    if not os.path.isdir(path):
        print(f"Error: '{path}' is not a valid directory.", file=sys.stderr)
        return None

    # Strategy 1: Check __manifest__.py in the given path
    version = detect_from_manifest(path)
    if version:
        return version

    # Strategy 1b: Check parent directory (in case path is a subdirectory)
    parent = os.path.dirname(path)
    if parent != path:
        version = detect_from_manifest(parent)
        if version:
            return version

    # Strategy 2: Check requirements.txt
    version = detect_from_requirements(path)
    if version:
        return version

    # Strategy 2b: Check parent directory for requirements.txt
    if parent != path:
        version = detect_from_requirements(parent)
        if version:
            return version

    # Strategy 3: Try odoo-bin --version
    version = detect_from_odoo_bin()
    if version:
        return version

    return None


def main():
    """Main entry point."""
    # Parse command line arguments
    path = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()

    version = detect_odoo_version(path)

    if version:
        print(f"Detected Odoo version: {version}")
        # Also print version-specific guidance
        if version in ("16.0", "17.0"):
            print(f"  -> Use <tree> for list views (Odoo {version})")
        elif version in ("18.0", "19.0"):
            print(f"  -> Use <list> for list views (Odoo {version})")
        sys.exit(0)
    else:
        print("Could not detect Odoo version automatically.")
        print("Please specify the target version (16.0 / 17.0 / 18.0 / 19.0).")
        sys.exit(1)


if __name__ == "__main__":
    main()
