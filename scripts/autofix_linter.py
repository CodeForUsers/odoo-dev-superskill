#!/usr/bin/env python3
"""Linter Auto-fixer for Odoo Modules.

Executes the repository linters (check_anti_patterns, check_acls) with JSON output,
parses the reports, and automatically applies fixes to code patterns and security files.
"""

import os
import re
import sys
import json
import subprocess

class LinterAutofixer:
    def __init__(self, module_path):
        self.module_path = os.path.abspath(module_path)
        self.script_dir = os.path.dirname(os.path.abspath(__file__))
        
    def run_command(self, script_name, extra_args=None):
        """Execute a validation script and return its JSON output."""
        script_path = os.path.join(self.script_dir, script_name)
        cmd = ["python3", script_path, self.module_path, "--json"]
        if extra_args:
            cmd.extend(extra_args)
            
        result = subprocess.run(cmd, capture_output=True, text=True)
        # We ignore exit code since linters return 1 when finding issues
        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError as e:
            return {}

    def fix_acls(self):
        """Automatically create missing ACL entries for models."""
        print("Checking missing ACLs...")
        report = self.run_command("check_acls.py")
        models = report.get("models", [])
        missing_models = [m for m in models if not m["has_acl"]]
        
        if not missing_models:
            print("✅ No missing ACLs.")
            return True
            
        security_dir = os.path.join(self.module_path, "security")
        os.makedirs(security_dir, exist_ok=True)
        acl_path = os.path.join(security_dir, "ir.model.access.csv")
        
        file_exists = os.path.exists(acl_path)
        write_header = not file_exists or os.path.getsize(acl_path) == 0
        
        new_lines = []
        if write_header:
            new_lines.append("id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink\n")
            
        for m in missing_models:
            model_name = m["model"]
            model_under = model_name.replace(".", "_")
            new_lines.append(f"access_{model_under}_user,model.{model_name},model_{model_under},base.group_user,1,1,1,1\n")
            
        with open(acl_path, "a" if file_exists else "w", encoding="utf-8") as f:
            f.writelines(new_lines)
            
        print(f"✅ Added {len(missing_models)} ACL entries to {os.path.relpath(acl_path, self.module_path)}")
        return True

    def fix_anti_patterns(self):
        """Fix automated Python and XML anti-patterns."""
        print("Checking anti-patterns...")
        report = self.run_command("check_anti_patterns.py")
        findings = report.get("findings", [])
        
        if not findings:
            print("✅ No anti-patterns found.")
            return True
            
        # Group findings by file to prevent reading/writing the same file repeatedly
        files_to_fix = {}
        for f in findings:
            filepath = os.path.join(self.module_path, f["file"])
            if filepath not in files_to_fix:
                files_to_fix[filepath] = []
            files_to_fix[filepath].append(f)
            
        for filepath, file_findings in files_to_fix.items():
            if not os.path.exists(filepath):
                continue
                
            with open(filepath, "r", encoding="utf-8") as file:
                lines = file.readlines()
                
            modified = False
            # Sort findings by line number descending to avoid displacement issues if code size changes
            for f in sorted(file_findings, key=lambda x: x["line"], reverse=True):
                line_idx = f["line"] - 1
                msg = f["message"]
                
                # Case 1: Deprecated attributes in python (._cr, ._uid, ._context)
                if "is deprecated" in msg.lower() or "deprecated record attribute" in msg.lower():
                    orig = lines[line_idx]
                    # Replace _cr -> env.cr, _uid -> env.uid, _context -> env.context
                    new_line = orig.replace("._cr", ".env.cr").replace("._uid", ".env.uid").replace("._context", ".env.context")
                    if new_line != orig:
                        lines[line_idx] = new_line
                        modified = True
                        
                # Case 2: XML view tag <tree> in Odoo 18.0+
                elif "use of <tree> tag" in msg.lower() or "list view tag" in msg.lower():
                    orig = lines[line_idx]
                    new_line = orig.replace("<tree", "<list").replace("</tree>", "</list>")
                    if new_line != orig:
                        lines[line_idx] = new_line
                        modified = True
                        
            if modified:
                with open(filepath, "w", encoding="utf-8") as file:
                    file.writelines(lines)
                print(f"✅ Auto-fixed issues in {os.path.relpath(filepath, self.module_path)}")
                
        return True

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/autofix_linter.py <path_to_module>")
        sys.exit(1)
        
    module_path = sys.argv[1]
    if not os.path.isdir(module_path):
        print(f"Error: {module_path} is not a valid directory.")
        sys.exit(1)
        
    fixer = LinterAutofixer(module_path)
    fixer.fix_acls()
    fixer.fix_anti_patterns()
    print("\nAutofix run completed.")

if __name__ == "__main__":
    main()
