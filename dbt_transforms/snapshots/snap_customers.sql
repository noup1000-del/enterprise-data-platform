{% snapshot snap_customers %}
    {{
        config(
            target_schema='main',
            unique_key='customer_id',
            strategy='timestamp',
            updated_at='updated_at'
        )
    }}

    select
        customer_id,
        customer_name,
        customer_tier,
        billing_city,
        billing_country,
        updated_at
    from {{ ref('silver_customers') }}
{% endsnapshot %}
