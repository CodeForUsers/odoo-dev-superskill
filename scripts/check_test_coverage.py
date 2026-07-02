#!/usr/bin/env python3
"""Check test coverage for an Odoo module.

Verifies that:
- A tests/ directory exists with __init__.py.
- Test files exist for models defined in the module.
- Basic test patterns are present (TransactionCase, test methods).
- Tests cover CRUD operations, compute methods, and constrains.

Usage:
    python check_test_coverage.py [path_to_module]

Exit codes:
    0 — Adequate test coverage found.
    1 — Insufficient test coverage.
"""

import ast
import os
import re
import sys


class TestCoverageChecker:
    """Checks test coverage for an Odoo module."""

    def __init__(self, module_path):
        self.module_path = os.path.abspath(module_path)
        self.models_found = []
        self.test_files = []
        self.test_classes = []
        self.test_methods = []
        self.errors = []
        self.warnings = []
        self.info = []

    def check(self):
        """Run all coverage checks.

        Returns:
            bool: True if minimum coverage is met, False otherwise.
        """
        self._find_models()
        self._find_tests()
        self._analyze_test_coverage()

        return len(self.errors) == 0

    def _find_models(self):
        """Find all model definitions in the module."""
        models_dir = os.path.join(self.module_path, "models")
        if not os.path.isdir(models_dir):
            # Try root directory
            models_dir = self.module_path

        for root, _dirs, files in os.walk(models_dir):
            for filename in files:
                if not filename.endswith(".py") or filename.startswith("__"):
                    continue

                filepath = os.path.join(root, filename)
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        content = f.read()

                    tree = ast.parse(content)
                    for node in ast.walk(tree):
                        if isinstance(node, ast.ClassDef):
                            # Look for _name assignment
                            for item in node.body:
                                if (
                                    isinstance(item, ast.Assign)
                                    and len(item.targets) == 1
                                    and isinstance(item.targets[0], ast.Name)
                                    and item.targets[0].id == "_name"
                                    and isinstance(item.value, ast.Constant)
                                ):
                                    self.models_found.append({
                                        "class_name": node.name,
                                        "model_name": item.value.value,
                                        "file": os.path.relpath(
                                            filepath, self.module_path
                                        ),
                                    })

                except (SyntaxError, OSError):
                    continue

    def _find_tests(self):
        """Find all test files and extract test classes/methods."""
        tests_dir = os.path.join(self.module_path, "tests")

        if not os.path.isdir(tests_dir):
            self.errors.append(
                "No 'tests/' directory found. Every module should have tests."
            )
            return

        init_path = os.path.join(tests_dir, "__init__.py")
        if not os.path.isfile(init_path):
            self.errors.append(
                "'tests/__init__.py' not found. Tests won't be discovered."
            )
            return

        # Check __init__.py imports
        try:
            with open(init_path, "r", encoding="utf-8") as f:
                init_content = f.read()
        except OSError:
            init_content = ""

        for root, _dirs, files in os.walk(tests_dir):
            for filename in files:
                if not filename.startswith("test_") or not filename.endswith(".py"):
                    continue

                filepath = os.path.join(root, filename)
                rel_path = os.path.relpath(filepath, self.module_path)
                self.test_files.append(rel_path)

                # Check if imported in __init__.py
                module_name = filename[:-3]  # Remove .py
                if module_name not in init_content:
                    self.warnings.append(
                        f"Test file '{filename}' may not be imported in "
                        f"tests/__init__.py"
                    )

                # Parse test file
                self._parse_test_file(filepath)

    def _parse_test_file(self, filepath):
        """Parse a test file to extract classes and methods."""
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()

            tree = ast.parse(content)

            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    # Check if it inherits from a test class
                    base_names = []
                    for base in node.bases:
                        if isinstance(base, ast.Name):
                            base_names.append(base.name)
                        elif isinstance(base, ast.Attribute):
                            base_names.append(base.attr)

                    test_bases = {
                        "TransactionCase",
                        "SavepointCase",
                        "HttpCase",
                        "SingleTransactionCase",
                    }

                    if any(b in test_bases for b in base_names):
                        rel_path = os.path.relpath(filepath, self.module_path)
                        self.test_classes.append({
                            "name": node.name,
                            "file": rel_path,
                            "base": [b for b in base_names if b in test_bases][0],
                        })

                        # Find test methods
                        for item in node.body:
                            if (
                                isinstance(item, ast.FunctionDef)
                                and item.name.startswith("test_")
                            ):
                                self.test_methods.append({
                                    "name": item.name,
                                    "class": node.name,
                                    "file": rel_path,
                                })

        except (SyntaxError, OSError):
            pass

    def _analyze_test_coverage(self):
        """Analyze if tests adequately cover the models."""
        if not self.models_found:
            self.info.append("No models with _name found in this module.")
            return

        if not self.test_files:
            self.errors.append(
                "No test files found (files starting with 'test_')."
            )
            return

        if not self.test_classes:
            self.errors.append(
                "No test classes inheriting from TransactionCase/HttpCase found."
            )
            return

        if not self.test_methods:
            self.errors.append(
                "No test methods (starting with 'test_') found in test classes."
            )
            return

        # Check basic CRUD test patterns
        method_names = " ".join(m["name"] for m in self.test_methods)

        crud_patterns = {
            "create": r"test_\w*create\w*",
            "read": r"test_\w*read\w*|test_\w*get\w*|test_\w*search\w*",
            "write": r"test_\w*write\w*|test_\w*update\w*",
            "unlink": r"test_\w*unlink\w*|test_\w*delete\w*",
        }

        for operation, pattern in crud_patterns.items():
            if not re.search(pattern, method_names, re.IGNORECASE):
                self.warnings.append(
                    f"No test found for '{operation}' operation. "
                    f"Consider adding a test_*{operation}* method."
                )

        # Check for compute test patterns
        if not re.search(r"test_\w*comput\w*|test_\w*calc\w*", method_names, re.IGNORECASE):
            self.warnings.append(
                "No test found for compute methods. "
                "Consider adding test_*compute* methods."
            )

        # Check for constraint test patterns
        if not re.search(r"test_\w*constrain\w*|test_\w*valid\w*|test_\w*check\w*",
                          method_names, re.IGNORECASE):
            self.warnings.append(
                "No test found for constraints/validations. "
                "Consider testing that ValidationError is raised correctly."
            )

        # Summary stats
        self.info.append(f"Models found: {len(self.models_found)}")
        self.info.append(f"Test files: {len(self.test_files)}")
        self.info.append(f"Test classes: {len(self.test_classes)}")
        self.info.append(f"Test methods: {len(self.test_methods)}")

        # Calculate coverage percentage (heuristic based on 3 tests per model)
        expected_tests = len(self.models_found) * 3
        if expected_tests > 0:
            coverage_pct = min(100.0, (len(self.test_methods) / expected_tests) * 100.0)
        else:
            coverage_pct = 100.0 if self.test_methods else 0.0

        self.info.append(f"Estimated Test Coverage: {coverage_pct:.1f}%")

        if coverage_pct < 80.0:
            self.errors.append(
                f"Test coverage is below 80% ({coverage_pct:.1f}%). "
                f"Found {len(self.test_methods)} tests for {len(self.models_found)} models. "
                f"Require at least 3 tests per model."
            )

    def print_report(self):
        """Print the coverage report."""
        module_name = os.path.basename(self.module_path)

        print(f"\n{'=' * 60}")
        print(f"Test Coverage Report: {module_name}")
        print(f"{'=' * 60}")

        if self.info:
            print(f"\nℹ️  INFO:")
            for item in self.info:
                print(f"  • {item}")

        if self.models_found:
            print(f"\n📦 Models ({len(self.models_found)}):")
            for model in self.models_found:
                print(f"  • {model['model_name']} ({model['class_name']}) — {model['file']}")

        if self.test_classes:
            print(f"\n🧪 Test Classes ({len(self.test_classes)}):")
            for tc in self.test_classes:
                print(f"  • {tc['name']} ({tc['base']}) — {tc['file']}")

        if self.test_methods:
            print(f"\n🔬 Test Methods ({len(self.test_methods)}):")
            for tm in self.test_methods:
                print(f"  • {tm['class']}.{tm['name']}")

        if self.errors:
            print(f"\n❌ ERRORS ({len(self.errors)}):")
            for error in self.errors:
                print(f"  • {error}")

        if self.warnings:
            print(f"\n⚠️  WARNINGS ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"  • {warning}")

        if not self.errors and not self.warnings:
            print("\n✅ Test coverage looks adequate!")
        elif not self.errors:
            print(f"\n✅ Basic coverage met ({len(self.warnings)} warnings).")
        else:
            print(f"\n❌ Insufficient coverage ({len(self.errors)} errors, "
                  f"{len(self.warnings)} warnings).")

        print(f"{'=' * 60}\n")


def main():
    """Main entry point."""
    path = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()

    checker = TestCoverageChecker(path)
    success = checker.check()
    checker.print_report()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
