-- =====================================================================
-- ESQUEMA: Cotizaciones — agregar etapa_id
-- =====================================================================
-- Las cotizaciones referencian centros/subcentros de costo, que ya
-- son por etapa, así que las cotizaciones también quedan acotadas a
-- una etapa. Las casas comerciales (proveedores) NO se acotan por
-- etapa — son un directorio general de contactos, se reutilizan
-- entre etapas.
--
-- Cómo usar este archivo:
-- 1. Entra a tu proyecto Supabase "Loteo Guanaqueros" → SQL Editor
-- 2. Pega TODO este archivo y presiona "Run"
-- =====================================================================

alter table loteo_cotizaciones add column if not exists etapa_id bigint references loteo_etapas(id) on delete cascade;

do $$
declare
  primera_etapa_id bigint;
begin
  if exists (select 1 from loteo_cotizaciones where etapa_id is null) then
    select id into primera_etapa_id from loteo_etapas order by orden limit 1;
    if primera_etapa_id is not null then
      update loteo_cotizaciones set etapa_id = primera_etapa_id where etapa_id is null;
    end if;
  end if;
end $$;

alter table loteo_cotizaciones alter column etapa_id set not null;

-- =====================================================================
-- Fin del script.
-- =====================================================================
