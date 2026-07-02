#!/usr/bin/env python3
"""Extract translatable strings from an Odoo module.

This script parses Python (.py) and XML (.xml) files in the given Odoo module
to find strings that need translation. It generates a basic .pot template file
in the i18n/ directory.

WARNING: This is a basic extractor meant for AI scaffolding.
For production use, use Odoo's built-in export translation feature:
`odoo-bin -d db_name --i18n-export=module.pot --modules=module`

Usage:
    python extract_translations.py [path_to_module]

Exit codes:
    0 — Translations extracted successfully.
    1 — An error occurred.
"""

import ast
import os
import re
import sys
import xml.etree.ElementTree as ET


class TranslationExtractor:
    """Extracts translatable strings from Python and XML files."""

    def __init__(self, module_path):
        self.module_path = os.path.abspath(module_path)
        self.module_name = os.path.basename(self.module_path)
        self.strings = set()  # Set of (string, filepath)

    def extract(self):
        """Run extraction on all supported files."""
        for root, _dirs, files in os.walk(self.module_path):
            # Skip hidden dirs, pycache, i18n
            if any(part.startswith(".") or part in ("__pycache__", "i18n") 
                   for part in root.split(os.sep)):
                continue

            for filename in files:
                filepath = os.path.join(root, filename)
                if filename.endswith(".py"):
                    self._extract_from_python(filepath)
                elif filename.endswith(".xml"):
                    self._extract_from_xml(filepath)

    def _extract_from_python(self, filepath):
        """Extract strings wrapped in _("...") from Python code."""
        rel_path = os.path.relpath(filepath, self.module_path)
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            tree = ast.parse(content)
        except (SyntaxError, OSError):
            return

        for node in ast.walk(tree):
            if isinstance(node, ast.Call):
                if isinstance(node.func, ast.Name) and node.func.id == "_":
                    if node.args and isinstance(node.args[0], ast.Constant):
                        if isinstance(node.args[0].value, str):
                            self.strings.add((node.args[0].value, rel_path))

        # Also extract field string="" and help="" attributes
        # (This requires regex as AST doesn't preserve keyword arg values simply if they are concatenated, 
        # but regex is good enough for a basic scaffold)
        field_pattern = r'(?:string|help)\s*=\s*(["\'])(.*?)\1'
        for match in re.finditer(field_pattern, content):
            if match.group(2):
                self.strings.add((match.group(2), rel_path))

    def _extract_from_xml(self, filepath):
        """Extract string="" and help="" from XML files."""
        rel_path = os.path.relpath(filepath, self.module_path)
        try:
            tree = ET.parse(filepath)
            root = tree.getroot()
        except (ET.ParseError, OSError):
            return

        for elem in root.iter():
            if "string" in elem.attrib:
                self.strings.add((elem.attrib["string"], rel_path))
            if "help" in elem.attrib:
                self.strings.add((elem.attrib["help"], rel_path))

    def generate_pot(self):
        """Generate the .pot file."""
        i18n_dir = os.path.join(self.module_path, "i18n")
        os.makedirs(i18n_dir, exist_ok=True)
        
        pot_path = os.path.join(i18n_dir, f"{self.module_name}.pot")
        
        with open(pot_path, "w", encoding="utf-8") as f:
            f.write(f'# Translation of Odoo Server.\n')
            f.write(f'# This file contains the translation of the following modules:\n')
            f.write(f'# \t* {self.module_name}\n')
            f.write(f'#\n')
            f.write(f'msgid ""\n')
            f.write(f'msgstr ""\n')
            f.write(f'"Project-Id-Version: Odoo Server 17.0\\n"\n')
            f.write(f'"Report-Msgid-Bugs-To: \\n"\n')
            f.write(f'"POT-Creation-Date: 2026-07-02 00:00+0000\\n"\n')
            f.write(f'"PO-Revision-Date: 2026-07-02 00:00+0000\\n"\n')
            f.write(f'"Last-Translator: \\n"\n')
            f.write(f'"Language-Team: \\n"\n')
            f.write(f'"MIME-Version: 1.0\\n"\n')
            f.write(f'"Content-Type: text/plain; charset=UTF-8\\n"\n')
            f.write(f'"Content-Transfer-Encoding: \\n"\n')
            f.write(f'"Plural-Forms: \\n"\n')
            f.write(f'\n')

            # Group by string to show multiple file occurrences
            grouped = {}
            for text, filepath in self.strings:
                if text not in grouped:
                    grouped[text] = []
                grouped[text].append(filepath)

            for text, files in sorted(grouped.items()):
                f.write(f'#. module: {self.module_name}\n')
                for fp in set(files):
                    f.write(f'#: code:addons/{self.module_name}/{fp}\n')
                
                # Escape quotes and newlines
                safe_text = text.replace('"', '\\"').replace('\n', '\\n')
                f.write(f'msgid "{safe_text}"\n')
                f.write(f'msgstr ""\n\n')

        print(f"✅ Extracted {len(grouped)} translatable strings to {pot_path}")


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    
    if not os.path.isfile(os.path.join(path, "__manifest__.py")):
        print(f"Error: '{path}' does not appear to be an Odoo module "
              f"(__manifest__.py not found).", file=sys.stderr)
        sys.exit(1)

    extractor = TranslationExtractor(path)
    extractor.extract()
    extractor.generate_pot()


if __name__ == "__main__":
    main()
