-- ═══════════════════════════════════════════════════════════════
-- 20. Configuración compartida de la web (clave → valor JSON).
-- Primer uso: "apalancamiento_centros" = centros de Partida 2 que se
-- suman en el cuadro de apalancamiento bancario del Flujo de Proyecto.
-- Mismo acceso que el resto de las tablas loteo_* (ver 19_acceso_publico_sin_login.sql).
-- ═══════════════════════════════════════════════════════════════
create table if not exists public.loteo_config (
  clave          text primary key,
  valor          jsonb not null,
  actualizado_en timestamptz not null default now()
);

alter table public.loteo_config enable row level security;

do $$
declare r text;
begin
  foreach r in array array['anon','authenticated'] loop
    execute format('drop policy if exists "%1$s puede ver loteo_config" on public.loteo_config', r);
    execute format('drop policy if exists "%1$s puede crear loteo_config" on public.loteo_config', r);
    execute format('drop policy if exists "%1$s puede editar loteo_config" on public.loteo_config', r);
    execute format('drop policy if exists "%1$s puede eliminar loteo_config" on public.loteo_config', r);
    execute format('create policy "%1$s puede ver loteo_config" on public.loteo_config for select to %1$s using (true)', r);
    execute format('create policy "%1$s puede crear loteo_config" on public.loteo_config for insert to %1$s with check (true)', r);
    execute format('create policy "%1$s puede editar loteo_config" on public.loteo_config for update to %1$s using (true) with check (true)', r);
    execute format('create policy "%1$s puede eliminar loteo_config" on public.loteo_config for delete to %1$s using (true)', r);
    execute format('grant select, insert, update, delete on public.loteo_config to %I', r);
  end loop;
end $$;

-- Verificación: debe mostrar 8 políticas
select policyname from pg_policies where tablename = 'loteo_config' order by policyname;
