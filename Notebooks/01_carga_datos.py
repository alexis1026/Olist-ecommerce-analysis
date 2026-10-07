"""
================================================================
CARGA DE DATOS
Proyecto: Análisis de E-commerce - Dataset Olist
================================================================
Qué hace este script:
1. Sube los CSV del dataset a Google Colab
2. Carga cada CSV como un DataFrame de pandas
3. Hace un diagnóstico inicial de cada tabla (dimensiones,
   tipos de datos, nulos, duplicados)
4. Deja cada tabla lista como variable individual para los
   siguientes scripts de limpieza
"""

# -----------------------------
# 1. SUBIDA DE ARCHIVOS A COLAB
# -----------------------------
# Abre un diálogo para seleccionar los archivos desde tu computadora.
# Sube los 9 CSV del dataset Olist (descargados previamente de Kaggle).
from google.colab import files
uploaded = files.upload()

import pandas as pd
import os

# Evita que pandas trunque columnas al imprimir
pd.set_option("display.max_columns", None)
pd.set_option("display.width", 150)

# -----------------------------
# 2. CONFIGURACIÓN DE ARCHIVOS
# -----------------------------
# Como los archivos se subieron directo a la raíz de Colab (no a una carpeta),
# DATA_PATH queda vacío. Si subes a una carpeta de Drive, cambia esta ruta.
DATA_PATH = ""

archivos = {
    "orders": "olist_orders_dataset.csv",
    "customers": "olist_customers_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "products": "olist_products_dataset.csv",
    "payments": "olist_order_payments_dataset.csv",
    "reviews": "olist_order_reviews_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}

# -----------------------------
# 3. CARGA DE TABLAS A UN DICCIONARIO
# -----------------------------
# Usamos un diccionario primero (en vez de 9 variables sueltas) para poder
# iterar fácilmente sobre todas las tablas en el diagnóstico de abajo.
tablas = {}

for nombre, archivo in archivos.items():
    ruta = os.path.join(DATA_PATH, archivo)
    if os.path.exists(ruta):
        tablas[nombre] = pd.read_csv(ruta)
        print(f"✅ Cargado: {nombre} ({archivo})")
    else:
        print(f"⚠️  No encontrado: {ruta}")

print("\n" + "=" * 60)
print("RESUMEN DE CARGA")
print("=" * 60)
print(f"Tablas cargadas correctamente: {len(tablas)} / {len(archivos)}")

# -----------------------------
# 4. DIAGNÓSTICO POR TABLA
# -----------------------------
# Para cada tabla revisamos: forma, tipos de datos, nulos (con %) y
# duplicados. Esto es lo que guía las decisiones de limpieza del
# siguiente script.
for nombre, df in tablas.items():
    print("\n" + "-" * 60)
    print(f"TABLA: {nombre.upper()}")
    print("-" * 60)
    print(f"Dimensiones: {df.shape[0]} filas x {df.shape[1]} columnas")

    print("\nTipos de datos:")
    print(df.dtypes)

    print("\nValores nulos por columna:")
    nulos = df.isnull().sum()
    nulos = nulos[nulos > 0]
    if len(nulos) > 0:
        porcentaje = (nulos / len(df) * 100).round(2)
        resumen_nulos = pd.DataFrame({"nulos": nulos, "porcentaje (%)": porcentaje})
        print(resumen_nulos)
    else:
        print("Sin valores nulos.")

    duplicados = df.duplicated().sum()
    print(f"\nFilas duplicadas: {duplicados}")

    print("\nPrimeras filas:")
    print(df.head(3))

# -----------------------------
# 5. EXTRAER CADA TABLA A SU PROPIA VARIABLE
# -----------------------------
# Sacamos cada DataFrame del diccionario a una variable individual,
# que es como se van a usar en los scripts siguientes (limpieza, carga a SQL).
# .copy() evita que una modificación posterior afecte al diccionario original.
orders = tablas["orders"].copy()
customers = tablas["customers"].copy()
order_items = tablas["order_items"].copy()
products = tablas["products"].copy()
payments = tablas["payments"].copy()
reviews = tablas["reviews"].copy()
sellers = tablas["sellers"].copy()
geolocation = tablas["geolocation"].copy()

print("\n✅ Carga y diagnóstico inicial completados.")
print("Variables individuales listas: orders, customers, order_items, products,")
print("payments, reviews, sellers, geolocation")
