with source_orders as (
    select * from (values
        ('ORD-109283', 'CUST-44021', 'FULFILLED', 'EUR', 482.50, timestamp '2026-02-14 09:30:00'),
        ('ORD-109284', 'CUST-44021', 'FULFILLED', 'EUR', 1200.00, timestamp '2026-04-15 14:00:00')
    ) as raw(order_id, customer_id, order_status, currency, order_total, order_timestamp)
)
select
    order_id,
    customer_id,
    order_status,
    currency,
    order_total,
    order_timestamp
from source_orders
