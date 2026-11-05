-- ═══════════════════════════════════════════════════════════════
-- 19. Acceso sin login: abre las tablas loteo_* y los adjuntos al rol anon.
-- OJO: desde aquí cualquiera con la URL o la clave publicable puede ver,
-- crear, editar y borrar estos datos. Para volver atrás: 19b_revertir_acceso_publico.sql
-- ═══════════════════════════════════════════════════════════════
do $$
declare t text;
begin
  for t in
    select tablename from pg_tables
    where schemaname = 'public' and tablename like 'loteo\_%'
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "Publico puede ver %1$s" on public.%1$I', t);
    execute format('drop policy if exists "Publico puede crear %1$s" on public.%1$I', t);
    execute format('drop policy if exists "Publico puede editar %1$s" on public.%1$I', t);
    execute format('drop policy if exists "Publico puede eliminar %1$s" on public.%1$I', t);
    execute format('create policy "Publico puede ver %1$s" on public.%1$I for select to anon using (true)', t);
    execute format('create policy "Publico puede crear %1$s" on public.%1$I for insert to anon with check (true)', t);
    execute format('create policy "Publico puede editar %1$s" on public.%1$I for update to anon using (true) with check (true)', t);
    execute format('create policy "Publico puede eliminar %1$s" on public.%1$I for delete to anon using (true)', t);
    execute format('grant select, insert, update, delete on public.%I to anon', t);
  end loop;
end $$;

grant usage, select on all sequences in schema public to anon;

drop policy if exists "Publico puede ver adjuntos loteo" on storage.objects;
drop policy if exists "Publico puede subir adjuntos loteo" on storage.objects;
drop policy if exists "Publico puede eliminar adjuntos loteo" on storage.objects;
create policy "Publico puede ver adjuntos loteo" on storage.objects
  for select to anon using (bucket_id = 'loteo-documentos');
create policy "Publico puede subir adjuntos loteo" on storage.objects
  for insert to anon with check (bucket_id = 'loteo-documentos');
create policy "Publico puede eliminar adjuntos loteo" on storage.objects
  for delete to anon using (bucket_id = 'loteo-documentos');

-- Verificación: debe listar 4 políticas por cada tabla loteo_* y 3 de adjuntos
select tablename, count(*) as politicas_publicas
from pg_policies
where 'anon' = any(roles) and policyname like 'Publico puede%'
group by tablename order by tablename;
