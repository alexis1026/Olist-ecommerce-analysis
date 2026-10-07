"""
================================================================
CARGA DE DATOS A SUPABASE (PostgreSQL)
Proyecto: Análisis de E-commerce - Dataset Olist
================================================================
Requiere haber corrido antes:
    01_carga_datos.py
    02_limpieza_datos.py
    03_geolocation_procesamiento.py
    04_conexion_supabase.py  

Las tablas YA DEBEN EXISTIR en Supabase (creadas manualmente o con un
script de esquema aparte), por eso se usa if_exists="append" en todos
los casos: este script solo INSERTA datos, no crea estructura.

Orden de carga (importante, respeta las Foreign Keys):
    1. Geolocation   (no depende de nadie)
    2. Customers     (depende de Geolocation, vía código postal)
    3. Sellers       (no depende de nadie)
    4. Products      (no depende de nadie)
    5. Orders        (depende de Customers)
    6. Order Items   (depende de Orders, Products y Sellers)
    7. Payments      (depende de Orders)
    8. Reviews       (depende de Orders)
"""

import pandas as pd

# -----------------------------
# 1. GEOLOCATION
# -----------------------------
# Ya incluye tanto los puntos originales (reducidos por código postal)
# como los registros completados para los clientes "huérfanos"
# (ver 03_geolocation_procesamiento.py). 
geolocation.to_sql(
    "geolocation",
    con=engine,
    if_exists="append",
    index=False,
    method="multi",
    chunksize=5000,
)
print(f"✅ geolocation cargada ({len(geolocation)} filas)")

# -----------------------------
# 2. CUSTOMERS
# -----------------------------
customers.to_sql(
    "customers",
    con=engine,
    if_exists="append",
    index=False,
    method="multi",
    chunksize=5000,
)
print(f"✅ customers cargada ({len(customers)} filas)")

# -----------------------------
# 3. SELLERS
# -----------------------------
sellers.to_sql(
    "sellers",
    con=engine,
    if_exists="append",
    index=False,
    method="multi",
    chunksize=5000,
)
print(f"✅ sellers cargada ({len(sellers)} filas)")

# -----------------------------
# 4. PRODUCTS
# -----------------------------
products.to_sql(
    "products",
    con=engine,
    if_exists="append",
    index=False,
    method="multi",
    chunksize=5000,
)
print(f"✅ products cargada ({len(products)} filas)")

# -----------------------------
# 5. ORDERS
# -----------------------------
orders.to_sql(
    "orders",
    con=engine,
    if_exists="append",
    index=False,
    method="multi",
    chunksize=5000,
)
print(f"✅ orders cargada ({len(orders)} filas)")

# -----------------------------
# 6. ORDER_ITEMS
# -----------------------------
order_items.to_sql(
    "order_items",
    con=engine,
    if_exists="append",
    index=False,
    method="multi",
    chunksize=5000,
)
print(f"✅ order_items cargada ({len(order_items)} filas)")

# -----------------------------
# 7. PAYMENTS
# -----------------------------
payments.to_sql(
    "payments",
    con=engine,
    if_exists="append",
    index=False,
    method="multi",
    chunksize=5000,
)
print(f"✅ payments cargada ({len(payments)} filas)")

# -----------------------------
# 8. REVIEWS
# -----------------------------
reviews.to_sql(
    "reviews",
    con=engine,
    if_exists="append",
    index=False,
    method="multi",
    chunksize=5000,
)
print(f"✅ reviews cargada ({len(reviews)} filas)")

# -----------------------------
# 9. VERIFICACIÓN FINAL
# -----------------------------
print("\n--- Verificación de filas cargadas en Supabase ---")
tablas_verificar = [
    "geolocation", "customers", "sellers", "products",
    "orders", "order_items", "payments", "reviews",
]
for tabla in tablas_verificar:
    conteo = pd.read_sql(f'SELECT COUNT(*) as total FROM {tabla}', engine)["total"][0]
    print(f"  - {tabla}: {conteo} filas")

print("\n✅ Carga completa finalizada.")
