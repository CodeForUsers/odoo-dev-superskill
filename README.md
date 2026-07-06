# odoo-dev-superskill

**Odoo Module Development Skill for AI Agents (16.0–19.0)**

![Version](https://img.shields.io/badge/Odoo-16.0%20%7C%2017.0%20%7C%2018.0%20%7C%2019.0-714B67?style=for-the-badge&logo=odoo&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
[![skills.sh](https://skills.sh/b/CodeForUsers/odoo-dev-superskill)](https://skills.sh/CodeForUsers/odoo-dev-superskill)

A comprehensive AI agent skill providing scaffolding, refactoring tools, and architecture templates for Odoo module development. Enforces Odoo Community Association (OCA) coding standards and security guidelines across Odoo versions 16.0 through 19.0.

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Repository Structure](#repository-structure)
- [Usage](#usage)
- [Behavior Templates](#behavior-templates)
- [Key Version Differences](#key-version-differences)
- [Author](#author)
- [License](#license)

## Features

- **Module Migration & Porting**: Automated version migrations and commit porting between branches using OCA tools (`oca-port` and `odoo-module-migrator`).
- **Module Scaffolding**: Command-line tools to generate complete, OCA-compliant Odoo modules.
- **Static Analysis & Refactoring**: Automated XML syntax upgrades (e.g., `attrs` to `invisible`) and anti-pattern detection.
- **Architecture Templates**: Boilerplates for OWL 2 components, POS offline architecture, B2B portals, and REST APIs.
- **Security & Performance**: Patterns for safe ORM bypassing (`cr.execute`), cache invalidation, and multi-company access rules.
- **E2E Testing**: Infrastructure templates for backend QUnit/Hoot testing and frontend Odoo Tours.
- **Behavior Templates**: Specialized agent behavior guides for scaffolding, migration, security, XML/UI, connectors, code review, and testing tasks.

## Installation

The skill is distributed via NPM for integration into local agent environments.

```bash
npx odoo-dev-superskill
```

This command copies the required references, scripts, and templates to the `.agents/skills/odoo-dev-superskill` directory in your current workspace.

### Prerequisites (for Migration Tools)

If you plan to use the automated version migration and porting scripts, install the required OCA tools directly from GitHub:

```bash
pip install git+https://github.com/OCA/oca-port.git
pip install git+https://github.com/OCA/odoo-module-migrator.git
```

## Repository Structure

```text
odoo-dev-superskill/
├── SKILL.md                          # Agent instructions and entry point
├── references/                       # Technical architecture guides
│   ├── agents/                       # Behavior templates (loaded on demand)
│   │   ├── scaffold-behavior.md      # Module creation behavior
│   │   ├── migration-behavior.md     # Version migration behavior
│   │   ├── security-behavior.md      # Security & access control behavior
│   │   ├── xml-ui-behavior.md        # Views, XPath, OWL behavior
│   │   ├── connector-behavior.md     # API & integration behavior
│   │   ├── review-behavior.md        # Code review behavior
│   │   └── testing-behavior.md       # Testing & QA behavior
│   ├── orm-changelog-16-19.md        # ORM version differences
│   ├── owl-components.md             # OWL 2 frontend patterns
│   ├── sql-performance.md            # Raw SQL guidelines
│   └── ...                           
├── scripts/                          # CI/CD and automation tools
│   ├── scaffold_module.py            # Module generator
│   ├── autofix_xml.py                # Legacy XML refactoring
│   ├── validate_manifest.py          # Manifest validation
│   ├── migrate_code_patterns.py      # Code pattern migration (odoo-module-migrator)
│   ├── port_addon.py                 # Port commits between branches (oca-port)
│   └── auto_migrate_full.py          # Orchestrates full migration pipeline
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

To run a full Odoo module migration (code patterns + commit porting):

```bash
python scripts/auto_migrate_full.py \
    --source origin/16.0 \
    --target origin/18.0 \
    --module my_custom_module \
    --repo ./
```

## Behavior Templates

The skill includes specialized behavior templates that AI agents load on demand depending on the task at hand. These live in `references/agents/` and are automatically triggered from `SKILL.md`:

| Template | When it activates |
|---|---|
| `scaffold-behavior.md` | Creating a new addon or scaffolding from scratch |
| `migration-behavior.md` | Migrating between Odoo versions (deprecated syntax, ORM, assets) |
| `security-behavior.md` | ACLs, `ir.rule`, `sudo()`, controllers, raw SQL |
| `xml-ui-behavior.md` | XML views, XPath, QWeb, OWL, frontend assets |
| `connector-behavior.md` | APIs, marketplaces, webhooks, import/export pipelines |
| `review-behavior.md` | Code review, quality audit, OCA compliance |
| `testing-behavior.md` | Tests, coverage strategy, QA |

Templates can be combined when a task spans multiple areas (e.g., a migration that also changes XML views).

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
