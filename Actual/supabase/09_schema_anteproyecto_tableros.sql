-- =====================================================================
-- ESQUEMA: Anteproyecto — sub-apartados (tableros) + archivos en columna
-- =====================================================================
-- Un "tablero" es un sub-apartado dentro de Anteproyecto (el primero
-- se llama "General"), cada uno con su propio set de columnas. Además,
-- los archivos ahora pueden vivir directamente en una columna (no solo
-- dentro de una carpeta).
-- =====================================================================

create table if not exists loteo_anteproyecto_tableros (
  id              bigint generated always as identity primary key,
  nombre          text not null,
  orden           integer not null default 0,
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now()
);

alter table loteo_anteproyecto_columnas add column if not exists tablero_id bigint references loteo_anteproyecto_tableros(id) on delete cascade;
alter table loteo_anteproyecto_carpetas add column if not exists tablero_id bigint references loteo_anteproyecto_tableros(id) on delete cascade;
alter table loteo_anteproyecto_archivos add column if not exists tablero_id bigint references loteo_anteproyecto_tableros(id) on delete cascade;
alter table loteo_anteproyecto_archivos add column if not exists columna_id bigint references loteo_anteproyecto_columnas(id) on delete set null;

-- Backfill: crea el tablero "General" y le asigna todo lo que ya
-- existía (columnas y carpetas/archivos de nivel raíz).
do $$
declare
  general_id bigint;
begin
  if exists (select 1 from loteo_anteproyecto_columnas where tablero_id is null)
     or exists (select 1 from loteo_anteproyecto_carpetas where carpeta_padre_id is null and tablero_id is null)
     or exists (select 1 from loteo_anteproyecto_archivos where carpeta_id is null and tablero_id is null) then

    insert into loteo_anteproyecto_tableros (nombre, orden) values ('General', 0)
    returning id into general_id;

    update loteo_anteproyecto_columnas set tablero_id = general_id where tablero_id is null;
    update loteo_anteproyecto_carpetas set tablero_id = general_id where carpeta_padre_id is null and tablero_id is null;
    update loteo_anteproyecto_archivos set tablero_id = general_id where carpeta_id is null and tablero_id is null;
  end if;
end $$;

drop trigger if exists trg_ap_tableros_actualizado on loteo_anteproyecto_tableros;
create trigger trg_ap_tableros_actualizado before update on loteo_anteproyecto_tableros
  for each row execute function set_actualizado_en();

alter table loteo_anteproyecto_tableros enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where tablename='loteo_anteproyecto_tableros' and policyname='Usuarios autenticados pueden ver loteo_anteproyecto_tableros') then
    create policy "Usuarios autenticados pueden ver loteo_anteproyecto_tableros" on loteo_anteproyecto_tableros for select to authenticated using (true);
    create policy "Usuarios autenticados pueden crear loteo_anteproyecto_tableros" on loteo_anteproyecto_tableros for insert to authenticated with check (true);
    create policy "Usuarios autenticados pueden editar loteo_anteproyecto_tableros" on loteo_anteproyecto_tableros for update to authenticated using (true);
    create policy "Usuarios autenticados pueden eliminar loteo_anteproyecto_tableros" on loteo_anteproyecto_tableros for delete to authenticated using (true);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='loteo_anteproyecto_tableros'
  ) then
    alter publication supabase_realtime add table loteo_anteproyecto_tableros;
  end if;
end $$;

-- =====================================================================
-- Fin del script.
-- =====================================================================
