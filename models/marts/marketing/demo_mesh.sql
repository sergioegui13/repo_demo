select *, 1 as demo
from {{ ref('demo_dbt_platform','dim_customer') }}