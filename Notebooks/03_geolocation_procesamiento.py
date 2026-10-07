"""
================================================================
PROCESAMIENTO DE GEOLOCATION
Proyecto: Análisis de E-commerce - Dataset Olist
================================================================
Requiere haber corrido antes: 01_carga_datos.py y 02_limpieza_datos.py

Qué hace este script:

PARTE A - Reducción de geolocation
    La tabla original trae múltiples coordenadas GPS por un mismo
    código postal (varias calles/edificios dentro del mismo zip).
    Se reduce a UN punto representativo por código postal, usando
    el promedio de latitud/longitud.

PARTE B - Completar códigos postales faltantes
    Algunos clientes (tabla 'customers') tienen un código postal que
    NO existe en la tabla 'geolocation' ya reducida. Si no se corrige,
    esto rompe la Foreign Key al cargar a SQL (customers -> geolocation).
    Se identifican esos casos y se crean registros nuevos para
    completarlos (con lat/lng en nulo, ya que no tenemos esa coordenada
    real, pero sí ciudad/estado del cliente).
"""

import pandas as pd
import numpy as np

# ================================================================
# PARTE A: REDUCCIÓN DE GEOLOCATION POR CÓDIGO POSTAL
# ================================================================

print(f"Filas originales en geolocation: {len(geolocation)}")
print(f"Códigos postales únicos: {geolocation['geolocation_zip_code_prefix'].nunique()}")

# -----------------------------
# A.1 Calcular el promedio de lat/lng por código postal
# -----------------------------
medias = (
    geolocation
    .groupby("geolocation_zip_code_prefix")[["geolocation_lat", "geolocation_lng"]]
    .mean()
)

# -----------------------------
# A.2 Quedarnos con UNA sola fila por código postal
# (conserva city/state, que no cambian dentro del mismo zip)
# -----------------------------
geolocation = geolocation.drop_duplicates(
    subset="geolocation_zip_code_prefix", keep="first"
).copy()

print(f"Filas después de reducir a un punto por código postal: {len(geolocation)}")

# -----------------------------
# A.3 Reemplazar lat/lng por las medias calculadas en A.1
# -----------------------------
# Se indexa por zip_code_prefix en ambos DataFrames para que
# .update() reemplace el valor correcto en cada fila.
geolocation = geolocation.set_index("geolocation_zip_code_prefix")
geolocation.update(medias)
geolocation = geolocation.reset_index()

print("✅ geolocation reducida y actualizada con coordenadas promedio.")
print(geolocation.head())


# ================================================================
# PARTE B: COMPLETAR CÓDIGOS POSTALES FALTANTES
# ================================================================
# Esto es necesario porque 'customers' puede referenciar códigos postales
# que no aparecen en la tabla 'geolocation' ya reducida (por ejemplo,
# zonas sin mediciones GPS registradas en el dataset original). Si no se
# corrige, la Foreign Key de customers -> geolocation falla al cargar a SQL.

# -----------------------------
# B.1 Detectar qué códigos postales de 'customers' NO existen en 'geolocation'
# -----------------------------
customer_zip_codes = set(customers["customer_zip_code_prefix"])
geolocation_zip_codes = set(geolocation["geolocation_zip_code_prefix"])

missing_zip_codes = customer_zip_codes - geolocation_zip_codes

print(f"\nCantidad de códigos postales de clientes faltantes en geolocation: "
      f"{len(missing_zip_codes)}")

# -----------------------------
# B.2 Obtener la info (ciudad/estado) de esos clientes con código faltante
# -----------------------------
# drop_duplicates: si varios clientes comparten el mismo código postal
# nuevo, solo necesitamos UN registro por código para crear en geolocation.
missing_data = customers[
    customers["customer_zip_code_prefix"].isin(missing_zip_codes)
].drop_duplicates(subset=["customer_zip_code_prefix"])

# -----------------------------
# B.3 Crear los registros nuevos para 'geolocation'
# -----------------------------
# lat/lng quedan en NaN porque no tenemos la coordenada GPS real de estos
# códigos postales y solo sabemos a qué ciudad/estado pertenecen. Si más adelante se requiere, se podría
# completar con un servicio externo de geocodificación.
new_geolocation_records = pd.DataFrame({
    "geolocation_zip_code_prefix": missing_data["customer_zip_code_prefix"],
    "geolocation_lat": np.nan,
    "geolocation_lng": np.nan,
    "geolocation_city": missing_data["customer_city"],
    "geolocation_state": missing_data["customer_state"],
})

print(f"\n✅ {len(new_geolocation_records)} registros nuevos creados para completar geolocation.")
print(new_geolocation_records.head())

# -----------------------------
# B.4 Unir los registros faltantes a la tabla geolocation ya reducida
# -----------------------------
# A partir de aquí, 'geolocation' ya incluye tanto los puntos originales
# (con coordenadas reales) como los nuevos (con lat/lng en nulo), lista
# para cargarse completa a SQL en un solo.
geolocation = pd.concat([geolocation, new_geolocation_records], ignore_index=True)

print(f"\n✅ geolocation final: {len(geolocation)} filas "
      f"({len(geolocation) - len(new_geolocation_records)} originales + "
      f"{len(new_geolocation_records)} completados)")
