-- ===========================================================================
-- fct_user_sessions.sql
-- ===========================================================================
-- CAPA: Marts/Product (Gold)
-- MATERIALIZACIÓN: table
--
-- OBJETIVO (Ejercicio 19.1 — Caso de uso del equipo de Producto):
--   El equipo de producto necesita conocer para cada sesión:
--     - Información del usuario que la realizó
--     - Inicio y fin de la sesión
--     - Duración total
--     - Número de páginas vistas
--     - Número de eventos add_to_cart, checkout y package_shipped
--
-- ESTRATEGIA:
--   Reutilizamos el modelo intermedio `int_events__aggregated_by_user` que
--   ya tiene los conteos por sesión. Lo cruzamos con dim_users para añadir
--   los atributos del usuario.
-- ===========================================================================

with sessions_aggregated as (

    select * from {{ ref('int_events__aggregated_by_user') }}

),

users as (

    select * from {{ ref('dim_users') }}

),

final as (

    select
          -- Surrogate key de sesión (user_id + session_id por seguridad)
          {{ dbt_utils.generate_surrogate_key(['s.user_id', 's.session_id']) }}
              as user_session_id

        -- IDs y referencias
        , s.session_id
        , s.user_id

        -- Atributos del usuario (denormalizado para queries directas en BI)
        , u.full_name                                  as user_full_name
        , u.email                                      as user_email
        , u.is_valid_email_address
        , u.country                                    as user_country
        , u.state                                      as user_state

        -- Métricas temporales de la sesión
        , s.session_start_at_utc
        , s.session_end_at_utc
        , s.session_duration_seconds
        , round(s.session_duration_seconds / 60.0, 2)  as session_duration_minutes

        -- Métricas de eventos por sesión
        , s.page_view_count
        , s.add_to_cart_count
        , s.checkout_count
        , s.package_shipped_count

        -- Métrica derivada: ¿la sesión convirtió en compra?
        , case when s.checkout_count > 0 then true else false end
              as did_session_convert

    from sessions_aggregated s
    inner join users u on s.user_id = u.user_id

)

select * from final
