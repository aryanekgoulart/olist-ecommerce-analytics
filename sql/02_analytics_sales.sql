-- Objetivo: Criar uma camada analítica para análise comercial, evitando duplicidade causada pelos diferentes níveis de granularidade das tabelas.

-- 1. VALOR DOS ITENS POR PEDIDO

CREATE OR REPLACE VIEW vw_olist_order_sales AS
SELECT
    oi.order_id,
    SUM(oi.price) AS product_value,
    SUM(oi.freight_value) AS freight_value,
    SUM(oi.price + oi.freight_value) AS total_order_value
FROM stg_olist_order_items oi
GROUP BY
    oi.order_id;

-- 2. VISÃO ANALÍTICA DE PEDIDOS

CREATE OR REPLACE VIEW vw_olist_orders_analytics AS
SELECT
    o.order_id,
    c.customer_unique_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    s.product_value,
    s.freight_value,
    s.total_order_value
FROM stg_olist_orders o
LEFT JOIN stg_olist_customers c
    ON c.customer_id = o.customer_id
LEFT JOIN vw_olist_order_sales s
    ON s.order_id = o.order_id;

-- 3. EVOLUÇÃO MENSAL DE VENDAS

SELECT
    TRUNC(order_purchase_timestamp, 'MM') AS mes,
    COUNT(*) AS pedidos,
    ROUND(SUM(total_order_value), 2) AS valor_pedidos,
    ROUND(AVG(total_order_value), 2) AS ticket_medio
FROM vw_olist_orders_analytics
WHERE order_status = 'delivered'
GROUP BY
    TRUNC(order_purchase_timestamp, 'MM')
ORDER BY
    mes;

-- 4. CRESCIMENTO MENSAL

WITH vendas_mensais AS (
    SELECT
        TRUNC(order_purchase_timestamp, 'MM') AS mes,
        COUNT(*) AS pedidos,
        SUM(total_order_value) AS valor_pedidos
    FROM vw_olist_orders_analytics
    WHERE order_status = 'delivered'
    GROUP BY
        TRUNC(order_purchase_timestamp, 'MM')
),
vendas_com_anterior AS (
    SELECT
        mes,
        pedidos,
        valor_pedidos,
        LAG(valor_pedidos) OVER (
            ORDER BY mes
        ) AS valor_mes_anterior
    FROM vendas_mensais
)
SELECT
    mes,
    pedidos,
    ROUND(valor_pedidos, 2) AS valor_pedidos,
    ROUND(
        valor_pedidos / pedidos,
        2
    ) AS ticket_medio,
    ROUND(
        (valor_pedidos - valor_mes_anterior)
        / valor_mes_anterior * 100,
        2
    ) AS crescimento_percentual
FROM vendas_com_anterior
ORDER BY mes;

-- 5. EVOLUÇÃO MENSAL - PERÍODO ANALISADO

WITH vendas_mensais AS (
    SELECT
        TRUNC(order_purchase_timestamp, 'MM') AS mes,
        COUNT(*) AS pedidos,
        SUM(total_order_value) AS valor_pedidos
    FROM vw_olist_orders_analytics
    WHERE order_status = 'delivered'
    AND order_purchase_timestamp >= DATE '2017-01-01'
    GROUP BY
        TRUNC(order_purchase_timestamp, 'MM')
),
vendas_com_anterior AS (
    SELECT
        mes,
        pedidos,
        valor_pedidos,
        LAG(valor_pedidos) OVER (
            ORDER BY mes
        ) AS valor_mes_anterior
    FROM vendas_mensais
)
SELECT
    mes,
    pedidos,
    ROUND(valor_pedidos, 2) AS valor_pedidos,
    ROUND(
        valor_pedidos / pedidos, 2
    ) AS ticket_medio,
    ROUND(
        (valor_pedidos - valor_mes_anterior)
        / valor_mes_anterior * 100,
        2
    ) AS crescimento_percentual
FROM vendas_com_anterior
ORDER BY mes;