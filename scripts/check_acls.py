#!/usr/bin/env python3
"""Check that all models defined in Python code have ACL entries.

For each model with a _name attribute found in the models/ directory,
this script verifies that the module's ir.model.access.csv file contains
at least one access line for that model.

Usage:
    python check_acls.py [path_to_module]

Exit codes:
    0 — All models have ACL coverage.
    1 — One or more models are missing ACL entries.
"""

import ast
import csv
import os
import sys


class AclChecker:
    """Verifies ACL coverage for all models in an Odoo module."""

    def __init__(self, module_path):
        self.module_path = os.path.abspath(module_path)
        self.models_found = {}   # {model_name: file_path}
        self.acl_models = set()  # model names covered in ir.model.access.csv
        self.errors = []
        self.warnings = []
        self.info = []

    def check(self):
        """Run all ACL checks.

        Returns:
            bool: True if all models have ACL coverage, False otherwise.
        """
        self._find_models()
        self._parse_acl_files()
        self._cross_check()
        return len(self.errors) == 0

    def _find_models(self):
        """Find all models with a _name attribute in Python files."""
        # Look in models/ directory first, then root
        search_dirs = []

        models_dir = os.path.join(self.module_path, "models")
        if os.path.isdir(models_dir):
            search_dirs.append(models_dir)
        else:
            search_dirs.append(self.module_path)

        # Also check wizards/ directory
        wizards_dir = os.path.join(self.module_path, "wizards")
        if os.path.isdir(wizards_dir):
            search_dirs.append(wizards_dir)

        for search_dir in search_dirs:
            for root, _dirs, files in os.walk(search_dir):
                for filename in files:
                    if not filename.endswith(".py") or filename.startswith("__"):
                        continue

                    filepath = os.path.join(root, filename)
                    self._extract_models_from_file(filepath)

    def _extract_models_from_file(self, filepath):
        """Extract model names (_name) from a Python file."""
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()

            tree = ast.parse(content)

        except (SyntaxError, OSError) as e:
            self.warnings.append(f"Could not parse {os.path.relpath(filepath, self.module_path)}: {e}")
            return

        for node in ast.walk(tree):
            if not isinstance(node, ast.ClassDef):
                continue

            model_name = None
            has_inherit = False
            is_abstract = False

            for item in node.body:
                if not isinstance(item, ast.Assign):
                    continue
                if len(item.targets) != 1:
                    continue
                target = item.targets[0]
                if not isinstance(target, ast.Name):
                    continue

                if target.id == "_name" and isinstance(item.value, ast.Constant):
                    model_name = item.value.value

                elif target.id == "_inherit":
                    has_inherit = True

                elif target.id == "_auto" and isinstance(item.value, ast.Constant):
                    if item.value.value is False:
                        is_abstract = True

            # Only report models that define _name (new models, not pure inheritance)
            if model_name and not is_abstract:
                rel_path = os.path.relpath(filepath, self.module_path)
                self.models_found[model_name] = rel_path

    def _parse_acl_files(self):
        """Parse all ir.model.access.csv files in the module."""
        csv_found = False

        for root, _dirs, files in os.walk(self.module_path):
            for filename in files:
                if filename == "ir.model.access.csv":
                    csv_found = True
                    filepath = os.path.join(root, filename)
                    self._parse_acl_file(filepath)

        if not csv_found:
            self.errors.append(
                "No 'ir.model.access.csv' file found in the module. "
                "Every module with models must define ACL entries."
            )

    def _parse_acl_file(self, filepath):
        """Parse a single ACL CSV file."""
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)

                # Handle files with comment lines (starting with #)
                for row in reader:
                    model_ref = row.get("model_id:id", "").strip()

                    if not model_ref or model_ref.startswith("#"):
                        continue

                    # model_id:id format is "model_sale_order_line"
                    # Convert back to "sale.order.line"
                    if model_ref.startswith("model_"):
                        model_name = model_ref[6:].replace("_", ".")
                        self.acl_models.add(model_name)

        except (OSError, csv.Error) as e:
            self.warnings.append(
                f"Could not read ACL file {os.path.relpath(filepath, self.module_path)}: {e}"
            )

    def _cross_check(self):
        """Cross-check models against ACL entries."""
        if not self.models_found:
            self.info.append("No models with _name found in this module.")
            return

        # Models without ACL
        missing = []
        for model_name, source_file in sorted(self.models_found.items()):
            if model_name not in self.acl_models:
                missing.append((model_name, source_file))

        for model_name, source_file in missing:
            self.errors.append(
                f"Model '{model_name}' (in {source_file}) has no ACL entry. "
                f"Add a line to ir.model.access.csv:\n"
                f"      access_{model_name.replace('.', '_')}_user,"
                f"{model_name}.user,"
                f"model_{model_name.replace('.', '_')},"
                f"base.group_user,1,1,1,0"
            )

        # ACL entries for models not in this module's code (unusual, not an error)
        module_prefix = os.path.basename(self.module_path)
        extra_acls = self.acl_models - set(self.models_found.keys())
        if extra_acls:
            # Only warn for models that don't look like they're from a dependency
            for m in sorted(extra_acls):
                self.info.append(
                    f"ACL entry found for '{m}' but no corresponding model in module "
                    f"(may be a dependency model — OK if intentional)."
                )

        # Summary
        self.info.append(f"Models found: {len(self.models_found)}")
        self.info.append(f"ACL entries: {len(self.acl_models)}")
        self.info.append(f"Models without ACL: {len(missing)}")

    def print_report(self, json_output=False):
        """Print the ACL coverage report."""
        if json_output:
            import json
            models_list = []
            for model_name, filepath in sorted(self.models_found.items()):
                models_list.append({
                    "model": model_name,
                    "file": os.path.relpath(filepath, self.module_path),
                    "has_acl": model_name in self.acl_models
                })
            print(json.dumps({
                "models": models_list,
                "errors": self.errors,
                "warnings": self.warnings,
                "info": self.info,
                "summary": {
                    "total_models": len(self.models_found),
                    "total_acls": len(self.acl_models),
                    "errors": len(self.errors),
                    "warnings": len(self.warnings),
                    "success": len(self.errors) == 0
                }
            }, indent=2))
            return

        module_name = os.path.basename(self.module_path)

        print(f"\n{'=' * 60}")
        print(f"ACL Coverage Report: {module_name}")
        print(f"{'=' * 60}")

        if self.models_found:
            print(f"\n📦 Models ({len(self.models_found)}):")
            for model_name, filepath in sorted(self.models_found.items()):
                acl_status = "✅" if model_name in self.acl_models else "❌"
                print(f"  {acl_status} {model_name}  ({filepath})")

        if self.errors:
            print(f"\n❌ ERRORS ({len(self.errors)}):")
            for error in self.errors:
                print(f"  • {error}")

        if self.warnings:
            print(f"\n⚠️  WARNINGS ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"  • {warning}")

        if self.info:
            print(f"\nℹ️  INFO:")
            for item in self.info:
                print(f"  • {item}")

        if not self.errors and not self.warnings:
            print("\n✅ All models have ACL coverage!")
        elif not self.errors:
            print(f"\n✅ ACL coverage complete ({len(self.warnings)} warnings).")
        else:
            print(f"\n❌ ACL coverage INCOMPLETE ({len(self.errors)} errors).")

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

    checker = AclChecker(path)
    success = checker.check()
    checker.print_report(json_output=json_output)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
