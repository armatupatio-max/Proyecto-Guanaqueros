-- =====================================================================
-- ESQUEMA: Anteproyecto — explorador de carpetas y archivos
-- =====================================================================
-- Carpetas anidadas (auto-referencia carpeta_padre_id) + archivos.
-- Los archivos reutilizan el bucket "loteo-documentos" que ya existe
-- (carpeta "anteproyecto/" dentro del bucket), no hace falta uno nuevo.
-- Es global al proyecto (no está acotado por etapa): el anteproyecto
-- es documentación previa a las etapas de construcción.
-- =====================================================================

create or replace function set_actualizado_en()
returns trigger as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$ language plpgsql;

create table if not exists loteo_anteproyecto_carpetas (
  id                bigint generated always as identity primary key,
  nombre            text not null,
  carpeta_padre_id  bigint references loteo_anteproyecto_carpetas(id) on delete cascade,
  creado_en         timestamptz not null default now(),
  actualizado_en    timestamptz not null default now()
);

create table if not exists loteo_anteproyecto_archivos (
  id            bigint generated always as identity primary key,
  carpeta_id    bigint references loteo_anteproyecto_carpetas(id) on delete cascade,
  nombre        text not null,
  path          text not null,
  tipo          text,
  tamano_bytes  bigint,
  creado_por    uuid references auth.users(id),
  creado_en     timestamptz not null default now()
);

drop trigger if exists trg_ap_carpetas_actualizado on loteo_anteproyecto_carpetas;
create trigger trg_ap_carpetas_actualizado before update on loteo_anteproyecto_carpetas
  for each row execute function set_actualizado_en();

alter table loteo_anteproyecto_carpetas enable row level security;
alter table loteo_anteproyecto_archivos enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array['loteo_anteproyecto_carpetas','loteo_anteproyecto_archivos']
  loop
    if not exists (select 1 from pg_policies where tablename=t and policyname='Usuarios autenticados pueden ver '||t) then
      execute format('create policy "Usuarios autenticados pueden ver %1$s" on %1$s for select to authenticated using (true)', t);
      execute format('create policy "Usuarios autenticados pueden crear %1$s" on %1$s for insert to authenticated with check (true)', t);
      execute format('create policy "Usuarios autenticados pueden editar %1$s" on %1$s for update to authenticated using (true)', t);
      execute format('create policy "Usuarios autenticados pueden eliminar %1$s" on %1$s for delete to authenticated using (true)', t);
    end if;
  end loop;
end $$;

do $$
declare
  t text;
begin
  foreach t in array array['loteo_anteproyecto_carpetas','loteo_anteproyecto_archivos']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname='supabase_realtime' and schemaname='public' and tablename=t
    ) then
      execute format('alter publication supabase_realtime add table %I', t);
    end if;
  end loop;
end $$;

-- =====================================================================
-- Fin del script.
-- =====================================================================
