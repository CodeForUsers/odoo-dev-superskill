#!/usr/bin/env python3
"""Check for common anti-patterns in Odoo module code.

Scans Python and XML files for known anti-patterns including:
- cr.commit() outside migrations/crons
- Bare except clauses (except: pass)
- SQL injection via string concatenation
- Direct use of deprecated record._cr, record._uid, record._context
- Use of <tree> in Odoo 18.0+ modules
- Use of deprecated methods (name_get, read_group) in newer versions

Usage:
    python check_anti_patterns.py [path_to_module] [--version VERSION]

Exit codes:
    0 — No anti-patterns found.
    1 — One or more anti-patterns detected.
"""

import ast
import os
import re
import sys

# Import version detection from sibling script
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)
try:
    from detect_odoo_version import detect_odoo_version
except ImportError:
    detect_odoo_version = None


class AntiPatternChecker:
    """Scans Odoo module files for anti-patterns."""

    def __init__(self, module_path, odoo_version=None):
        self.module_path = os.path.abspath(module_path)
        self.odoo_version = odoo_version
        self.findings = []

    def check_all(self):
        """Run all checks on the module."""
        # Detect version if not provided
        if not self.odoo_version and detect_odoo_version:
            self.odoo_version = detect_odoo_version(self.module_path)

        # Scan Python files
        for filepath in self._find_files("*.py"):
            self._check_python_file(filepath)

        # Scan XML files
        for filepath in self._find_files("*.xml"):
            self._check_xml_file(filepath)

        return len(self.findings) == 0

    def _find_files(self, pattern):
        """Find files matching a glob pattern recursively."""
        import fnmatch

        for root, _dirs, files in os.walk(self.module_path):
            # Skip hidden directories and __pycache__
            if any(
                part.startswith(".") or part == "__pycache__"
                for part in root.split(os.sep)
            ):
                continue

            for filename in files:
                if fnmatch.fnmatch(filename, pattern):
                    yield os.path.join(root, filename)

    def _add_finding(self, filepath, line_num, severity, message):
        """Add a finding to the results."""
        rel_path = os.path.relpath(filepath, self.module_path)
        self.findings.append({
            "file": rel_path,
            "line": line_num,
            "severity": severity,
            "message": message,
        })

    def _check_python_file(self, filepath):
        """Check a Python file for anti-patterns."""
        # Skip migration scripts (cr.commit is allowed there)
        rel_path = os.path.relpath(filepath, self.module_path)
        is_migration = "migrations/" in rel_path or "migration" in os.path.basename(filepath)

        try:
            with open(filepath, "r", encoding="utf-8") as f:
                lines = f.readlines()
        except (OSError, UnicodeDecodeError):
            return

        for i, line in enumerate(lines, start=1):
            stripped = line.strip()

            # Skip comments
            if stripped.startswith("#"):
                continue

            # 1. cr.commit() outside migrations
            if not is_migration and re.search(
                r"\bcr\.commit\s*\(\s*\)", stripped
            ):
                self._add_finding(
                    filepath, i, "ERROR",
                    "cr.commit() found outside migration script. "
                    "Never use cr.commit() in business logic."
                )

            # 2. Bare except
            if re.match(r"^\s*except\s*:\s*$", line):
                self._add_finding(
                    filepath, i, "ERROR",
                    "Bare 'except:' clause. Always catch specific exceptions."
                )

            # 3. except + pass (swallowing errors)
            if re.match(r"^\s*except\s+\w*.*:\s*$", line):
                # Check if next non-empty line is just 'pass'
                for j in range(i, min(i + 3, len(lines))):
                    next_line = lines[j].strip()
                    if next_line and next_line != "":
                        if next_line == "pass":
                            self._add_finding(
                                filepath, i, "WARNING",
                                "'except: pass' pattern. Errors should be "
                                "logged or re-raised, not silently swallowed."
                            )
                        break

            # 4. SQL injection via string concatenation
            if re.search(
                r'cr\.execute\s*\(\s*["\'].*["\']\s*%\s*\(', stripped
            ) or re.search(
                r'cr\.execute\s*\(\s*["\'].*["\']\s*\+', stripped
            ) or re.search(
                r'cr\.execute\s*\(\s*f["\']', stripped
            ):
                self._add_finding(
                    filepath, i, "ERROR",
                    "Potential SQL injection: string formatting/concatenation "
                    "in cr.execute(). Use parameterized queries or SQL() wrapper."
                )

            # 5. Deprecated record._cr, record._uid, record._context (19.0+)
            if self.odoo_version and self.odoo_version >= "19.0":
                if re.search(r'\bself\._cr\b', stripped):
                    self._add_finding(
                        filepath, i, "WARNING",
                        "self._cr is deprecated in 19.0. Use self.env.cr instead."
                    )
                if re.search(r'\bself\._uid\b', stripped):
                    self._add_finding(
                        filepath, i, "WARNING",
                        "self._uid is deprecated in 19.0. Use self.env.uid instead."
                    )
                if re.search(r'\bself\._context\b', stripped):
                    self._add_finding(
                        filepath, i, "WARNING",
                        "self._context is deprecated in 19.0. "
                        "Use self.env.context instead."
                    )

            # 6. Deprecated name_get (17.0+)
            if self.odoo_version and self.odoo_version >= "17.0":
                if re.search(r'\bdef\s+name_get\s*\(', stripped):
                    self._add_finding(
                        filepath, i, "WARNING",
                        f"name_get() is deprecated in {self.odoo_version}. "
                        "Use _compute_display_name instead."
                    )

            # 7. Deprecated read_group (18.0+)
            if self.odoo_version and self.odoo_version >= "18.0":
                if re.search(r'\.read_group\s*\(', stripped):
                    self._add_finding(
                        filepath, i, "WARNING",
                        "read_group() is deprecated in 18.0+. "
                        "Use _read_group() or formatted_read_group() instead."
                    )

            # 8. Using sudo() without apparent reason
            sudo_count = stripped.count(".sudo()")
            if sudo_count > 1:
                self._add_finding(
                    filepath, i, "WARNING",
                    f"Multiple sudo() calls ({sudo_count}) on one line. "
                    "Review if all are necessary."
                )

    def _check_xml_file(self, filepath):
        """Check an XML file for anti-patterns."""
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                lines = f.readlines()
        except (OSError, UnicodeDecodeError):
            return

        for i, line in enumerate(lines, start=1):
            # 1. <tree> in 18.0+ modules
            if self.odoo_version and self.odoo_version >= "18.0":
                if re.search(r"<tree\b", line) and not line.strip().startswith("<!--"):
                    self._add_finding(
                        filepath, i, "ERROR",
                        f"<tree> tag found in Odoo {self.odoo_version} module. "
                        "Must use <list> instead (breaking change in 18.0)."
                    )
                if re.search(r"</tree>", line) and not line.strip().startswith("<!--"):
                    self._add_finding(
                        filepath, i, "ERROR",
                        f"</tree> closing tag found in Odoo {self.odoo_version} module. "
                        "Must use </list> instead."
                    )

            # 2. <list> in 16.0/17.0 modules
            if self.odoo_version and self.odoo_version in ("16.0", "17.0"):
                if re.search(r"<list\b", line) and not line.strip().startswith("<!--"):
                    self._add_finding(
                        filepath, i, "ERROR",
                        f"<list> tag found in Odoo {self.odoo_version} module. "
                        "Must use <tree> instead (<list> is only for 18.0+)."
                    )

            # 3. view_mode with 'tree' in 18.0+
            if self.odoo_version and self.odoo_version >= "18.0":
                if re.search(r'view_mode.*tree', line, re.IGNORECASE):
                    self._add_finding(
                        filepath, i, "WARNING",
                        "view_mode contains 'tree'. "
                        "In 18.0+ use 'list' instead of 'tree'."
                    )

            # 4. Old-style attrs (deprecated in 17.0+)
            if self.odoo_version and self.odoo_version >= "17.0":
                if re.search(r'\battrs\s*=\s*["\']', line):
                    self._add_finding(
                        filepath, i, "WARNING",
                        "'attrs' attribute is deprecated in 17.0+. "
                        "Use direct attributes (invisible, readonly, required) instead."
                    )

    def print_report(self):
        """Print the findings report."""
        module_name = os.path.basename(self.module_path)
        version_str = self.odoo_version or "unknown"

        print(f"\n{'=' * 60}")
        print(f"Anti-Pattern Check Report: {module_name} (Odoo {version_str})")
        print(f"{'=' * 60}")

        if not self.findings:
            print("\n✅ No anti-patterns found!")
            print(f"{'=' * 60}\n")
            return

        errors = [f for f in self.findings if f["severity"] == "ERROR"]
        warnings = [f for f in self.findings if f["severity"] == "WARNING"]

        if errors:
            print(f"\n❌ ERRORS ({len(errors)}):")
            for finding in errors:
                print(
                    f"  {finding['file']}:{finding['line']} — "
                    f"{finding['message']}"
                )

        if warnings:
            print(f"\n⚠️  WARNINGS ({len(warnings)}):")
            for finding in warnings:
                print(
                    f"  {finding['file']}:{finding['line']} — "
                    f"{finding['message']}"
                )

        print(f"\n{'=' * 60}")
        print(
            f"Total: {len(errors)} errors, {len(warnings)} warnings"
        )
        print(f"{'=' * 60}\n")


def main():
    """Main entry point."""
    # Parse arguments
    path = os.getcwd()
    version = None

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--version" and i + 1 < len(args):
            version = args[i + 1]
            i += 2
        elif not args[i].startswith("-"):
            path = args[i]
            i += 1
        else:
            i += 1

    checker = AntiPatternChecker(path, odoo_version=version)
    success = checker.check_all()
    checker.print_report()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
