-- 1. QUANTIDADE DE REGISTROS

SELECT 'CUSTOMERS' AS tabela, COUNT(*) AS qtd
FROM stg_olist_customers

UNION ALL

SELECT 'ORDERS', COUNT(*)
FROM stg_olist_orders

UNION ALL

SELECT 'ORDER_ITEMS', COUNT(*)
FROM stg_olist_order_items

UNION ALL

SELECT 'PAYMENTS', COUNT(*)
FROM stg_olist_order_payments

UNION ALL

SELECT 'REVIEWS', COUNT(*)
FROM stg_olist_order_reviews

UNION ALL

SELECT 'PRODUCTS', COUNT(*)
FROM stg_olist_products

UNION ALL

SELECT 'SELLERS', COUNT(*)
FROM stg_olist_sellers;

-- 2. DUPLICIDADE DAS PRINCIPAIS CHAVES

-- Orders
SELECT
    order_id,
    COUNT(*) AS qtd
FROM stg_olist_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Customers
SELECT
    customer_id,
    COUNT(*) AS qtd
FROM stg_olist_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Products
SELECT
    product_id,
    COUNT(*) AS qtd
FROM stg_olist_products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Sellers
SELECT
    seller_id,
    COUNT(*) AS qtd
FROM stg_olist_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- 3. INTEGRIDADE REFERENCIAL

-- Pedidos sem cliente
SELECT COUNT(*) AS pedidos_sem_cliente
FROM stg_olist_orders o
LEFT JOIN stg_olist_customers c
    ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

-- Itens sem produto
SELECT COUNT(*) AS itens_sem_produto
FROM stg_olist_order_items oi
LEFT JOIN stg_olist_products p
    ON p.product_id = oi.product_id
WHERE p.product_id IS NULL;

-- Itens sem vendedor
SELECT COUNT(*) AS itens_sem_vendedor
FROM stg_olist_order_items oi
LEFT JOIN stg_olist_sellers s
    ON s.seller_id = oi.seller_id
WHERE s.seller_id IS NULL;

-- 4. VALORES NULOS

-- Orders
SELECT
    COUNT(*) AS total,
    SUM(CASE
        WHEN customer_id IS NULL THEN 1
        ELSE 0
    END) AS customer_id_null,
    SUM(CASE
        WHEN order_purchase_timestamp IS NULL THEN 1
        ELSE 0
    END) AS purchase_date_null,
    SUM(CASE
        WHEN order_status IS NULL THEN 1
        ELSE 0
    END) AS status_null
FROM stg_olist_orders;

-- Order Items
SELECT
    COUNT(*) AS total,
    SUM(CASE
        WHEN product_id IS NULL THEN 1
        ELSE 0
    END) AS product_id_null,
    SUM(CASE
        WHEN seller_id IS NULL THEN 1
        ELSE 0
    END) AS seller_id_null,
    SUM(CASE
        WHEN price IS NULL THEN 1
        ELSE 0
    END) AS price_null,
    SUM(CASE
        WHEN freight_value IS NULL THEN 1
        ELSE 0
    END) AS freight_null
FROM stg_olist_order_items;

-- Reviews
SELECT
    COUNT(*) AS total,
    SUM(CASE
        WHEN review_score IS NULL THEN 1
        ELSE 0
    END) AS score_null,
    SUM(CASE
        WHEN review_creation_date IS NULL THEN 1
        ELSE 0
    END) AS creation_date_null
FROM stg_olist_order_reviews;

-- 5. VALIDAÇÃO DAS AVALIAÇÕES

SELECT
    review_score,
    COUNT(*) AS quantidade,
    ROUND(
        COUNT(*) * 100 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentual
FROM stg_olist_order_reviews
GROUP BY review_score
ORDER BY review_score;

-- 6. VALIDAÇÃO DA CHAVE DE ORDER_ITEMS
-- A combinação order_id + order_item_id deve identificar unicamente cada item do pedido.

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS qtd
FROM stg_olist_order_items
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;

-- 7. CLIENTES ÚNICOS
-- Comparação entre o identificador do registro e o identificador real do cliente.

SELECT
    COUNT(DISTINCT customer_id) AS clientes,
    COUNT(DISTINCT customer_unique_id) AS clientes_reais
FROM stg_olist_customers;

-- Clientes que possuem pedidos
SELECT
    COUNT(DISTINCT o.customer_id) AS clientes_com_pedido,
    COUNT(DISTINCT c.customer_unique_id) AS clientes_reais_com_pedido
FROM stg_olist_orders o
JOIN stg_olist_customers c
    ON c.customer_id = o.customer_id;

-- 8. DISTRIBUIÇÃO DOS STATUS DOS PEDIDOS

SELECT
    order_status,
    COUNT(*) AS quantidade
FROM stg_olist_orders
GROUP BY order_status
ORDER BY quantidade DESC;