-- =====================================================================
-- ESQUEMA: Órdenes de compra — agregar etapa_id
-- =====================================================================
alter table loteo_ordenes_compra add column if not exists etapa_id bigint references loteo_etapas(id) on delete cascade;

do $$
declare
  primera_etapa_id bigint;
begin
  if exists (select 1 from loteo_ordenes_compra where etapa_id is null) then
    select id into primera_etapa_id from loteo_etapas order by orden limit 1;
    if primera_etapa_id is not null then
      update loteo_ordenes_compra set etapa_id = primera_etapa_id where etapa_id is null;
    end if;
  end if;
end $$;

alter table loteo_ordenes_compra alter column etapa_id set not null;

-- =====================================================================
-- Fin del script.
-- =====================================================================
