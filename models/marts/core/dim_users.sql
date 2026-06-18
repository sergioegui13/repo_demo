-- ===========================================================================
-- dim_users.sql
-- ===========================================================================
-- CAPA: Marts/Core (Gold)
-- MATERIALIZACIÓN: table (heredada — Gold siempre table o incremental, nunca view)
--
-- OBJETIVO:
--   Dimensión de usuarios. "La fuente de verdad" sobre los usuarios para
--   toda la organización.
--
-- ENRIQUECIMIENTOS:
--   - Validación de formato de email con regex (ejemplo de transformación
--     de negocio en la capa core).
--   - Cálculo de días desde el alta del usuario.
-- ===========================================================================

with users as (

    select * from {{ ref('stg_sql_server_dbo__users') }}

),

addresses as (

    select * from {{ ref('stg_sql_server_dbo__addresses') }}

),

final as (

    select
          u.user_id
        , u.first_name
        , u.last_name
        , concat(u.first_name, ' ', u.last_name)             as full_name
        , u.email

        -- Validación de formato de email. Esta columna se valida
        -- con un unit_test en _core__models.yml.
        , coalesce(
              regexp_like(u.email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
              false
          )                                                  as is_valid_email_address

        , u.phone_number
        , u.address_id
        , a.address_line
        , a.zipcode::varchar(20) as zipcode_02
        , a.state
        , a.country
        , u.created_at_utc                                   as registered_at_utc
        , u.updated_at_utc                                   as last_updated_at_utc
        , datediff('day', u.created_at_utc, current_timestamp()) as days_since_registration
        , u.date_load
        , 1 as demo_error
    from users u
    left join addresses a on u.address_id = a.address_id

)

select *, 1 as demo_error from final
