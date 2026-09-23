{{ config(
    materialized='table'
) }}

-- Orders Fact Table joined to Customer Dimension via Point-in-Time Lookup
-- Guarantees that order metrics reflect the customer's state at order placement time

with orders as (
    select * from {{ ref('silver_orders') }}
),

dim_customers as (
    select * from {{ ref('dim_customers') }}
)

select
    o.order_id,
    c.customer_sk,
    o.customer_id,
    o.order_status,
    o.currency,
    o.order_total,
    o.order_timestamp,
    c.billing_city as attributed_billing_city,
    c.customer_tier as attributed_customer_tier
from orders o
left join dim_customers c
    on o.customer_id = c.customer_id
   and o.order_timestamp >= c.valid_from
   and (o.order_timestamp < c.valid_to or c.valid_to is null)
