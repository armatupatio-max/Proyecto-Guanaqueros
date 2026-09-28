-- =====================================================================
-- ESQUEMA: Anteproyecto — columnas tipo Kanban para el nivel raíz
-- =====================================================================
-- Columnas nombradas por el usuario (ej. "Planos", "Permisos"). Las
-- carpetas de nivel raíz se organizan dentro de una columna, con
-- posición (orden) para poder reordenarlas o moverlas a otra columna.
-- Las subcarpetas (dentro de una carpeta) NO usan columna — siguen
-- viéndose como explorador simple.
-- =====================================================================

create table if not exists loteo_anteproyecto_columnas (
  id              bigint generated always as identity primary key,
  nombre          text not null,
  orden           integer not null default 0,
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now()
);

alter table loteo_anteproyecto_carpetas add column if not exists columna_id bigint references loteo_anteproyecto_columnas(id) on delete set null;
alter table loteo_anteproyecto_carpetas add column if not exists orden integer not null default 0;

drop trigger if exists trg_ap_columnas_actualizado on loteo_anteproyecto_columnas;
create trigger trg_ap_columnas_actualizado before update on loteo_anteproyecto_columnas
  for each row execute function set_actualizado_en();

alter table loteo_anteproyecto_columnas enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where tablename='loteo_anteproyecto_columnas' and policyname='Usuarios autenticados pueden ver loteo_anteproyecto_columnas') then
    create policy "Usuarios autenticados pueden ver loteo_anteproyecto_columnas" on loteo_anteproyecto_columnas for select to authenticated using (true);
    create policy "Usuarios autenticados pueden crear loteo_anteproyecto_columnas" on loteo_anteproyecto_columnas for insert to authenticated with check (true);
    create policy "Usuarios autenticados pueden editar loteo_anteproyecto_columnas" on loteo_anteproyecto_columnas for update to authenticated using (true);
    create policy "Usuarios autenticados pueden eliminar loteo_anteproyecto_columnas" on loteo_anteproyecto_columnas for delete to authenticated using (true);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='loteo_anteproyecto_columnas'
  ) then
    alter publication supabase_realtime add table loteo_anteproyecto_columnas;
  end if;
end $$;

-- =====================================================================
-- Fin del script.
-- =====================================================================
