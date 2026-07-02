# Rendimiento y SQL Directo en Odoo — Buenas Prácticas (OCA)

El ORM de Odoo es potente, pero en operaciones masivas (miles o millones de registros) puede ser lento debido a los cálculos, validaciones, gestión de caché y eventos de los campos compute.

Cuando el rendimiento es crítico (por ejemplo, en un script de migración masiva o un cálculo financiero pesado), un desarrollador senior puede **saltarse el ORM y ejecutar consultas SQL directas**. 

> [!WARNING]
> Usar SQL directo debe ser el último recurso. Bypassea la seguridad (ir.rule), las validaciones (constrains) y la caché del ORM.

## 1. Prevención de Inyección SQL (¡CRÍTICO!)

**NUNCA** utilices formateo de cadenas (`%s`, `.format()`, f-strings) para insertar variables en una consulta SQL si la variable proviene del usuario o de datos no confiables.

**Incorrecto (Vulnerable a Inyección SQL):**
```python
# PELIGRO! Si req_name es "1'; DROP TABLE res_partner; --", la DB se borra.
self.env.cr.execute(f"SELECT id FROM res_partner WHERE name = '{req_name}'")
```

**Correcto (Uso de Bind Variables de Psycopg2):**
```python
# SEGURO. Psycopg2 escapa automáticamente la variable.
self.env.cr.execute(
    "SELECT id FROM res_partner WHERE name = %s", 
    [req_name]
)
```

## 2. Invalidación de Caché (`env.cache.invalidate`)

Si modificas un registro mediante SQL (UPDATE), **el ORM no se entera**. Si ese registro estaba en memoria, las siguientes llamadas del código leerán el valor obsoleto.

> [!IMPORTANT]
> Siempre que modifiques datos mediante `cr.execute()`, debes invalidar la caché para forzar al ORM a leer de nuevo de la base de datos.

```python
# Actualizamos el estado saltándonos las reglas del ORM
self.env.cr.execute("""
    UPDATE sale_order 
    SET state = 'done' 
    WHERE id = %s
""", [order.id])

# Opción 1: Invalidar TODO el caché (Odoo 17+)
self.env.invalidate_all()

# Opción 2: Invalidar un campo específico para esos registros (Más eficiente)
# (En Odoo 15/16 se llamaba invalidate_cache)
self.env.cache.invalidate([
    (self.env['sale.order']._fields['state'], order.ids)
])
```

## 3. Seguridad a Nivel de Fila y SQL (Multi-Company)

Cuando usas SQL directo (`SELECT`), ignoras los filtros de seguridad de Odoo (`ir.rule`). Si tienes entornos multi-empresa, podrías devolverle al usuario registros de otras empresas.

Para aplicar reglas de seguridad dinámicamente en consultas SQL nativas, usa el compilador de seguridad del ORM:

```python
# Obtenemos la cláusula WHERE y los parámetros para respetar las reglas de 'sale.order'
query = self.env['sale.order']._where_calc([])
where_clause, where_params = query.get_sql()

# Construimos nuestra query raw combinando las reglas
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

## 4. Consultas Eficientes: Operaciones en Lote (Batch)

Evita ejecutar `cr.execute` dentro de un bucle for. Modifica múltiples registros a la vez usando la cláusula `IN`.

**Incorrecto (Lento):**
```python
for record_id in list_of_ids:
    self.env.cr.execute("UPDATE account_move SET state='draft' WHERE id=%s", [record_id])
```

**Correcto (Rápido):**
```python
# Psycopg2 requiere que la tupla/lista se pase como parámetro para la cláusula IN
self.env.cr.execute("""
    UPDATE account_move 
    SET state='draft' 
    WHERE id IN %s
""", [tuple(list_of_ids)])
```
