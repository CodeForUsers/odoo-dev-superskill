#!/usr/bin/env python3
# External RPC Client Template — Odoo 16.0–19.0
# Replace all {{ placeholders }} with actual values.
#
# USAGE:
# This is a standalone Python script intended to be run from an external server
# (e.g. AWS Lambda, a cron job on another machine, or a migration script).
# It uses the built-in xmlrpc library to connect to Odoo.

import xmlrpc.client
import ssl

# Configuration
URL = "{{ odoo_url }}"       # e.g., "https://mycompany.odoo.com"
DB = "{{ odoo_db }}"         # e.g., "mycompany_prod"
USER = "{{ odoo_user }}"     # e.g., "admin"
PASSWORD = "{{ odoo_pass }}" # e.g., "admin" or API Key

# To ignore SSL certificate errors (only for local dev environments)
# ctx = ssl.create_default_context()
# ctx.check_hostname = False
# ctx.verify_mode = ssl.CERT_NONE

def main():
    print(f"Connecting to {URL} (Database: {DB})...")
    
    # 1. Authenticate
    common = xmlrpc.client.ServerProxy(f'{URL}/xmlrpc/2/common')
    uid = common.authenticate(DB, USER, PASSWORD, {})
    
    if not uid:
        print("Authentication failed.")
        return
        
    print(f"Authenticated successfully as User ID: {uid}")

    # 2. Setup the models proxy
    models = xmlrpc.client.ServerProxy(f'{URL}/xmlrpc/2/object')
    
    def execute(*args, **kwargs):
        """Helper to run model methods."""
        return models.execute_kw(DB, uid, PASSWORD, *args, **kwargs)

    # 3. Search and Read (Batch operation)
    model_name = '{{ target_model }}' # e.g., 'res.partner'
    print(f"Searching {model_name}...")
    
    # Search for IDs matching a domain
    domain = [[('is_company', '=', True)]]
    record_ids = execute(model_name, 'search', domain, {'limit': 10})
    
    if not record_ids:
        print("No records found.")
        return
        
    # Read specific fields for those IDs
    records = execute(model_name, 'read', [record_ids], {'fields': ['name', 'country_id']})
    
    for rec in records:
        print(f"- {rec.get('name')} (Country ID: {rec.get('country_id')})")
        
    # 4. Create a record
    # new_id = execute(model_name, 'create', [{'name': 'New External Company'}])
    # print(f"Created record ID: {new_id}")
    
    # 5. Write/Update a record
    # execute(model_name, 'write', [[new_id], {'phone': '123456789'}])
    
    # 6. Call a custom method (must be decorated with @api.model or handle recordsets)
    # result = execute(model_name, 'my_custom_method', [[new_id]])
    
    # 7. Unlink / Delete
    # execute(model_name, 'unlink', [[new_id]])

if __name__ == '__main__':
    main()
