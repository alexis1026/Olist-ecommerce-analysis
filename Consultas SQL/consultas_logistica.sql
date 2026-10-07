/*
================================================================================
 PROYECTO      : Análisis de E-commerce - Dataset Olist
 MÓDULO        : Consultas SQL - Logística
 BASE DE DATOS : PostgreSQL (Supabase)
================================================================================
 DESCRIPCIÓN GENERAL
 --------------------------------------------------------------------------
 Este módulo contiene las consultas relacionadas con el desempeño de
 entrega: tiempos de entrega (real vs. estimado), tasa de pedidos
 tardíos, desempeño por región y por vendedor, y el desglose del tiempo
 de entrega por etapa (despacho vs. transporte).

 Estas consultas alimentan directamente la página "Logística" del
 dashboard de Power BI.

 DEPENDENCIAS
 --------------------------------------------------------------------------
 Requiere que existan las tablas: orders, order_items, customers, sellers
 Requiere la vista: orders_delivered (definida en consultas_ventas.sql)

 CONVENCIONES
 --------------------------------------------------------------------------
 - Un pedido se considera "tardío" si order_delivered_customer_date es
   posterior a order_estimated_delivery_date.
 - Las consultas que agrupan por vendedor o categoría excluyen grupos con
   muy pocos pedidos (HAVING COUNT >= 10) para evitar que un vendedor con
   1-2 pedidos distorsione el ranking con un 100% de tardanza.
 - FILTER (WHERE ...) es sintaxis específica de PostgreSQL para contar
   condicionalmente dentro de un COUNT, usada en vez de CASE WHEN por
   legibilidad.
================================================================================
*/


-- ================================================================
-- SECCIÓN 1: INDICADORES GENERALES DE ENTREGA
-- ================================================================

-- --------------------------------------------------------------------------
-- Consulta: Tiempo promedio de entrega (real vs. estimado)
-- Propósito: comparar cuántos días tarda en promedio un pedido en llegar,
--            frente a lo que la plataforma le prometió al cliente.
-- Salida esperada: un único registro con dos valores (KPIs).
-- Uso en Power BI: tarjetas KPI en la página de logística.
-- --------------------------------------------------------------------------
SELECT
    ROUND(AVG(EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)))::numeric, 1)
        AS dias_entrega_promedio_real,
    ROUND(AVG(EXTRACT(DAY FROM (order_estimated_delivery_date - order_purchase_timestamp)))::numeric, 1)
        AS dias_entrega_promedio_estimado
FROM orders_delivered
WHERE order_delivered_customer_date IS NOT NULL;


-- --------------------------------------------------------------------------
-- Consulta: Porcentaje de pedidos con retraso
-- Propósito: cuantificar qué proporción de pedidos llegó después de la
--            fecha estimada de entrega.
-- Salida esperada: un único registro (pedidos tardíos, total, % tardíos).
-- Uso en Power BI: tarjeta KPI "% de pedidos tardíos".
-- --------------------------------------------------------------------------
SELECT
    COUNT(*) FILTER (WHERE order_delivered_customer_date > order_estimated_delivery_date)
        AS pedidos_tardios,
    COUNT(*) AS total_pedidos,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_delivered_customer_date > order_estimated_delivery_date)
        / COUNT(*), 2
    ) AS porcentaje_tardios
FROM orders_delivered
WHERE order_delivered_customer_date IS NOT NULL;


-- ================================================================
-- SECCIÓN 2: DESEMPEÑO POR REGIÓN
-- ================================================================

-- --------------------------------------------------------------------------
-- Consulta: Retrasos por estado del cliente
-- Propósito: identificar qué regiones concentran más problemas de entrega.
-- Salida esperada: una fila por estado, con % de tardanza y días promedio.
-- Uso en Power BI: mapa o gráfico de barras por región.
-- --------------------------------------------------------------------------
SELECT
    c.customer_state AS estado,
    COUNT(*)          AS total_pedidos,
    COUNT(*) FILTER (WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date)
        AS pedidos_tardios,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date)
        / COUNT(*), 2
    ) AS porcentaje_tardios,
    ROUND(AVG(EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)))::numeric, 1)
        AS dias_entrega_promedio
FROM orders_delivered o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY estado
ORDER BY porcentaje_tardios DESC;


-- ================================================================
-- SECCIÓN 3: DESEMPEÑO POR VENDEDOR
-- ================================================================

-- --------------------------------------------------------------------------
-- Consulta: Top 10 vendedores con más pedidos retrasados
-- Propósito: identificar vendedores que requieren seguimiento por
--            desempeño logístico deficiente.
-- Nota técnica: HAVING COUNT >= 10 excluye vendedores con muestra muy
--            pequeña, donde el % de tardanza no es estadísticamente
--            representativo.
-- Salida esperada: 10 filas, vendedor + % de pedidos tardíos.
-- Uso en Power BI: tabla "vendedores a revisar".
-- --------------------------------------------------------------------------
SELECT
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS total_pedidos,
    COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
    ) AS pedidos_tardios,
    ROUND(
        100.0 * COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
        ) / COUNT(DISTINCT o.order_id), 2
    ) AS porcentaje_tardios
FROM orders_delivered o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY s.seller_id, s.seller_state
HAVING COUNT(DISTINCT o.order_id) >= 10
ORDER BY porcentaje_tardios DESC
LIMIT 10;


-- ================================================================
-- SECCIÓN 4: DESGLOSE DEL TIEMPO DE ENTREGA
-- ================================================================

-- --------------------------------------------------------------------------
-- Consulta: Tiempo de entrega por etapa (despacho vs. transporte)
-- Propósito: identificar en qué tramo del proceso se origina el retraso:
--            ¿el vendedor tarda en despachar, o el transportista tarda
--            en llevar el paquete al cliente?
-- Salida esperada: un único registro con 3 promedios (días).
-- Uso en Power BI: gráfico de barras apiladas o tarjetas comparativas.
-- --------------------------------------------------------------------------
SELECT
    ROUND(AVG(EXTRACT(DAY FROM (order_delivered_carrier_date - order_purchase_timestamp)))::numeric, 1)
        AS dias_hasta_envio,
    ROUND(AVG(EXTRACT(DAY FROM (order_delivered_customer_date - order_delivered_carrier_date)))::numeric, 1)
        AS dias_transporte,
    ROUND(AVG(EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)))::numeric, 1)
        AS dias_totales
FROM orders_delivered
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL;
