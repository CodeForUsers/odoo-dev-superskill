# Maturity Levels — Odoo OCA Development

Maturity levels for Odoo modules according to OCA standards.
These levels are **identical for all 4 versions** (16.0–19.0).

---

## Maturity Levels

| Level | Badge | Meaning |
|-------|-------|---------|
| **Alpha** | `Alpha` | In active development, not suitable for production |
| **Beta** | `Beta` | Functional but may have bugs, suitable for testing |
| **Production/Stable** | `Production/Stable` | Tested and stable, suitable for production |
| **Mature** | `Mature` | Stable across multiple versions, widely adopted |

---

## Checklist by Level

### Alpha

Minimum requirements to declare a module as Alpha:

- [x] The module installs without errors.
- [x] The manifest (`__manifest__.py`) contains all mandatory fields.
- [x] Models have basic ACLs (`ir.model.access.csv`).
- [ ] No tests required.
- [ ] No comprehensive documentation required.

```python
# __manifest__.py
{
    "development_status": "Alpha",
    # ...
}
```

### Beta

Requirements to declare a module as Beta (includes everything from Alpha):

- [x] Everything from Alpha.
- [x] There is at least one test per model (`TransactionCase` with basic CRUD).
- [x] Main views work (form, list, search).
- [x] Basic documentation exists (`README.rst` or `readme/` folder).
- [x] Computed fields have tests.
- [x] Constraints have tests verifying exceptions.
- [ ] Exhaustive documentation is not required.

```python
# __manifest__.py
{
    "development_status": "Beta",
    # ...
}
```

### Production/Stable

Requirements to declare a module as Stable (includes everything from Beta):

- [x] Everything from Beta.
- [x] Adequate test coverage (CRUD, compute, constrains, workflows).
- [x] Comprehensive documentation with OCA structure:
  - `DESCRIPTION.rst`: functional description.
  - `CONFIGURE.rst`: configuration instructions.
  - `USAGE.rst`: usage guide with screenshots.
  - `CONTRIBUTORS.rst`: list of contributors.
- [x] State transition / workflow tests.
- [x] Security tests (verify group access).
- [x] Record rules (`ir.rule`) for multi-company if applicable.
- [x] No deprecation warnings in logs when running tests.
- [x] Code reviewed by at least one developer.

```python
# __manifest__.py
{
    "development_status": "Production/Stable",
    # ...
}
```

### Mature

Requirements to declare a module as Mature (includes everything from Stable):

- [x] Everything from Production/Stable.
- [x] The module has been stable for **at least 2 Odoo versions**
  (e.g., functional in 16.0 and 17.0 without reported critical bugs).
- [x] Widely adopted by the community (multiple production installations).
- [x] Clean issue history: critical bugs resolved in under 30 days.
- [x] Test coverage > 80%.
- [x] Comprehensive and updated documentation, including changelog.
- [x] Performance tests if the module handles large data volumes.

```python
# __manifest__.py
{
    "development_status": "Mature",
    # ...
}
```

---

## How to Declare Maturity Level

### In the Manifest

```python
# __manifest__.py
{
    "name": "My Module",
    "version": "18.0.1.0.0",
    "development_status": "Beta",  # Alpha | Beta | Production/Stable | Mature
    # ...
}
```

### In the README (Badge)

Use a badge in the README to indicate the level:

```rst
.. |badge_status| image:: https://img.shields.io/badge/maturity-Beta-yellow.svg
    :target: https://odoo-community.org/page/development-status
    :alt: Beta
```

### Valid values for `development_status`

```python
# Accepted values by OCA:
"Alpha"
"Beta"
"Production/Stable"
"Mature"
```

---

## Progression Flow

```text
Alpha  →  Beta  →  Production/Stable  →  Mature
  │         │              │                  │
  │         │              │                  └─ 2+ stable versions
  │         │              └─ Full tests + docs + review
  │         └─ Basic tests + minimal docs
  └─ Installs + ACLs
```

### When to Promote

| From → To | Condition |
|-----------|-----------|
| Alpha → Beta | CRUD tests pass, basic documentation exists |
| Beta → Stable | Full tests, complete OCA documentation, code review |
| Stable → Mature | 2+ versions without critical bugs, wide adoption |

### When to Demote

| From → To | Condition |
|-----------|-----------|
| Stable → Beta | Critical production bug unresolved for 30 days |
| Mature → Stable | Major refactoring changing the API |
| Any → Alpha | Complete module rewrite |

---

## Quick Validation Checklist

Before declaring any level, verify:

- [ ] Is `development_status` defined in the manifest?
- [ ] Does the declared level match the module's reality?
- [ ] Do tests pass 100%?
- [ ] Is the documentation proportional to the declared level?
- [ ] Are there no deprecation warnings if the level is Stable or higher?
