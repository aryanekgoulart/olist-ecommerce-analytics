-- Objetivo: Analisar desempenho logístico e investigar a relação entre prazo de entrega e satisfação dos clientes.

-- 1. STATUS DE ENTREGA

SELECT
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'No prazo'
        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Atrasado'
    END AS status_entrega,
    COUNT(*) AS pedidos
FROM stg_olist_orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL
AND order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'No prazo'
        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Atrasado'
    END;

-- 2. ATRASO X AVALIAÇÃO

SELECT
    CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
            THEN 'No prazo'
        ELSE 'Atrasado'
    END AS status_entrega,
    COUNT(*) AS pedidos_avaliados,
    ROUND(AVG(r.review_score), 2) AS nota_media,
    ROUND(
        SUM(
            CASE
                WHEN r.review_score <= 2 THEN 1
                ELSE 0
            END
        ) * 100 / COUNT(*),
        2
    ) AS percentual_notas_baixas,
    ROUND(
        SUM(
            CASE
                WHEN r.review_score >= 4 THEN 1
                ELSE 0
            END
        ) * 100 / COUNT(*),
        2
    ) AS percentual_notas_altas
FROM stg_olist_orders o
INNER JOIN stg_olist_order_reviews r
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
            THEN 'No prazo'
        ELSE 'Atrasado'
    END
ORDER BY status_entrega;

-- 3. IMPACTO DA QUANTIDADE DE DIAS DE ATRASO NA AVALIAÇÃO

WITH entregas AS (
    SELECT
        o.order_id,
        TRUNC(
            CAST(o.order_delivered_customer_date AS DATE)
            - CAST(o.order_estimated_delivery_date AS DATE)
        ) AS dias_atraso,
        r.review_score
    FROM stg_olist_orders o
    INNER JOIN stg_olist_order_reviews r
        ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
),
faixas AS (
    SELECT
        order_id,
        dias_atraso,
        review_score,
        CASE
            WHEN dias_atraso <= 0 THEN 'No prazo'
            WHEN dias_atraso BETWEEN 1 AND 3 THEN '1 a 3 dias'
            WHEN dias_atraso BETWEEN 4 AND 7 THEN '4 a 7 dias'
            WHEN dias_atraso BETWEEN 8 AND 14 THEN '8 a 14 dias'
            WHEN dias_atraso BETWEEN 15 AND 30 THEN '15 a 30 dias'
            ELSE 'Mais de 30 dias'
        END AS faixa_atraso
    FROM entregas
)
SELECT
    faixa_atraso,
    COUNT(*) AS pedidos,
    ROUND(AVG(review_score), 2) AS nota_media,
    ROUND(
        SUM(
            CASE
                WHEN review_score <= 2 THEN 1
                ELSE 0
            END
        ) * 100 / COUNT(*),
        2
    ) AS percentual_notas_baixas
FROM faixas
GROUP BY faixa_atraso
ORDER BY
    CASE faixa_atraso
        WHEN 'No prazo' THEN 1
        WHEN '1 a 3 dias' THEN 2
        WHEN '4 a 7 dias' THEN 3
        WHEN '8 a 14 dias' THEN 4
        WHEN '15 a 30 dias' THEN 5
        WHEN 'Mais de 30 dias' THEN 6
    END;

-- 4. ATRASO POR ESTADO

SELECT
    c.customer_state AS estado,
    COUNT(*) AS pedidos,
    SUM(
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
            ELSE 0
        END
    ) AS pedidos_atrasados,
    ROUND(
        SUM(
            CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                    THEN 1
                ELSE 0
            END
        ) * 100 / COUNT(*),
        2
    ) AS percentual_atraso
FROM stg_olist_orders o
INNER JOIN stg_olist_customers c
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    c.customer_state
ORDER BY
    percentual_atraso DESC;

-- 5. TEMPO MÉDIO DE ENTREGA POR ESTADO

SELECT
    c.customer_state AS estado,
    COUNT(*) AS pedidos,
    ROUND(
        AVG(
            CAST(o.order_delivered_customer_date AS DATE)
            - CAST(o.order_purchase_timestamp AS DATE)
        ),
        2
    ) AS dias_medio_entrega
FROM stg_olist_orders o
INNER JOIN stg_olist_customers c
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
AND o.order_purchase_timestamp IS NOT NULL
GROUP BY
    c.customer_state
ORDER BY
    dias_medio_entrega DESC;