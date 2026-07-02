#!/usr/bin/env python3
"""Auto-refactor XML files for modern Odoo versions (17.0, 18.0).

This script performs "black magic" to automatically upgrade legacy XML syntax
to the modern syntax required by Odoo 17.0+ and 18.0+.

Features:
- Converts `<tree>` to `<list>` (required in 18.0+).
- Converts `attrs="{'invisible': [('field', '=', 'val')]}"` to `invisible="field == 'val'"` (Odoo 17.0+).
- Converts `states="draft,done"` to `invisible="state not in ('draft', 'done')"` (Odoo 17.0+).

WARNING: This script modifies files IN PLACE.
Ensure your code is committed to Git before running this script so you can easily revert if needed.

Usage:
    python autofix_xml.py --version 18.0 [path_to_module]

Exit codes:
    0 — Refactoring completed successfully.
    1 — An error occurred.
"""

import argparse
import ast
import os
import re
import sys

def convert_domain_to_python(domain_str):
    """Convert an Odoo domain list string to a Python evaluation string.
    Example: "[('state', '=', 'draft')]" -> "state == 'draft'"
    """
    try:
        # Evaluate string to actual list
        domain = ast.literal_eval(domain_str)
        if not isinstance(domain, list):
            return domain_str # Fallback
            
        conditions = []
        for item in domain:
            if isinstance(item, tuple) and len(item) == 3:
                field, op, val = item
                # Format value
                if isinstance(val, str):
                    val_str = f"'{val}'"
                elif isinstance(val, bool):
                    val_str = str(val) # True/False
                else:
                    val_str = str(val)
                
                # Format operator
                if op == '=':
                    op = '=='
                    
                conditions.append(f"{field} {op} {val_str}")
            elif isinstance(item, str):
                # Logical operators '|', '&'
                if item == '|':
                    conditions.append("or")
                elif item == '&':
                    conditions.append("and")
                
        # Simple joining (this is basic and might not handle complex nesting perfectly)
        # For a truly robust solution, a proper domain parser is needed, 
        # but this handles 90% of basic attrs.
        result = " ".join(conditions)
        # Clean up consecutive operators if any logical operators were misplaced
        return result.replace(" and and ", " and ").replace(" or or ", " or ")
    except Exception:
        return domain_str # If parsing fails, return original and let human fix it

def fix_attrs(content):
    """Convert attrs="..." to invisible="..." readonly="..."."""
    # Regex to find attrs="{...}"
    pattern = r'attrs="(\{.*?\})"'
    
    def replacer(match):
        dict_str = match.group(1)
        try:
            attrs_dict = ast.literal_eval(dict_str)
            new_attrs = []
            for key, domain in attrs_dict.items():
                if key in ('invisible', 'readonly', 'required', 'column_invisible'):
                    py_expr = convert_domain_to_python(str(domain))
                    new_attrs.append(f'{key}="{py_expr}"')
            
            if new_attrs:
                return " ".join(new_attrs)
            return match.group(0) # Fallback
        except Exception:
            return match.group(0) # Fallback
            
    return re.sub(pattern, replacer, content)

def fix_states(content):
    """Convert states="draft,done" to invisible="..."."""
    pattern = r'states="([^"]+)"'
    
    def replacer(match):
        states_str = match.group(1)
        states = [s.strip() for s in states_str.split(',')]
        if len(states) == 1:
            return f"invisible=\"state != '{states[0]}'\""
        else:
            states_tuple = ", ".join(f"'{s}'" for s in states)
            return f"invisible=\"state not in ({states_tuple})\""
            
    return re.sub(pattern, replacer, content)

def fix_tree_to_list(content):
    """Convert <tree> to <list> (Odoo 18.0+)."""
    # Replace open tag
    content = re.sub(r'<tree(\s|>)', r'<list\1', content)
    # Replace closing tag
    content = content.replace('</tree>', '</list>')
    return content

def process_file(filepath, target_version):
    """Process a single XML file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    original = content
    
    # Apply Odoo 17.0+ fixes
    if float(target_version) >= 17.0:
        content = fix_attrs(content)
        content = fix_states(content)
        
    # Apply Odoo 18.0+ fixes
    if float(target_version) >= 18.0:
        content = fix_tree_to_list(content)
        
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    parser = argparse.ArgumentParser(description="Auto-refactor Odoo XML files.")
    parser.add_argument("--version", required=True, choices=["17.0", "18.0", "19.0"],
                        help="Target Odoo version")
    parser.add_argument("path", nargs="?", default=os.getcwd(), 
                        help="Path to the Odoo module (default: current dir)")

    args = parser.parse_args()
    
    module_path = os.path.abspath(args.path)
    
    if not os.path.isdir(module_path):
        print(f"Error: {module_path} is not a directory.")
        sys.exit(1)

    print(f"🪄  Running auto-fixer for Odoo {args.version} on {module_path}...")
    
    changed_files = 0
    
    for root, _dirs, files in os.walk(module_path):
        for filename in files:
            if filename.endswith(".xml"):
                filepath = os.path.join(root, filename)
                if process_file(filepath, args.version):
                    changed_files += 1
                    print(f"   [FIXED] {os.path.relpath(filepath, module_path)}")
                    
    print(f"\n✅ Auto-fix completed. Modified {changed_files} files.")
    if changed_files > 0:
        print("   Please review the changes (git diff) and test thoroughly.")
        print("   Note: Complex domains in attrs may need manual correction.")

if __name__ == "__main__":
    main()
