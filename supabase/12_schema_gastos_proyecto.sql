-- =====================================================================
-- ESQUEMA: Gastos de Proyecto (prorrateados entre etapas)
-- =====================================================================
-- Reemplaza el sistema anterior de "gasto general" simple. Un gasto de
-- proyecto (ej. Arquitectura, Ingeniería) se ingresa UNA vez con un
-- monto total y una forma de prorrateo, y se reparte automáticamente
-- entre las etapas:
--   'm2'    -> proporcional a los m² útiles proyectados de cada etapa
--              (loteo_etapas.m2_utiles_proyectados, editable a mano)
--   'parejo'-> dividido en partes iguales entre todas las etapas
--   'etapa' -> 100% asignado a una etapa específica
-- =====================================================================

alter table loteo_etapas add column if not exists m2_utiles_proyectados numeric not null default 0;

create table if not exists loteo_gastos_proyecto (
  id                    bigint generated always as identity primary key,
  nombre                text not null,
  monto                 numeric not null default 0,
  tipo_prorrateo        text not null default 'parejo' check (tipo_prorrateo in ('m2','parejo','etapa')),
  etapa_especifica_id   bigint references loteo_etapas(id) on delete set null,
  orden                 integer not null default 0,
  creado_en             timestamptz not null default now(),
  actualizado_en        timestamptz not null default now()
);

drop trigger if exists trg_gastos_proyecto_actualizado on loteo_gastos_proyecto;
create trigger trg_gastos_proyecto_actualizado before update on loteo_gastos_proyecto
  for each row execute function set_actualizado_en();

alter table loteo_gastos_proyecto enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where tablename='loteo_gastos_proyecto' and policyname='Usuarios autenticados pueden ver loteo_gastos_proyecto') then
    create policy "Usuarios autenticados pueden ver loteo_gastos_proyecto" on loteo_gastos_proyecto for select to authenticated using (true);
    create policy "Usuarios autenticados pueden crear loteo_gastos_proyecto" on loteo_gastos_proyecto for insert to authenticated with check (true);
    create policy "Usuarios autenticados pueden editar loteo_gastos_proyecto" on loteo_gastos_proyecto for update to authenticated using (true);
    create policy "Usuarios autenticados pueden eliminar loteo_gastos_proyecto" on loteo_gastos_proyecto for delete to authenticated using (true);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='loteo_gastos_proyecto'
  ) then
    alter publication supabase_realtime add table loteo_gastos_proyecto;
  end if;
end $$;

-- =====================================================================
-- MIGRACIÓN: convertir el gasto general "Proyectos" (Arquitectura,
-- Ingeniería, etc.) en gastos de proyecto asignados 100% a Etapa 1.
-- Funciona tanto si "Proyectos" tiene sub-costos como si tiene ítems
-- planos. Es seguro correrlo una sola vez.
-- =====================================================================
do $$
declare
  etapa1_id bigint;
  proyectos_row loteo_centros%rowtype;
  sc jsonb;
  item jsonb;
  monto numeric;
begin
  select id into etapa1_id from loteo_etapas where nombre = 'Etapa 1' order by orden limit 1;
  if etapa1_id is null then
    raise notice 'No se encontró una etapa llamada "Etapa 1" — no se migró nada.';
    return;
  end if;

  select * into proyectos_row from loteo_centros where etapa_id is null and nombre = 'Proyectos' limit 1;
  if not found then
    raise notice 'No se encontró el gasto general "Proyectos" — no se migró nada.';
    return;
  end if;

  if proyectos_row.tiene_subcentros then
    for sc in select jsonb_array_elements(proyectos_row.subcentros)
    loop
      for item in select jsonb_array_elements(coalesce(sc->'items','[]'::jsonb))
      loop
        monto := coalesce((item->>'cantidad')::numeric,0) * coalesce((item->>'unitario')::numeric,0);
        insert into loteo_gastos_proyecto (nombre, monto, tipo_prorrateo, etapa_especifica_id)
        values (item->>'nombre', monto, 'etapa', etapa1_id);
      end loop;
    end loop;
  else
    for item in select jsonb_array_elements(coalesce(proyectos_row.items,'[]'::jsonb))
    loop
      monto := coalesce((item->>'cantidad')::numeric,0) * coalesce((item->>'unitario')::numeric,0);
      insert into loteo_gastos_proyecto (nombre, monto, tipo_prorrateo, etapa_especifica_id)
      values (item->>'nombre', monto, 'etapa', etapa1_id);
    end loop;
  end if;

  delete from loteo_centros where id = proyectos_row.id;

  raise notice 'Migrados los ítems de "Proyectos" a gastos de proyecto (asignados a Etapa 1).';
end $$;

-- =====================================================================
-- Fin del script.
-- =====================================================================
