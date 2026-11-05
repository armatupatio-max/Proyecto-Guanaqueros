-- ═══════════════════════════════════════════════════════════════
-- 19b. Revierte 19: vuelve a exigir login para datos y adjuntos.
-- Después hay que restaurar la pantalla de login en index.html.
-- ═══════════════════════════════════════════════════════════════
do $$
declare t text;
begin
  for t in
    select tablename from pg_tables
    where schemaname = 'public' and tablename like 'loteo\_%'
  loop
    execute format('drop policy if exists "Publico puede ver %1$s" on public.%1$I', t);
    execute format('drop policy if exists "Publico puede crear %1$s" on public.%1$I', t);
    execute format('drop policy if exists "Publico puede editar %1$s" on public.%1$I', t);
    execute format('drop policy if exists "Publico puede eliminar %1$s" on public.%1$I', t);
  end loop;
end $$;

drop policy if exists "Publico puede ver adjuntos loteo" on storage.objects;
drop policy if exists "Publico puede subir adjuntos loteo" on storage.objects;
drop policy if exists "Publico puede eliminar adjuntos loteo" on storage.objects;
