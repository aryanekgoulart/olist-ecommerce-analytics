-- 1. FREQUÊNCIA DE COMPRA POR CLIENTE

WITH clientes AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS quantidade_pedidos
    FROM stg_olist_customers c
    INNER JOIN stg_olist_orders o ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id
)
SELECT
    quantidade_pedidos,
    COUNT(*) AS quantidade_clientes,
    ROUND(
        COUNT(*) * 100 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentual_clientes
FROM clientes
GROUP BY
    quantidade_pedidos
ORDER BY
    quantidade_pedidos;

-- 2. CLIENTES NOVOS X RECORRENTES

WITH clientes AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS quantidade_pedidos
    FROM stg_olist_customers c
    INNER JOIN stg_olist_orders o
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id
)
SELECT
    COUNT(*) AS clientes_totais,
    SUM(
        CASE
            WHEN quantidade_pedidos = 1 THEN 1
            ELSE 0
        END
    ) AS clientes_compra_unica,
    SUM(
        CASE
            WHEN quantidade_pedidos >= 2 THEN 1
            ELSE 0
        END
    ) AS clientes_recorrentes,
    ROUND(
        SUM(
            CASE
                WHEN quantidade_pedidos >= 2 THEN 1
                ELSE 0
            END
        ) * 100 / COUNT(*),
        2
    ) AS taxa_recorrencia
FROM clientes;

-- 3. VALOR GERADO POR CLIENTE

WITH clientes AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS quantidade_pedidos,
        SUM(s.total_order_value) AS valor_total
    FROM stg_olist_customers c
    INNER JOIN stg_olist_orders o
        ON o.customer_id = c.customer_id
    INNER JOIN vw_olist_order_sales s
        ON s.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id
)
SELECT
    CASE
        WHEN quantidade_pedidos = 1 THEN 'Compra única'
        ELSE 'Recorrente'
    END AS tipo_cliente,
    COUNT(*) AS clientes,
    ROUND(SUM(valor_total), 2) AS valor_total,
    ROUND(AVG(valor_total), 2) AS valor_medio_por_cliente,
    ROUND(
        SUM(valor_total) * 100 /
        SUM(SUM(valor_total)) OVER (),
        2
    ) AS percentual_valor
FROM clientes
GROUP BY
    CASE
        WHEN quantidade_pedidos = 1 THEN 'Compra única'
        ELSE 'Recorrente'
    END
ORDER BY
    valor_total DESC;

-- 4. CONCENTRAÇÃO DE VALOR POR CLIENTE

WITH clientes AS (
    SELECT
        c.customer_unique_id,
        SUM(s.total_order_value) AS valor_total
    FROM stg_olist_customers c
    INNER JOIN stg_olist_orders o
        ON o.customer_id = c.customer_id
    INNER JOIN vw_olist_order_sales s
        ON s.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id
),
clientes_rank AS (
    SELECT
        customer_unique_id,
        valor_total,
        SUM(valor_total) OVER (
            ORDER BY valor_total DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS valor_acumulado,
        SUM(valor_total) OVER () AS valor_total_geral,
        ROW_NUMBER() OVER (
            ORDER BY valor_total DESC
        ) AS ranking
    FROM clientes
)
SELECT
    ranking,
    customer_unique_id,
    ROUND(valor_total, 2) AS valor_total,
    ROUND(
        valor_acumulado / valor_total_geral * 100,
        2
    ) AS percentual_acumulado
FROM clientes_rank
WHERE ranking <= 20
ORDER BY ranking;

-- 5. ANÁLISE DE PARETO

WITH clientes AS (
    SELECT
        c.customer_unique_id,
        SUM(s.total_order_value) AS valor_total
    FROM stg_olist_customers c
    INNER JOIN stg_olist_orders o
        ON o.customer_id = c.customer_id
    INNER JOIN vw_olist_order_sales s
        ON s.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id
),
clientes_rank AS (
    SELECT
        customer_unique_id,
        valor_total,
        ROW_NUMBER() OVER (
            ORDER BY valor_total DESC
        ) AS ranking,
        SUM(valor_total) OVER (
            ORDER BY valor_total DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS valor_acumulado,
        SUM(valor_total) OVER () AS valor_total_geral
    FROM clientes
),
pareto AS (
    SELECT
        ranking,
        customer_unique_id,
        valor_total,
        valor_acumulado / valor_total_geral * 100
            AS percentual_acumulado
    FROM clientes_rank
)
SELECT
    MIN(
        CASE
            WHEN percentual_acumulado >= 50
            THEN ranking
        END
    ) AS clientes_para_50,
    MIN(
        CASE
            WHEN percentual_acumulado >= 80
            THEN ranking
        END
    ) AS clientes_para_80,
    MIN(
        CASE
            WHEN percentual_acumulado >= 90
            THEN ranking
        END
    ) AS clientes_para_90
FROM pareto;

-- 6. BASE RFM

WITH base_clientes AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS ultima_compra,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(s.total_order_value) AS monetary
    FROM stg_olist_customers c
    INNER JOIN stg_olist_orders o
        ON o.customer_id = c.customer_id
    INNER JOIN vw_olist_order_sales s
        ON s.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id
),
data_referencia AS (
    SELECT
        MAX(CAST(order_purchase_timestamp AS DATE)) + 1 AS data_ref
    FROM stg_olist_orders
    WHERE order_status = 'delivered'
)
SELECT
    b.customer_unique_id,
    TRUNC(
        d.data_ref - CAST(b.ultima_compra AS DATE)
    ) AS recency,
    b.frequency,
    ROUND(b.monetary, 2) AS monetary
FROM base_clientes b
CROSS JOIN data_referencia d;

-- 7. DISTRIBUIÇÃO RFM

WITH base_clientes AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS ultima_compra,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(s.total_order_value) AS monetary
    FROM stg_olist_customers c
    INNER JOIN stg_olist_orders o
        ON o.customer_id = c.customer_id
    INNER JOIN vw_olist_order_sales s
        ON s.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id
),
data_referencia AS (
    SELECT
        MAX(CAST(order_purchase_timestamp AS DATE)) + 1 AS data_ref
    FROM stg_olist_orders
    WHERE order_status = 'delivered'
),
rfm AS (
    SELECT
        b.customer_unique_id,
        TRUNC(
            d.data_ref - CAST(b.ultima_compra AS DATE)
        ) AS recency,
        b.frequency,
        b.monetary
    FROM base_clientes b
    CROSS JOIN data_referencia d
)
SELECT
    MIN(recency) AS recency_min,
    MAX(recency) AS recency_max,
    MIN(frequency) AS frequency_min,
    MAX(frequency) AS frequency_max,
    ROUND(MIN(monetary), 2) AS monetary_min,
    ROUND(MAX(monetary), 2) AS monetary_max
FROM rfm;

-- 8. SCORE RFM

WITH base_clientes AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS ultima_compra,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(s.total_order_value) AS monetary
    FROM stg_olist_customers c
    INNER JOIN stg_olist_orders o
        ON o.customer_id = c.customer_id
    INNER JOIN vw_olist_order_sales s
        ON s.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id
),
data_referencia AS (
    SELECT
        MAX(CAST(order_purchase_timestamp AS DATE)) + 1 AS data_ref
    FROM stg_olist_orders
    WHERE order_status = 'delivered'
),
rfm AS (
    SELECT
        b.customer_unique_id,
        TRUNC(
            d.data_ref - CAST(b.ultima_compra AS DATE)
        ) AS recency,
        b.frequency,
        b.monetary
    FROM base_clientes b
    CROSS JOIN data_referencia d
),
scores_base AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        -- Quanto menor a recência, melhor.
        6 - NTILE(5) OVER (
            ORDER BY recency ASC
        ) AS r_score,
        -- Quanto maior o valor, melhor.
        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS m_score
    FROM rfm
),
scores AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        ROUND(monetary, 2) AS monetary,
        r_score,
        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            WHEN frequency BETWEEN 4 AND 5 THEN 4
            WHEN frequency >= 6 THEN 5
        END AS f_score,
        m_score
    FROM scores_base
)
SELECT *
FROM scores
ORDER BY
    r_score DESC,
    f_score DESC,
    m_score DESC;

-- 9. DISTRIBUIÇÃO DOS SCORES RFM

WITH base_clientes AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS ultima_compra,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(s.total_order_value) AS monetary
    FROM stg_olist_customers c
    INNER JOIN stg_olist_orders o
        ON o.customer_id = c.customer_id
    INNER JOIN vw_olist_order_sales s
        ON s.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id
),
data_referencia AS (
    SELECT
        MAX(CAST(order_purchase_timestamp AS DATE)) + 1 AS data_ref
    FROM stg_olist_orders
    WHERE order_status = 'delivered'
),
rfm AS (
    SELECT
        b.customer_unique_id,
        TRUNC(
            d.data_ref - CAST(b.ultima_compra AS DATE)
        ) AS recency,
        b.frequency,
        b.monetary
    FROM base_clientes b
    CROSS JOIN data_referencia d
),
scores_base AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        6 - NTILE(5) OVER (
            ORDER BY recency ASC
        ) AS r_score,
        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS m_score
    FROM rfm
),
scores AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        r_score,
        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            WHEN frequency BETWEEN 4 AND 5 THEN 4
            WHEN frequency >= 6 THEN 5
        END AS f_score,
        m_score
    FROM scores_base
)
SELECT
    r_score,
    f_score,
    m_score,
    COUNT(*) AS quantidade_clientes
FROM scores
GROUP BY
    r_score,
    f_score,
    m_score
ORDER BY
    r_score DESC,
    f_score DESC,
    m_score DESC;

-- 10. SEGMENTAÇÃO FINAL DE CLIENTES - RFM

WITH base_clientes AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS ultima_compra,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(s.total_order_value) AS monetary
    FROM stg_olist_customers c
    INNER JOIN stg_olist_orders o
        ON o.customer_id = c.customer_id
    INNER JOIN vw_olist_order_sales s
        ON s.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id
),
data_referencia AS (
    SELECT
        MAX(CAST(order_purchase_timestamp AS DATE)) + 1 AS data_ref
    FROM stg_olist_orders
    WHERE order_status = 'delivered'
),
rfm AS (
    SELECT
        b.customer_unique_id,
        TRUNC(
            d.data_ref - CAST(b.ultima_compra AS DATE)
        ) AS recency,
        b.frequency,
        b.monetary
    FROM base_clientes b
    CROSS JOIN data_referencia d
),
scores_base AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        6 - NTILE(5) OVER (
            ORDER BY recency ASC
        ) AS r_score,
        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS m_score
    FROM rfm
),
scores AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        ROUND(monetary, 2) AS monetary,
        r_score,
        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            WHEN frequency BETWEEN 4 AND 5 THEN 4
            WHEN frequency >= 6 THEN 5
        END AS f_score,
        m_score
    FROM scores_base
),
segmentacao AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CASE
            -- Clientes recentes, recorrentes e de alto valor
            WHEN r_score >= 4
            AND f_score >= 2
            AND m_score >= 4
            THEN 'Campeões'
            -- Recorrentes com bom valor, mesmo sem compra tão recente
            WHEN f_score >= 2
            AND m_score >= 3
            THEN 'Fiéis'
            -- Compra recente, ainda sem recorrência
            WHEN r_score = 5
            AND f_score = 1
            THEN 'Novos'
            -- Compra única, mas com alto valor
            WHEN f_score = 1
            AND m_score = 5
            AND r_score >= 3
            THEN 'Alto Valor'
            -- Já tiveram bom valor ou frequência, mas estão afastados
            WHEN r_score <= 2
            AND (
                    f_score >= 2
                    OR m_score >= 4
                )
            THEN 'Em Risco'
            -- Clientes antigos, pouco frequentes e de baixo valor
            WHEN r_score <= 2
            AND f_score = 1
            AND m_score <= 2
            THEN 'Inativos'
            ELSE 'Regulares'
        END AS segmento
    FROM scores
)
SELECT
    segmento,
    COUNT(*) AS clientes,
    ROUND(
        COUNT(*) * 100 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentual_clientes,
    ROUND(SUM(monetary), 2) AS valor_total,
    ROUND(AVG(monetary), 2) AS valor_medio_cliente
FROM segmentacao
GROUP BY segmento
ORDER BY valor_total DESC;

-- 11. BASE DETALHADA DE CLIENTES SEGMENTADOS

WITH base_clientes AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS ultima_compra,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(s.total_order_value) AS monetary
    FROM stg_olist_customers c
    INNER JOIN stg_olist_orders o
        ON o.customer_id = c.customer_id
    INNER JOIN vw_olist_order_sales s
        ON s.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
data_referencia AS (
    SELECT
        MAX(CAST(order_purchase_timestamp AS DATE)) + 1 AS data_ref
    FROM stg_olist_orders
    WHERE order_status = 'delivered'
),
rfm AS (
    SELECT
        b.customer_unique_id,
        TRUNC(
            d.data_ref - CAST(b.ultima_compra AS DATE)
        ) AS recency,
        b.frequency,
        b.monetary
    FROM base_clientes b
    CROSS JOIN data_referencia d
),
scores_base AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        6 - NTILE(5) OVER (
            ORDER BY recency ASC
        ) AS r_score,
        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS m_score
    FROM rfm
),
scores AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        ROUND(monetary, 2) AS monetary,
        r_score,
        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            WHEN frequency BETWEEN 4 AND 5 THEN 4
            WHEN frequency >= 6 THEN 5
        END AS f_score,
        m_score
    FROM scores_base
)
SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,

    CASE
        WHEN r_score >= 4
        AND f_score >= 2
        AND m_score >= 4
            THEN 'Campeões'
        WHEN f_score >= 2
        AND m_score >= 3
            THEN 'Fiéis'
        WHEN r_score = 5
        AND f_score = 1
            THEN 'Novos'
        WHEN f_score = 1
        AND m_score = 5
        AND r_score >= 3
            THEN 'Alto Valor'
        WHEN r_score <= 2
        AND (
                f_score >= 2
                OR m_score >= 4
            )
            THEN 'Em Risco'
        WHEN r_score <= 2
        AND f_score = 1
        AND m_score <= 2
            THEN 'Inativos'
        ELSE 'Regulares'
    END AS segmento
FROM scores;