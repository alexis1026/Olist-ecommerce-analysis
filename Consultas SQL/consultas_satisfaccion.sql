/*
================================================================================
 PROYECTO      : Análisis de E-commerce - Dataset Olist
 MÓDULO        : Consultas SQL - Satisfacción del Cliente
 BASE DE DATOS : PostgreSQL (Supabase)
================================================================================
 DESCRIPCIÓN GENERAL
 --------------------------------------------------------------------------
 Este módulo contiene las consultas relacionadas con la calificación que
 los clientes dan a sus pedidos (review_score): distribución general,
 relación con el tiempo de entrega, y desempeño por categoría de
 producto y por vendedor.

 Estas consultas alimentan directamente la página "Satisfacción del
 Cliente" del dashboard de Power BI, y en particular la Consulta 2 es
 la base del insight principal del proyecto (impacto del retraso en
 la satisfacción).

 DEPENDENCIAS
 --------------------------------------------------------------------------
 Requiere que existan las tablas: orders, order_items, products, sellers,
 reviews
 Requiere la vista: orders_delivered (definida en consultas_ventas.sql)

 CONVENCIONES
 --------------------------------------------------------------------------
 - review_score es una escala de 1 (peor) a 5 (mejor).
 - Las consultas que agrupan por categoría o vendedor excluyen grupos con
   pocos pedidos (HAVING COUNT >= 20) para evitar que una muestra pequeña
   distorsione el rating promedio.
================================================================================
*/


-- ================================================================
-- SECCIÓN 1: VISIÓN GENERAL DE SATISFACCIÓN
-- ================================================================

-- --------------------------------------------------------------------------
-- Consulta: Distribución general de ratings
-- Propósito: conocer cómo se reparten las calificaciones de 1 a 5 estrellas.
-- Nota técnica: usa una función de ventana (SUM(...) OVER ()) para calcular
--            el porcentaje de cada rating sin necesidad de una subconsulta
--            aparte para el total general.
-- Salida esperada: 5 filas (una por cada valor de review_score).
-- Uso en Power BI: gráfico de barras simple.
-- --------------------------------------------------------------------------
SELECT
    r.review_score,
    COUNT(*) AS cantidad_reviews,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS porcentaje
FROM reviews r
JOIN orders_delivered o ON r.order_id = o.order_id
GROUP BY r.review_score
ORDER BY r.review_score;


-- ================================================================
-- SECCIÓN 2: RELACIÓN ENTRE ENTREGA Y SATISFACCIÓN
-- ================================================================

-- --------------------------------------------------------------------------
-- Consulta: Rating promedio - pedidos a tiempo vs. pedidos tardíos
-- Propósito: cuantificar el impacto directo del retraso en la satisfacción
--            del cliente. Es el insight central del proyecto.
-- Salida esperada: 2 filas ("A tiempo" / "Tardío") con su rating promedio.
-- Uso en Power BI: comparación visual (tarjetas o gráfico de barras).
-- --------------------------------------------------------------------------
SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Tardío'
        ELSE 'A tiempo'
    END AS tipo_entrega,
    COUNT(*)                            AS total_pedidos,
    ROUND(AVG(r.review_score)::numeric, 2) AS rating_promedio
FROM orders_delivered o
JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY tipo_entrega;


-- --------------------------------------------------------------------------
-- Consulta: Rating promedio según magnitud del retraso
-- Propósito: profundizar la consulta anterior, mostrando si el rating
--            empeora progresivamente a medida que el retraso es mayor.
-- Nota técnica: el retraso se agrupa en rangos (bins) para que el
--            resultado sea legible como gráfico de barras, en vez de un
--            gráfico de dispersión con cientos de puntos individuales.
-- Salida esperada: 4 filas (rangos de retraso) con su rating promedio.
-- Uso en Power BI: gráfico de barras ordenado por severidad de retraso.
-- --------------------------------------------------------------------------
SELECT
    CASE
        WHEN (o.order_delivered_customer_date - o.order_estimated_delivery_date) <= INTERVAL '0 days'
            THEN '0. A tiempo o antes'
        WHEN (o.order_delivered_customer_date - o.order_estimated_delivery_date) <= INTERVAL '3 days'
            THEN '1-3 días tarde'
        WHEN (o.order_delivered_customer_date - o.order_estimated_delivery_date) <= INTERVAL '7 days'
            THEN '4-7 días tarde'
        ELSE 'Más de 7 días tarde'
    END AS rango_retraso,
    COUNT(*)                               AS total_pedidos,
    ROUND(AVG(r.review_score)::numeric, 2) AS rating_promedio
FROM orders_delivered o
JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY rango_retraso
ORDER BY rango_retraso;


-- ================================================================
-- SECCIÓN 3: DESEMPEÑO POR CATEGORÍA Y VENDEDOR
-- ================================================================

-- --------------------------------------------------------------------------
-- Consulta: Top 10 categorías con peor rating promedio
-- Propósito: identificar categorías de producto con problemas recurrentes
--            de calidad o expectativa (no necesariamente de entrega).
-- Nota técnica: HAVING COUNT >= 20 excluye categorías con muestra pequeña.
-- Salida esperada: 10 filas, categoría + rating promedio.
-- Uso en Power BI: tabla "categorías a revisar".
-- --------------------------------------------------------------------------
SELECT
    p.product_category_name_english AS categoria,
    COUNT(DISTINCT o.order_id)      AS total_pedidos,
    ROUND(AVG(r.review_score)::numeric, 2) AS rating_promedio
FROM orders_delivered o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN reviews r ON o.order_id = r.order_id
GROUP BY categoria
HAVING COUNT(DISTINCT o.order_id) >= 20
ORDER BY rating_promedio ASC
LIMIT 10;


-- --------------------------------------------------------------------------
-- Consulta: Vendedores con peor rating promedio (solo los más activos)
-- Propósito: identificar vendedores con problemas de calidad percibida,
--            más allá de su desempeño logístico (ver consultas_logistica.sql).
-- Nota técnica: HAVING COUNT >= 20 excluye vendedores con muestra pequeña.
-- Salida esperada: 10 filas, vendedor + rating promedio.
-- Uso en Power BI: tabla "vendedores a revisar" (complementaria a logística).
-- --------------------------------------------------------------------------
SELECT
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    ROUND(AVG(r.review_score)::numeric, 2) AS rating_promedio
FROM orders_delivered o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN reviews r ON o.order_id = r.order_id
GROUP BY s.seller_id, s.seller_state
HAVING COUNT(DISTINCT o.order_id) >= 20
ORDER BY rating_promedio ASC
LIMIT 10;
