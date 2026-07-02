exclude: |
  (?x)
  # NOTA: regex para excluir archivos autogenerados o vendors
  # (e.g. static/lib/, .env, node_modules/)
  ^(\.idea|\.vscode|\.git|node_modules|static/lib)/

default_language_version:
  python: python3
  node: "18.15.0"

repos:
  # ─── PRE-COMMIT-HOOKS ESTÁNDAR ──────────────────────────────────────────────
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-xml
      - id: check-case-conflict
      - id: check-merge-conflict
      - id: check-symlinks
      - id: fix-byte-order-marker

  # ─── FORMATEO DE PYTHON (BLACK) ─────────────────────────────────────────────
  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
        args: [--line-length=88]

  # ─── ORDEN DE IMPORTS (ISORT) ───────────────────────────────────────────────
  - repo: https://github.com/PyCQA/isort
    rev: 5.12.0
    hooks:
      - id: isort
        args: [--profile=black, --line-length=88]

  # ─── ANALIZADOR ESTÁTICO PYTHON (FLAKE8) ────────────────────────────────────
  - repo: https://github.com/PyCQA/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
        additional_dependencies:
          - flake8-bugbear
          - flake8-comprehensions
          - flake8-debugger
          - flake8-print
        args: [--max-line-length=88, --extend-ignore=E203,W503]

  # ─── FORMATEO JAVASCRIPT/CSS/JSON (PRETTIER) ────────────────────────────────
  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.0.0
    hooks:
      - id: prettier
        types_or: [javascript, json, css, scss]
        args: [--print-width=100, --tab-width=4]

  # ─── PYLINT-ODOO (ESPECÍFICO DE OCA) ────────────────────────────────────────
  # Nota: Pylint-odoo puede ser lento, descomentar si se desea ejecución local.
  # En CI siempre se ejecuta.
  # - repo: https://github.com/OCA/pylint-odoo
  #   rev: v8.0.20
  #   hooks:
  #     - id: pylint_odoo
  #       args:
  #         - --load-plugins=pylint_odoo
  #         - --score=n
