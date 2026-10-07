/*
================================================================================
 PROYECTO      : Análisis de E-commerce - Dataset Olist
 MÓDULO        : Consultas SQL - Ventas
 BASE DE DATOS : PostgreSQL (Supabase)
================================================================================
 DESCRIPCIÓN GENERAL
 --------------------------------------------------------------------------
 Este módulo contiene las consultas analíticas relacionadas con el
 desempeño comercial de la plataforma: tendencia de ventas, categorías
 más vendidas, ticket promedio y distribución geográfica de las ventas.

 Estas consultas alimentan directamente la página "Resumen Ejecutivo"
 del dashboard de Power BI.

 DEPENDENCIAS
 --------------------------------------------------------------------------
 Requiere que existan las tablas: orders, order_items, products, customers
 Requiere la vista: orders_delivered (Solo analizaremos los pedidos que ya fueron entregados)

 CONVENCIONES
 --------------------------------------------------------------------------
 - Todas las consultas filtran implícitamente por pedidos con estado
   'delivered', a través de la vista `orders_delivered`.
 - Los montos monetarios se redondean a 2 decimales con ROUND(..., 2).
 - Los alias de columnas están en español, pensados para facilitar
   la lectura al conectar directamente con Power BI.
================================================================================
*/


-- ================================================================
-- SECCIÓN 1: VISTA BASE
-- ================================================================

-- --------------------------------------------------------------------------
-- Vista: orders_delivered
-- Propósito: centralizar el filtro de negocio "pedido entregado" en un
--            solo lugar, para no repetir WHERE order_status = 'delivered'
--            en cada consulta del proyecto (ventas, logística, satisfacción).
-- --------------------------------------------------------------------------
CREATE OR REPLACE VIEW orders_delivered AS
SELECT *
FROM orders
WHERE order_status = 'delivered';


-- ================================================================
-- SECCIÓN 2: TENDENCIA DE VENTAS
-- ================================================================

-- --------------------------------------------------------------------------
-- Consulta: Ventas totales por mes
-- Propósito: visualizar la evolución mensual de ventas y volumen de pedidos.
-- Salida esperada: una fila por mes, con total de pedidos y ventas ($).
-- Uso en Power BI: gráfico de líneas de tendencia mensual.
-- --------------------------------------------------------------------------
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS mes,
    COUNT(DISTINCT o.order_id)                       AS total_pedidos,
    ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS ventas_totales
FROM orders_delivered o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY mes
ORDER BY mes;


-- ================================================================
-- SECCIÓN 3: DESEMPEÑO POR CATEGORÍA
-- ================================================================

-- --------------------------------------------------------------------------
-- Consulta: Top 10 categorías más vendidas
-- Propósito: identificar los productos estrella del catálogo.
-- Salida esperada: 10 filas, categoría + unidades vendidas + ventas totales.
-- Uso en Power BI: gráfico de barras horizontales.
-- --------------------------------------------------------------------------
SELECT
    p.product_category_name_english AS categoria,
    COUNT(oi.order_item_id)         AS unidades_vendidas,
    ROUND(SUM(oi.price)::numeric, 2) AS ventas_totales
FROM order_items oi
JOIN orders_delivered o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY categoria
ORDER BY ventas_totales DESC
LIMIT 10;


-- --------------------------------------------------------------------------
-- Consulta: Evolución mensual de las 5 categorías líderes
-- Propósito: observar si las categorías top mantienen su posición en el
--            tiempo o si hay estacionalidad relevante.
-- Técnica utilizada: CTE (WITH) para calcular primero el top 5, y luego
--            traer su serie temporal completa.
-- Salida esperada: una fila por combinación mes + categoría.
-- Uso en Power BI: gráfico de líneas múltiples (una línea por categoría).
-- --------------------------------------------------------------------------
WITH top_categorias AS (
    SELECT p.product_category_name_english AS categoria
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY categoria
    ORDER BY SUM(oi.price) DESC
    LIMIT 5
)
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS mes,
    p.product_category_name_english                 AS categoria,
    ROUND(SUM(oi.price)::numeric, 2)                 AS ventas
FROM orders_delivered o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE p.product_category_name_english IN (SELECT categoria FROM top_categorias)
GROUP BY mes, categoria
ORDER BY mes, categoria;


-- ================================================================
-- SECCIÓN 4: INDICADORES GENERALES (KPIs)
-- ================================================================

-- --------------------------------------------------------------------------
-- Consulta: Ticket promedio por pedido
-- Propósito: calcular el valor promedio que gasta un cliente por pedido,
--            incluyendo el costo de envío.
-- Nota técnica: se usa una subconsulta porque un pedido puede tener varios
--            ítems; primero se suma por pedido y luego se promedia, para
--            no promediar a nivel de ítem individual.
-- Salida esperada: un único valor (KPI).
-- Uso en Power BI: tarjeta KPI en el resumen ejecutivo.
-- --------------------------------------------------------------------------
SELECT
    ROUND(AVG(total_pedido)::numeric, 2) AS ticket_promedio
FROM (
    SELECT
        o.order_id,
        SUM(oi.price + oi.freight_value) AS total_pedido
    FROM orders_delivered o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id
) AS pedidos_totales;


-- ================================================================
-- SECCIÓN 5: DISTRIBUCIÓN GEOGRÁFICA
-- ================================================================

-- --------------------------------------------------------------------------
-- Consulta: Ventas por estado del cliente
-- Propósito: identificar las regiones con mayor volumen de negocio.
-- Salida esperada: una fila por estado, con total de pedidos y ventas.
-- Uso en Power BI: mapa coroplético o gráfico de barras por región.
-- --------------------------------------------------------------------------
SELECT
    c.customer_state                                   AS estado,
    COUNT(DISTINCT o.order_id)                          AS total_pedidos,
    ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS ventas_totales
FROM orders_delivered o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY estado
ORDER BY ventas_totales DESC;
