# 📦 Análisis de E-commerce — Dataset Olist

Proyecto de análisis de datos end-to-end (Python + SQL + Power BI) sobre el dataset público de **Olist** (Brazilian E-Commerce), orientado a extraer insights de negocio sobre ventas, logística y satisfacción del cliente.

---

## 🎯 Objetivo del proyecto

Analizar el comportamiento de ventas, los tiempos de entrega y la satisfacción del cliente de una plataforma de e-commerce, para identificar oportunidades de mejora en logística y detectar los factores que más impactan en la experiencia del cliente.

---

## 🗂️ Dataset

- **Fuente:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)
- **Periodo:** 2016 - 2018
- **Tablas:** orders, customers, order_items, products, payments, reviews, sellers, geolocation, category_translation
- **Tamaño:** ~100,000 pedidos

El dataset **no está incluido en este repositorio** por su tamaño. Es un dataset público disponible directamente en Kaggle. Descárgalo y colócalo en una carpeta local `data/raw/` antes de correr los scripts.

---

## 🛠️ Stack tecnológico

| Herramienta | Uso en el proyecto |
|---|---|
| **Python (pandas) / Google Colab** | Limpieza de datos, tratamiento de nulos, transformación de columnas |
| **PostgreSQL (Supabase)** | Modelado relacional, carga de datos, consultas analíticas |
| **Power BI** | Dashboard interactivo (resumen ejecutivo, logística, satisfacción) |

---

## 🔄 Metodología

### 1. Carga de datos (`scripts/01_carga_datos.py`)
Subida de los 9 CSV a Google Colab, carga a DataFrames y diagnóstico inicial: dimensiones, tipos de datos, valores nulos y duplicados por tabla.

### 2. Limpieza de datos (`scripts/02_limpieza_datos.py`)
- **`orders`**: nulos en fechas (`order_approved_at`, `order_delivered_carrier_date`, `order_delivered_customer_date`) tratados como eventos no ocurridos (pedidos cancelados/no entregados), sin imputación.
- **`products`**: ficha de producto incompleta (categoría, longitud de nombre/descripción, cantidad de fotos) tratada con "sem_categoria" y ceros, según corresponda; nulos en peso/dimensiones imputados con la mediana.
- **`reviews`**: campos de comentario (opcionales en el formulario) tratados como texto vacío, no como error de datos; duplicados por `review_id` eliminados.
- Conversión de columnas de fecha (texto → datetime) en `orders`, `order_items` y `reviews`.
- Eliminación de duplicados exactos en todas las tablas.
- **Decisión de diseño:** las tablas se mantienen limpias pero normalizadas(sin unificar), dejando los filtros de negocio para la capa SQL.

### 3. Procesamiento de geolocalización (`scripts/03_geolocation_procesamiento.py`)
- Tabla original (~1,000,000 filas) reducida a ~19,000-20,000 registros (uno por código postal), promediando latitud/longitud, debido a múltiples coordenadas GPS por mismo código postal.
- Detección y corrección de códigos postales presentes en `customers` pero ausentes en `geolocation` (necesario para mantener la integridad de la Foreign Key al cargar a SQL).

### 4. Conexión y carga a base de datos (`scripts/04_conexion_supabase.py`, `scripts/05_carga_supabase.py`)
- Conexión a PostgreSQL (Supabase) desde Google Colab mediante SQLAlchemy.
- Carga de las 8 tablas respetando el orden de dependencias: Geolocation → Customers → Sellers → Products → Orders → Order Items → Payments → Reviews.

### 5. Análisis con SQL (`/sql`)
Consultas organizadas en 3 módulos documentados:
- **`consultas_ventas.sql`:** vista base de pedidos entregados, tendencia mensual, top categorías, ticket promedio, ventas por región.
- **`consultas_logistica.sql`:** tiempos de entrega real vs. estimado, % de pedidos tardíos, vendedores con más retrasos, tiempo por tramo (despacho vs. transporte).
- **`consultas_satisfaccion.sql`:** distribución de ratings, relación entre retraso y rating, categorías/vendedores con peor calificación.

### 6. Dashboard interactivo (Power BI)
*(sección a completar — ver [Estado del proyecto](#-estado-del-proyecto))*

---

## 🚀 Cómo reproducir este proyecto

1. Clonar el repositorio.
2. Descargar el dataset desde [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
3. Abrir los scripts en Google Colab (o adaptar localmente) y correrlos en orden: `01` → `02` → `03` → `04` → `05`.
4. Tener una base de datos PostgreSQL (Supabase u otra) con el esquema creado, y correr los scripts de `/sql` para generar las vistas de análisis.
5. Abrir `powerbi/olist_dashboard.pbix` con Power BI Desktop y actualizar la conexión a tu propia base de datos.

**Dependencias de Python:** ver `requirements.txt`.

---

## 📌 Estado del proyecto

- [x] Carga y limpieza de datos
- [x] Procesamiento de geolocalización
- [x] Modelado y carga a base de datos relacional (Supabase)
- [x] Consultas SQL de análisis (ventas, logística, satisfacción)
- [ ] Dashboard interactivo en Power BI
- [ ] Documentación final de insights

---

## 👤 Autor

**[Alexis Boza Acuña]**
[alexisboza2020@gmail.com]
