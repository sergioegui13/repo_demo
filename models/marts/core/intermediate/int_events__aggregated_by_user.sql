-- ===========================================================================
-- int_events__aggregated_by_user.sql
-- ===========================================================================
-- CAPA: Intermediate
-- MATERIALIZACIÓN: view
--
-- OBJETIVO:
--   Agregar el número de eventos por tipo y por usuario.
--   Demuestra el uso de Jinja + macros para evitar SQL repetitivo.
--
-- USO DEL MACRO `obtener_valores`:
--   En lugar de hardcodear los tipos de evento, los obtenemos dinámicamente
--   con un macro que ejecuta una query SELECT DISTINCT en compile-time.
--   Si en el futuro aparece un nuevo event_type, este modelo lo recoge sin
--   tocar el código.
-- ===========================================================================

-- Obtenemos los tipos de evento dinámicamente con el macro.
-- Esto se ejecuta en COMPILE-TIME y devuelve una lista Python.
{% set event_types = obtener_valores(ref('stg_sql_server_dbo__events'), 'event_type') %}

with stg_events as (

    select * from {{ ref('stg_sql_server_dbo__events') }}

),

aggregated as (

    select
          user_id
        , session_id

        -- Generamos dinámicamente una columna por cada tipo de evento.
        -- El loop de Jinja se "desenrolla" en compile-time:
        --   sum(case when event_type = 'page_view'    then 1 else 0 end) as page_view_count,
        --   sum(case when event_type = 'add_to_cart'  then 1 else 0 end) as add_to_cart_count,
        --   ...
        {%- for event_type in event_types %}
        , sum(case when event_type = '{{ event_type }}' then 1 else 0 end) as {{ event_type }}_count
        {%- endfor %}

        , min(created_at_utc) as session_start_at_utc
        , max(created_at_utc) as session_end_at_utc
        , datediff('second', min(created_at_utc), max(created_at_utc)) as session_duration_seconds

    from stg_events
    group by user_id, session_id

)

select * from aggregated
