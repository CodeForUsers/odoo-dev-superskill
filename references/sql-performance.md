# Performance and Direct SQL in Odoo — Best Practices (OCA)

The Odoo ORM is powerful, but in massive operations (thousands or millions of records) it can be slow due to calculations, validations, cache management, and compute field events.

When performance is critical (e.g., in a massive migration script or heavy financial calculation), a senior developer may **bypass the ORM and execute direct SQL queries**. 

> [!WARNING]
> Using direct SQL should be the last resort. It bypasses security (ir.rule), validations (constrains), and the ORM cache.

## 1. SQL Injection Prevention (CRITICAL!)

**NEVER** use string formatting (`%s`, `.format()`, f-strings) to insert variables into an SQL query if the variable comes from the user or untrusted data.

**Incorrect (Vulnerable to SQL Injection):**
```python
# DANGER! If req_name is "1'; DROP TABLE res_partner; --", the DB gets wiped.
self.env.cr.execute(f"SELECT id FROM res_partner WHERE name = '{req_name}'")
```

**Correct (Using Psycopg2 Bind Variables):**
```python
# SAFE. Psycopg2 automatically escapes the variable.
self.env.cr.execute(
    "SELECT id FROM res_partner WHERE name = %s", 
    [req_name]
)
```

## 2. Cache Invalidation (`env.cache.invalidate`)

If you modify a record via SQL (UPDATE), **the ORM is unaware**. If that record was in memory, subsequent code calls will read the stale value.

> [!IMPORTANT]
> Whenever you modify data using `cr.execute()`, you must invalidate the cache to force the ORM to read from the database again.

```python
# We update the state bypassing the ORM rules
self.env.cr.execute("""
    UPDATE sale_order 
    SET state = 'done' 
    WHERE id = %s
""", [order.id])

# Option 1: Invalidate ALL the cache (Odoo 17+)
self.env.invalidate_all()

# Option 2: Invalidate a specific field for those records (More efficient)
# (In Odoo 15/16 this was called invalidate_cache)
self.env.cache.invalidate([
    (self.env['sale.order']._fields['state'], order.ids)
])
```

## 3. Row-Level Security and SQL (Multi-Company)

When using direct SQL (`SELECT`), you ignore Odoo's security filters (`ir.rule`). If you have multi-company environments, you might return records from other companies to the user.

To dynamically apply security rules in native SQL queries, use the ORM's security compiler:

```python
# We obtain the WHERE clause and parameters to respect the 'sale.order' rules
query = self.env['sale.order']._where_calc([])
where_clause, where_params = query.get_sql()

# We construct our raw query combining the rules
sql = f"""
    SELECT id, name, amount_total 
    FROM sale_order 
    WHERE amount_total > %s 
    AND {where_clause}
"""
params = [1000.0] + where_params

self.env.cr.execute(sql, params)
results = self.env.cr.dictfetchall()
```

## 4. Efficient Queries: Batch Operations

Avoid executing `cr.execute` inside a for loop. Modify multiple records at once using the `IN` clause.

**Incorrect (Slow):**
```python
for record_id in list_of_ids:
    self.env.cr.execute("UPDATE account_move SET state='draft' WHERE id=%s", [record_id])
```

**Correct (Fast):**
```python
# Psycopg2 requires the tuple/list to be passed as a parameter for the IN clause
self.env.cr.execute("""
    UPDATE account_move 
    SET state='draft' 
    WHERE id IN %s
""", [tuple(list_of_ids)])
```
