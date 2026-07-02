name: Odoo CI
# Replace {{ odoo_version }} with the target Odoo version (e.g., 18.0)
# Uses OCA's standard maintainer-quality-tools

on:
  push:
    branches:
      - main
      - "{{ odoo_version }}"
  pull_request:
    branches:
      - main
      - "{{ odoo_version }}"

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.10"] # Odoo 16/17/18 use 3.10+
        odoo-version: ["{{ odoo_version }}"]

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}
          cache: "pip"

      - name: Install dependencies
        run: |
          pip install --upgrade pip
          pip install flake8
          pip install setuptools wheel

      - name: Run Flake8
        run: |
          flake8 .

      - name: Checkout OCA/maintainer-quality-tools
        uses: actions/checkout@v3
        with:
          repository: OCA/maintainer-quality-tools
          path: maintainer-quality-tools
          ref: master

      - name: Install maintainer-quality-tools
        run: |
          export VERSION=${{ matrix.odoo-version }}
          bash maintainer-quality-tools/travis/install_mqt.sh

      - name: Run Odoo Tests
        run: |
          export VERSION=${{ matrix.odoo-version }}
          # Tests all modules in the repository
          # EXCLUDE is optional to skip certain modules
          # export EXCLUDE="module_to_skip"
          bash maintainer-quality-tools/travis/test_server.sh
