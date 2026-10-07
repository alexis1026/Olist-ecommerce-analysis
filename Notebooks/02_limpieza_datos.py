"""
================================================================
LIMPIEZA DE DATOS
Proyecto: Análisis de E-commerce - Dataset Olist
================================================================
Requiere haber corrido antes: 01_carga_datos.py
(se usan las variables orders, customers, order_items, products, payments,
reviews, sellers, geolocation, category_translation)

Qué hace este script:
1. Convierte las columnas de fecha (texto) a formato datetime real,
   en las tablas 'orders', 'order_items' y 'reviews'
2. Elimina duplicados exactos en todas las tablas
"""

import pandas as pd

# -----------------------------
# 1. CONVERSIÓN DE FECHAS: tabla 'orders'
# -----------------------------
# Las fechas llegan como texto (string) desde el CSV. Las convertimos a
# datetime para poder calcular diferencias de tiempo más adelante
# (tiempo de entrega, retrasos, etc.).
# errors="coerce" convierte a NaT (nulo de fecha) cualquier valor que no
# se pueda interpretar como fecha, en vez de hacer fallar todo el script.
date_cols = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
]

for col in date_cols:
    orders[col] = pd.to_datetime(orders[col], errors="coerce")
print("✅ Fechas convertidas en 'orders'")

# -----------------------------
# 2. CONVERSIÓN DE FECHAS: tabla 'order_items'
# -----------------------------
# shipping_limit_date = fecha límite que tenía el vendedor para despachar
# el pedido. Útil para análisis de cumplimiento del vendedor.
order_items["shipping_limit_date"] = pd.to_datetime(
    order_items["shipping_limit_date"], errors="coerce"
)
print("✅ Fechas convertidas en 'order_items'")

# -----------------------------
# 3. CONVERSIÓN DE FECHAS: tabla 'reviews'
# -----------------------------
date_cols_reviews = [
    "review_creation_date",
    "review_answer_timestamp",
]

for col in date_cols_reviews:
    reviews[col] = pd.to_datetime(reviews[col], errors="coerce")
print("✅ Fechas convertidas en 'reviews'")

# -----------------------------
# 4. ELIMINACIÓN DE DUPLICADOS EN TODAS LAS TABLAS
# -----------------------------
# Revisamos fila por fila si hay registros exactamente iguales (en todas
# sus columnas) y los eliminamos. Esto es distinto a duplicados por llave
# (ej. mismo review_id con texto distinto), que se tratan aparte si aplica.
dataframes_orders = {
    "orders": orders,
    "customers": customers,
    "order_items": order_items,
    "products": products,
    "payments": payments,
    "reviews": reviews,
    "sellers": sellers,
    "geolocation": geolocation
}

for nombre_df, df in dataframes_orders.items():
    if df.duplicated().any():
        total_duplicados = df.duplicated().sum()
        df.drop_duplicates(inplace=True)
        print(f"🔹 {nombre_df}: se eliminaron {total_duplicados} duplicados")
    else:
        print(f"✅ {nombre_df}: sin duplicados")

# -----------------------------
# 5. DUPLICADOS POR LLAVE: tabla 'reviews'
# -----------------------------
# Un mismo pedido puede tener más de una reseña registrada (reseñas
# actualizadas, reenviadas, etc.). Nos quedamos con una sola fila por
# review_id para evitar inflar el conteo de reseñas al hacer JOIN con
# 'orders' más adelante.
reviews = reviews.drop_duplicates(subset=["review_id"], keep="first")
print(f"✅ reviews: duplicados por 'review_id' eliminados "
      f"(quedan {len(reviews)} reseñas únicas)")

print("\n✅ Limpieza de fechas y duplicados completada.")

