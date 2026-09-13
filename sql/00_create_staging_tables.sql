CREATE TABLE stg_olist_customers (
    customer_id VARCHAR2(50),
    customer_unique_id VARCHAR2(50),
    customer_zip_code_prefix NUMBER,
    customer_city VARCHAR2(100),
    customer_state VARCHAR2(2)
);

CREATE TABLE stg_olist_orders (
    order_id VARCHAR2(50),
    customer_id VARCHAR2(50),
    order_status VARCHAR2(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE stg_olist_order_items (
    order_id VARCHAR2(50),
    order_item_id NUMBER,
    product_id VARCHAR2(50),
    seller_id VARCHAR2(50),
    shipping_limit_date TIMESTAMP,
    price NUMBER(12,2),
    freight_value NUMBER(12,2)
);

CREATE TABLE stg_olist_products (
    product_id VARCHAR2(50),
    product_category_name VARCHAR2(100),
    product_name_lenght NUMBER,
    product_description_lenght NUMBER,
    product_photos_qty NUMBER,
    product_weight_g NUMBER,
    product_length_cm NUMBER,
    product_height_cm NUMBER,
    product_width_cm NUMBER
);

CREATE TABLE stg_olist_sellers (
    seller_id VARCHAR2(50),
    seller_zip_code_prefix NUMBER,
    seller_city VARCHAR2(100),
    seller_state VARCHAR2(2)
);

CREATE TABLE stg_olist_order_payments (
    order_id VARCHAR2(50),
    payment_sequential NUMBER,
    payment_type VARCHAR2(30),
    payment_installments NUMBER,
    payment_value NUMBER(12,2)
);

CREATE TABLE stg_olist_order_reviews (
    review_id VARCHAR2(50),
    order_id VARCHAR2(50),
    review_score NUMBER,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);