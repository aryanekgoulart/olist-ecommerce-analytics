-- Objetivo: Analisar desempenho de categorias e produtos em valor, volume vendido e participação nas vendas.

-- 1. VALOR POR CATEGORIA

SELECT
    p.product_category_name AS categoria,
    COUNT(DISTINCT oi.order_id) AS pedidos,
    COUNT(*) AS itens_vendidos,
    ROUND(SUM(oi.price), 2) AS valor_produtos,
    ROUND(SUM(oi.freight_value), 2) AS valor_frete,
    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS valor_total
FROM stg_olist_order_items oi
INNER JOIN stg_olist_orders o
    ON o.order_id = oi.order_id
INNER JOIN stg_olist_products p
    ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
GROUP BY
    p.product_category_name
ORDER BY
    valor_total DESC;

-- 2. VOLUME VENDIDO POR CATEGORIA

SELECT
    p.product_category_name AS categoria,
    COUNT(*) AS itens_vendidos,
    COUNT(DISTINCT oi.order_id) AS pedidos,
    ROUND(
        COUNT(*) * 100 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentual_itens
FROM stg_olist_order_items oi
INNER JOIN stg_olist_orders o
    ON o.order_id = oi.order_id
INNER JOIN stg_olist_products p
    ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
GROUP BY
    p.product_category_name
ORDER BY
    itens_vendidos DESC;

-- 3. TICKET MÉDIO POR CATEGORIA

SELECT
    p.product_category_name AS categoria,
    COUNT(DISTINCT oi.order_id) AS pedidos,
    ROUND(
        SUM(oi.price + oi.freight_value)
        / COUNT(DISTINCT oi.order_id),
        2
    ) AS ticket_medio_categoria
FROM stg_olist_order_items oi
INNER JOIN stg_olist_orders o
    ON o.order_id = oi.order_id
INNER JOIN stg_olist_products p
    ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
GROUP BY
    p.product_category_name
HAVING COUNT(DISTINCT oi.order_id) >= 20
ORDER BY
    ticket_medio_categoria DESC;

-- 4. TOP 20 PRODUTOS POR VALOR

SELECT
    oi.product_id,
    p.product_category_name AS categoria,
    COUNT(*) AS itens_vendidos,
    COUNT(DISTINCT oi.order_id) AS pedidos,
    ROUND(SUM(oi.price), 2) AS valor_produtos,
    ROUND(SUM(oi.freight_value), 2) AS valor_frete,
    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS valor_total
FROM stg_olist_order_items oi
INNER JOIN stg_olist_orders o
    ON o.order_id = oi.order_id
INNER JOIN stg_olist_products p
    ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
GROUP BY
    oi.product_id,
    p.product_category_name
ORDER BY
    valor_total DESC
FETCH FIRST 20 ROWS ONLY;