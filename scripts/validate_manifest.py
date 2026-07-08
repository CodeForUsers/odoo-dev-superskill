#!/usr/bin/env python3
"""Validate an Odoo module's __manifest__.py file.

Checks for:
- Required keys presence (name, version, depends, etc.)
- Version format (MAJOR.MINOR.PATCH.BUILD or 5-segment OCA format)
- Valid license values
- Valid development_status values
- Data files existence
- Security file presence

Usage:
    python validate_manifest.py [path_to_module]

Exit codes:
    0 — All checks passed.
    1 — One or more checks failed.
"""

import ast
import os
import sys

# Required manifest keys
REQUIRED_KEYS = {"name", "version"}

# Recommended manifest keys
RECOMMENDED_KEYS = {
    "category",
    "summary",
    "author",
    "website",
    "license",
    "depends",
    "data",
}

# Valid license values (Odoo standard)
VALID_LICENSES = {
    "GPL-2",
    "GPL-2 or later",
    "GPL-3",
    "GPL-3 or later",
    "AGPL-3",
    "LGPL-3",
    "Other OSI approved licence",
    "OEEL-1",
    "OPL-1",
    "Other proprietary",
}

# Valid development_status values (OCA)
VALID_STATUSES = {"Alpha", "Beta", "Production/Stable", "Mature"}

# Version regex: ODOO_MAJOR.ODOO_MINOR.MOD_MAJOR.MOD_MINOR.MOD_PATCH
VERSION_PATTERN = r"^\d+\.\d+\.\d+\.\d+\.\d+$"


class ManifestValidator:
    """Validates an Odoo module manifest."""

    def __init__(self, module_path):
        self.module_path = os.path.abspath(module_path)
        self.manifest_path = os.path.join(self.module_path, "__manifest__.py")
        self.manifest = None
        self.errors = []
        self.warnings = []

    def validate(self):
        """Run all validation checks.

        Returns:
            bool: True if all checks pass (no errors), False otherwise.
        """
        if not self._load_manifest():
            return False

        self._check_required_keys()
        self._check_recommended_keys()
        self._check_version_format()
        self._check_license()
        self._check_development_status()
        self._check_data_files_exist()
        self._check_security_file()
        self._check_depends()
        self._check_installable()

        return len(self.errors) == 0

    def _load_manifest(self):
        """Load and parse the manifest file."""
        if not os.path.isfile(self.manifest_path):
            self.errors.append(
                f"Manifest file not found: {self.manifest_path}"
            )
            return False

        try:
            with open(self.manifest_path, "r", encoding="utf-8") as f:
                content = f.read()

            self.manifest = ast.literal_eval(content)

            if not isinstance(self.manifest, dict):
                self.errors.append(
                    "Manifest must be a Python dictionary literal."
                )
                return False

            return True

        except (SyntaxError, ValueError) as e:
            self.errors.append(f"Could not parse manifest: {e}")
            return False

    def _check_required_keys(self):
        """Check that all required keys are present."""
        for key in REQUIRED_KEYS:
            if key not in self.manifest:
                self.errors.append(f"Missing required key: '{key}'")

    def _check_recommended_keys(self):
        """Check that recommended keys are present."""
        for key in RECOMMENDED_KEYS:
            if key not in self.manifest:
                self.warnings.append(f"Missing recommended key: '{key}'")

    def _check_version_format(self):
        """Check the version format."""
        import re

        version = self.manifest.get("version", "")
        if not version:
            return  # Already caught by required keys check

        if not re.match(VERSION_PATTERN, version):
            self.errors.append(
                f"Invalid version format: '{version}'. "
                f"Expected: ODOO_MAJOR.ODOO_MINOR.MOD_MAJOR.MOD_MINOR.MOD_PATCH "
                f"(e.g., '18.0.1.0.0')"
            )

    def _check_license(self):
        """Check that the license is a valid value."""
        license_val = self.manifest.get("license")
        if license_val and license_val not in VALID_LICENSES:
            self.warnings.append(
                f"Non-standard license: '{license_val}'. "
                f"Valid values: {sorted(VALID_LICENSES)}"
            )

    def _check_development_status(self):
        """Check that development_status is a valid value."""
        status = self.manifest.get("development_status")
        if status and status not in VALID_STATUSES:
            self.errors.append(
                f"Invalid development_status: '{status}'. "
                f"Valid values: {sorted(VALID_STATUSES)}"
            )

    def _check_data_files_exist(self):
        """Check that all referenced data files actually exist."""
        for key in ("data", "demo"):
            files = self.manifest.get(key, [])
            if not isinstance(files, list):
                self.errors.append(f"'{key}' must be a list, got {type(files).__name__}")
                continue

            for filepath in files:
                full_path = os.path.join(self.module_path, filepath)
                if not os.path.isfile(full_path):
                    self.errors.append(
                        f"Data file not found: '{filepath}' (referenced in '{key}')"
                    )

    def _check_security_file(self):
        """Check that security ACL file exists."""
        acl_path = os.path.join(
            self.module_path, "security", "ir.model.access.csv"
        )
        data_files = self.manifest.get("data", [])

        # Check if ACL is referenced in data
        acl_referenced = any(
            "ir.model.access.csv" in f for f in data_files
        )

        if not acl_referenced:
            self.warnings.append(
                "No 'ir.model.access.csv' found in 'data' list. "
                "Every module with models should define ACLs."
            )
        elif not os.path.isfile(acl_path):
            self.errors.append(
                "'security/ir.model.access.csv' is referenced but does not exist."
            )

    def _check_depends(self):
        """Check the depends list."""
        depends = self.manifest.get("depends")
        if depends is None:
            return  # Already caught by recommended keys

        if not isinstance(depends, list):
            self.errors.append(
                f"'depends' must be a list, got {type(depends).__name__}"
            )
            return

        if not depends:
            self.warnings.append(
                "'depends' is empty. Most modules should depend on at least 'base'."
            )

    def _check_installable(self):
        """Check that installable is True."""
        installable = self.manifest.get("installable")
        if installable is False:
            self.warnings.append(
                "'installable' is False. The module will not appear "
                "in the Apps list."
            )
        elif installable is None:
            self.warnings.append(
                "'installable' key is missing. It defaults to True, "
                "but should be explicit."
            )

    def print_report(self, json_output=False):
        """Print the validation report."""
        if json_output:
            import json
            print(json.dumps({
                "errors": self.errors,
                "warnings": self.warnings,
                "summary": {
                    "errors": len(self.errors),
                    "warnings": len(self.warnings),
                    "success": len(self.errors) == 0
                }
            }, indent=2))
            return

        module_name = os.path.basename(self.module_path)
        print(f"\n{'=' * 60}")
        print(f"Manifest Validation Report: {module_name}")
        print(f"{'=' * 60}")

        if self.errors:
            print(f"\n❌ ERRORS ({len(self.errors)}):")
            for error in self.errors:
                print(f"  • {error}")

        if self.warnings:
            print(f"\n⚠️  WARNINGS ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"  • {warning}")

        if not self.errors and not self.warnings:
            print("\n✅ All checks passed!")
        elif not self.errors:
            print(f"\n✅ No errors found ({len(self.warnings)} warnings).")
        else:
            print(f"\n❌ Validation FAILED ({len(self.errors)} errors, "
                  f"{len(self.warnings)} warnings).")

        print(f"{'=' * 60}\n")


def main():
    """Main entry point."""
    path = os.getcwd()
    json_output = False

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--json":
            json_output = True
            i += 1
        elif not args[i].startswith("-"):
            path = args[i]
            i += 1
        else:
            i += 1

    validator = ManifestValidator(path)
    success = validator.validate()
    validator.print_report(json_output=json_output)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
