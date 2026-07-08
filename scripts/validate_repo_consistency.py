#!/usr/bin/env python3
"""Repository internal consistency validator.

Verifies that all relative file links and inline path references mentioned
in README.md and SKILL.md point to actual existing files in the workspace.
"""

import os
import re
import sys

def main():
    repo_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    docs_to_check = ['README.md', 'SKILL.md']
    
    missing_files = []
    checked_count = 0
    
    # Regex to detect relative markdown links: [Text](path)
    # Ignores web links (http://, https://) and anchors (#...)
    md_link_re = re.compile(r'\[[^\]]*\]\(([^)#]+)\)')
    
    # Regex to detect inline file paths (e.g. references/version-matrix.md, templates/view.xml.tpl)
    path_inline_re = re.compile(r'\b(?:references|templates|scripts)/[a-zA-Z0-9_\-\./\*\{\},]+')

    for doc_name in docs_to_check:
        doc_path = os.path.join(repo_dir, doc_name)
        if not os.path.exists(doc_path):
            print(f"ERROR: Document {doc_name} not found at {doc_path}")
            sys.exit(1)
            
        with open(doc_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Find markdown links
        links = md_link_re.findall(content)
        # Find inline paths
        inline_paths = path_inline_re.findall(content)
        
        # Combine and clean paths
        potential_paths = set()
        for link in links:
            if not link.startswith(('http://', 'https://', 'mailto:')):
                potential_paths.add(link.strip())
                
        for path in inline_paths:
            potential_paths.add(path.strip())
            
        print(f"Analyzing {doc_name}...")
        for rel_path in sorted(potential_paths):
            # If path contains wildcards like * or glob patterns (e.g. templates/manifest/manifest_{16,17,18,19}.py.tpl or *.rst), check parent dir
            if '*' in rel_path or '{' in rel_path:
                dir_name = os.path.dirname(rel_path)
                full_dir = os.path.join(repo_dir, dir_name)
                if not os.path.exists(full_dir):
                    missing_files.append((doc_name, rel_path, f"Containing directory '{dir_name}' does not exist"))
                continue
                
            full_path = os.path.join(repo_dir, rel_path)
            full_path = os.path.normpath(full_path)
            
            checked_count += 1
            if not os.path.exists(full_path):
                missing_files.append((doc_name, rel_path, "File or directory does not exist"))
                
    if missing_files:
        print(f"\n--- Found {len(missing_files)} broken references ---")
        for doc_name, rel_path, reason in missing_files:
            print(f"[{doc_name}] -> {rel_path} ({reason})")
        sys.exit(1)
    else:
        print(f"\nSuccess! Validated {checked_count} references in README.md and SKILL.md. All files exist.")
        sys.exit(0)

if __name__ == '__main__':
    main()
