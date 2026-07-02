# Docker Compose for local Odoo development
# Replace {{ odoo_version }} with the target version (e.g., 18.0)
#
# USAGE:
# 1. Place this in the root of your project/repository
# 2. Run `docker-compose up -d`
# 3. Access Odoo at http://localhost:8069 (default login: admin/admin)

version: '3.1'

services:
  web:
    image: odoo:{{ odoo_version }}
    depends_on:
      - db
    ports:
      - "8069:8069"
      - "8071:8071" # xmlrpc
      - "8072:8072" # longpolling
    tty: true
    command: -- --dev=all
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=odoo
    volumes:
      - odoo-web-data:/var/lib/odoo
      - ./config:/etc/odoo
      # Mount the current directory (custom modules) into extra-addons
      - .:/mnt/extra-addons

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=odoo
      - POSTGRES_USER=odoo
    volumes:
      - odoo-db-data:/var/lib/postgresql/data

volumes:
  odoo-web-data:
  odoo-db-data:
