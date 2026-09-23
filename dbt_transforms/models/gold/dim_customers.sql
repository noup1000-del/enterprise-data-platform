{{ config(
    materialized='view'
) }}

-- Consolidates SCD2 snapshot into an analyst-friendly Dimension table
-- Exposing deterministic surrogate keys and temporal validity bounds

with customer_snapshot as (
    select * from {{ ref('snap_customers') }}
)

select
    md5(
        cast(
            concat(
                coalesce(cast(customer_id as varchar), ''),
                '-',
                coalesce(cast(dbt_valid_from as varchar), '')
            ) as varchar
        )
    ) as customer_sk,
    customer_id,
    customer_name,
    customer_tier,
    billing_city,
    billing_country,
    dbt_valid_from as valid_from,
    dbt_valid_to as valid_to,
    case when dbt_valid_to is null then true else false end as is_current
from customer_snapshot
