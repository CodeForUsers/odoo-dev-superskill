# odoo-dev-superskill

**Odoo Module Development Skill for AI Agents (16.0–19.0)**

![Version](https://img.shields.io/badge/Odoo-16.0%20%7C%2017.0%20%7C%2018.0%20%7C%2019.0-714B67?style=for-the-badge&logo=odoo&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

A comprehensive AI agent skill providing scaffolding, refactoring tools, and architecture templates for Odoo module development. Enforces Odoo Community Association (OCA) coding standards and security guidelines across Odoo versions 16.0 through 19.0.

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Repository Structure](#repository-structure)
- [Usage](#usage)
- [Key Version Differences](#key-version-differences)
- [Author](#author)
- [License](#license)

## Features

- **Multi-version Support**: Syntax generation and migration patterns for Odoo 16.0, 17.0, 18.0, and 19.0.
- **Module Scaffolding**: Command-line tools to generate complete, OCA-compliant Odoo modules.
- **Static Analysis & Refactoring**: Automated XML syntax upgrades (e.g., `attrs` to `invisible`) and anti-pattern detection.
- **Architecture Templates**: Boilerplates for OWL 2 components, POS offline architecture, B2B portals, and REST APIs.
- **Security & Performance**: Patterns for safe ORM bypassing (`cr.execute`), cache invalidation, and multi-company access rules.
- **E2E Testing**: Infrastructure templates for backend QUnit/Hoot testing and frontend Odoo Tours.

## Installation

The skill is distributed via NPM for integration into local agent environments.

```bash
npx odoo-dev-superskill
```

This command copies the required references, scripts, and templates to the `.agents/skills/odoo-dev-superskill` directory in your current workspace.

## Repository Structure

```text
odoo-dev-superskill/
├── SKILL.md                          # Agent instructions and entry point
├── references/                       # Technical architecture guides
│   ├── orm-changelog-16-19.md        # ORM version differences
│   ├── owl-components.md             # OWL 2 frontend patterns
│   ├── sql-performance.md            # Raw SQL guidelines
│   └── ...                           
├── scripts/                          # CI/CD and automation tools
│   ├── scaffold_module.py            # Module generator
│   ├── autofix_xml.py                # Legacy XML refactoring
│   ├── validate_manifest.py          # Manifest validation
│   └── ...
└── templates/                        # OCA-compliant code boilerplates
    ├── controllers/                  
    ├── models/                       
    ├── views/                        
    ├── security/                     
    ├── static/                       
    └── tests/                        
```

## Usage

Once installed, standard AI coding agents (Claude Code, Cursor, Windsurf, Gemini) will automatically detect the `SKILL.md` file when operating in the workspace. The skill provides the agent with context regarding:
- Target Odoo versions and required syntax changes.
- Appropriate file structures for new modules.
- Linter and formatting rules.

To manually scaffold a module without an agent, execute the included script:

```bash
python scripts/scaffold_module.py \
    --name my_custom_module \
    --title "My Module" \
    --version 18.0 \
    --models my.custom.record \
    --output /path/to/addons/
```

## Key Version Differences

| Feature | 16.0 | 17.0 | 18.0 | 19.0 |
|---------|------|------|------|------|
| **List View Tag** | `<tree>` | `<tree>` | `<list>` * | `<list>` |
| **Conditional UI** | `attrs="{...}"` | `invisible="..."` | `invisible="..."` | `invisible="..."` |
| **ORM read_group** | `read_group()` | `read_group()` | `_read_group()` * | `_read_group()` |
| **Frontend Tests** | QUnit | QUnit | Hoot * | Hoot |
| **SQL Wrapper** | N/A | `SQL()` class | `SQL()` class | `SQL()` class |

*\* Indicates a breaking change introduced in this version.*

## Author
David Carreres Gómez

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
