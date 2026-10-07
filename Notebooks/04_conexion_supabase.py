"""
================================================================
CONEXIÓN A SUPABASE (PostgreSQL)
Proyecto: Análisis de E-commerce - Dataset Olist
================================================================
Requisito previo: tener guardada la variable de entorno/secret
"SUPABASE_DATABASE_URL" en Colab (ícono de llave en el panel izquierdo).

Qué hace este script:
1. Instala las librerías necesarias para conectar a PostgreSQL
2. Crea la conexión (engine) hacia la base de datos de Supabase
3. Verifica que la conexión funciona antes de intentar cargar datos
"""

# -----------------------------
# 1. INSTALACIÓN DE LIBRERÍAS
# -----------------------------
# sqlalchemy: permite conectar Python a bases de datos SQL de forma genérica
# psycopg2-binary: el "driver" específico que sqlalchemy necesita para hablar
# con PostgreSQL
!pip install sqlalchemy psycopg2-binary

# -----------------------------
# 2. CREAR LA CONEXIÓN (ENGINE)
# -----------------------------
# userdata.get() lee el secret guardado en Colab, así la contraseña de la
# base de datos no queda expuesta.
from google.colab import userdata
from sqlalchemy import create_engine, text

DATABASE_URL = userdata.get("SUPABASE_DATABASE_URL")
engine = create_engine(DATABASE_URL)

# -----------------------------
# 3. VERIFICAR LA CONEXIÓN
# -----------------------------
# SELECT 1 es la consulta más simple posible, solo para confirmar que
# el motor puede comunicarse con la base de datos antes de intentar
# cargar las tablas reales.
try:
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))
        print("✅ Conexión exitosa con Supabase PostgreSQL")
except Exception as e:
    print("❌ Error de conexión:")
    print(e)

