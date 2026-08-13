-- =====================================================================
-- ESQUEMA: Registro de gastos — agregar etapa_id
-- =====================================================================
-- Los gastos reales también deben quedar acotados a una etapa (igual
-- que lotes y centros), para que la comparativa "proyectado vs. real"
-- compare cada etapa contra su propio presupuesto.
--
-- Cómo usar este archivo:
-- 1. Entra a tu proyecto Supabase "Loteo Guanaqueros" → SQL Editor
-- 2. Pega TODO este archivo y presiona "Run"
-- =====================================================================

alter table loteo_registros_gastos add column if not exists etapa_id bigint references loteo_etapas(id) on delete cascade;

-- Backfill por si ya hay registros de antes de este cambio (poco
-- probable en este proyecto, pero por seguridad los asigna a la
-- primera etapa existente).
do $$
declare
  primera_etapa_id bigint;
begin
  if exists (select 1 from loteo_registros_gastos where etapa_id is null) then
    select id into primera_etapa_id from loteo_etapas order by orden limit 1;
    if primera_etapa_id is not null then
      update loteo_registros_gastos set etapa_id = primera_etapa_id where etapa_id is null;
    end if;
  end if;
end $$;

alter table loteo_registros_gastos alter column etapa_id set not null;

-- =====================================================================
-- Fin del script.
-- =====================================================================
