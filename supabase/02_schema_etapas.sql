-- =====================================================================
-- ESQUEMA: Etapas del proyecto (Loteo Guanaqueros)
-- =====================================================================
-- Agrega el concepto de "etapa" como una lista dinámica (se agregan/
-- quitan desde la interfaz, sin cantidad fija). Cada lote y cada
-- centro de costo pasan a pertenecer a una etapa.
--
-- Cómo usar este archivo:
-- 1. Entra a tu proyecto Supabase "Loteo Guanaqueros" → SQL Editor
-- 2. Pega TODO este archivo y presiona "Run"
-- 3. Es seguro correrlo aunque ya tengas datos: crea automáticamente
--    "Etapa 1" y le asigna todos los lotes/centros que ya existen,
--    para no perder nada de lo que guardaste en el paso anterior.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Asegura que exista la función del trigger (por si este script se
--    corre antes que 01_schema_loteo.sql, o si por algún motivo no
--    quedó creada)
-- ---------------------------------------------------------------------
create or replace function set_actualizado_en()
returns trigger as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$ language plpgsql;

-- ---------------------------------------------------------------------
-- 1. TABLA: loteo_etapas
-- ---------------------------------------------------------------------
create table if not exists loteo_etapas (
  id              bigint generated always as identity primary key,
  nombre          text not null,
  orden           integer not null default 0,
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now()
);

drop trigger if exists trg_loteo_etapas_actualizado on loteo_etapas;
create trigger trg_loteo_etapas_actualizado before update on loteo_etapas
  for each row execute function set_actualizado_en();

alter table loteo_etapas enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where tablename='loteo_etapas' and policyname='Usuarios autenticados pueden ver loteo_etapas') then
    create policy "Usuarios autenticados pueden ver loteo_etapas" on loteo_etapas for select to authenticated using (true);
    create policy "Usuarios autenticados pueden crear loteo_etapas" on loteo_etapas for insert to authenticated with check (true);
    create policy "Usuarios autenticados pueden editar loteo_etapas" on loteo_etapas for update to authenticated using (true);
    create policy "Usuarios autenticados pueden eliminar loteo_etapas" on loteo_etapas for delete to authenticated using (true);
  end if;
end $$;

alter publication supabase_realtime add table loteo_etapas;

-- ---------------------------------------------------------------------
-- 2. Agregar etapa_id a loteo_lotes y loteo_centros
-- ---------------------------------------------------------------------
alter table loteo_lotes   add column if not exists etapa_id bigint references loteo_etapas(id) on delete cascade;
alter table loteo_centros add column if not exists etapa_id bigint references loteo_etapas(id) on delete cascade;

-- ---------------------------------------------------------------------
-- 3. Backfill: si ya existen lotes/centros sin etapa (de antes de este
--    cambio), crear "Etapa 1" y asignárselos.
-- ---------------------------------------------------------------------
do $$
declare
  etapa1_id bigint;
begin
  if exists (select 1 from loteo_lotes where etapa_id is null)
     or exists (select 1 from loteo_centros where etapa_id is null) then

    insert into loteo_etapas (nombre, orden) values ('Etapa 1', 0)
    returning id into etapa1_id;

    update loteo_lotes   set etapa_id = etapa1_id where etapa_id is null;
    update loteo_centros set etapa_id = etapa1_id where etapa_id is null;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 4. A partir de ahora, etapa_id es obligatorio
-- ---------------------------------------------------------------------
alter table loteo_lotes   alter column etapa_id set not null;
alter table loteo_centros alter column etapa_id set not null;

-- =====================================================================
-- Fin del script.
-- =====================================================================
