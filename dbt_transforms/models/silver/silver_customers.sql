with source_customers as (
    select * from (values
        ('CUST-44021', 'Acme Corp', 'Tier 2', 'Amsterdam', 'Netherlands', timestamp '2026-01-15 08:00:00'),
        ('CUST-44022', 'Global Logistics', 'Tier 1', 'Frankfurt', 'Germany', timestamp '2026-01-15 08:00:00'),
        ('CUST-44021', 'Acme Corp', 'Tier 1', 'Rotterdam', 'Netherlands', timestamp '2026-04-10 11:30:00')
    ) as raw(customer_id, customer_name, customer_tier, billing_city, billing_country, updated_at)
)
select
    customer_id,
    customer_name,
    customer_tier,
    billing_city,
    billing_country,
    updated_at
from source_customers
