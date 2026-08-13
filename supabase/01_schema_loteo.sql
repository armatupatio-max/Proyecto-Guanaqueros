-- =====================================================================
-- ESQUEMA: Loteo Guanaqueros — Flujo inmobiliario
-- Proyecto Supabase: NUEVO Y DEDICADO para este proyecto (plan Pro).
--   Las tablas mantienen el prefijo "loteo_" solo por claridad/
--   convención (no hay riesgo de colisión, es un proyecto propio).
-- =====================================================================
-- Cómo usar este archivo:
-- 1. Entra a https://supabase.com/dashboard → tu proyecto NUEVO
--    "Loteo Guanaqueros"
-- 2. Ve a "SQL Editor" → nueva consulta
-- 3. Pega TODO este archivo y presiona "Run"
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. TABLA: loteo_lotes (tipos de lote del flujo proyectado — Partida 1)
-- ---------------------------------------------------------------------
create table if not exists loteo_lotes (
  id              bigint generated always as identity primary key,
  nombre          text not null,
  unidades        integer not null default 0,
  m2              numeric not null default 0,
  ufm2            numeric not null default 0,
  orden           integer not null default 0,
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 2. TABLA: loteo_centros (centros de costo — Partida 2)
--    El árbol de subcentros/ítems es de profundidad variable (algunos
--    centros no tienen subcentros, otros tienen varios subcentros con
--    varios ítems cada uno) y se edita siempre como bloque completo
--    desde la interfaz, igual que el patrón usado en anexo2_* pero acá
--    se guarda como JSONB en vez de tablas hijas, porque nunca se
--    consulta un ítem individual por SQL — siempre se lee/escribe el
--    centro entero.
-- ---------------------------------------------------------------------
create table if not exists loteo_centros (
  id                bigint generated always as identity primary key,
  nombre            text not null,
  cls               text,
  tiene_subcentros  boolean not null default false,
  subcentros        jsonb not null default '[]'::jsonb,
  items             jsonb not null default '[]'::jsonb,
  orden             integer not null default 0,
  creado_en         timestamptz not null default now(),
  actualizado_en    timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 3. TABLA: loteo_registros_gastos (gastos reales — Centro de costos)
--    Los adjuntos van a Supabase Storage (bucket "loteo-documentos"),
--    acá solo se guarda su metadata (nombre + ruta en el bucket).
-- ---------------------------------------------------------------------
create table if not exists loteo_registros_gastos (
  id              bigint generated always as identity primary key,
  fecha           date,
  tipo_doc        text,
  centro          text,
  subcentro       text,
  desglose        text,
  monto           numeric not null default 0,
  forma_pago      text,
  nota            text,
  adjuntos        jsonb not null default '[]'::jsonb,
  creado_por      uuid references auth.users(id),
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 4. TABLAS: loteo_casas_comerciales + loteo_casas_ejecutivos
-- ---------------------------------------------------------------------
create table if not exists loteo_casas_comerciales (
  id              bigint generated always as identity primary key,
  nombre          text not null,
  rut             text,
  contacto        text,
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now()
);

create table if not exists loteo_casas_ejecutivos (
  id        bigint generated always as identity primary key,
  casa_id   bigint not null references loteo_casas_comerciales(id) on delete cascade,
  nombre    text not null,
  cargo     text,
  email     text,
  fono      text
);

-- ---------------------------------------------------------------------
-- 5. TABLAS: loteo_cotizaciones + loteo_cotizacion_items
-- ---------------------------------------------------------------------
create table if not exists loteo_cotizaciones (
  id              bigint generated always as identity primary key,
  titulo          text not null,
  fecha           date,
  validez         text,
  casa            text,
  ejecutivo       text,
  estado          text,
  nota            text,
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now()
);

create table if not exists loteo_cotizacion_items (
  id            bigint generated always as identity primary key,
  cotizacion_id bigint not null references loteo_cotizaciones(id) on delete cascade,
  desc_item     text,
  und           text,
  cantidad      numeric not null default 0,
  precio_unit   numeric not null default 0,
  centro_ref    text,
  sub_ref       text,
  orden         integer not null default 0
);

-- ---------------------------------------------------------------------
-- 6. TABLAS: loteo_ordenes_compra + loteo_orden_items
--    El archivo fuente (Excel/PDF/imagen) va a Storage; acá solo su
--    metadata.
-- ---------------------------------------------------------------------
create table if not exists loteo_ordenes_compra (
  id              bigint generated always as identity primary key,
  numero          text not null,
  fecha           date,
  casa            text,
  ejecutivo       text,
  estado          text,
  pago            text,
  entrega         text,
  lugar           text,
  nota            text,
  cot_ref         bigint references loteo_cotizaciones(id) on delete set null,
  archivo_nombre  text,
  archivo_tipo    text,
  archivo_path    text,
  creado_por      uuid references auth.users(id),
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now()
);

create table if not exists loteo_orden_items (
  id          bigint generated always as identity primary key,
  orden_id    bigint not null references loteo_ordenes_compra(id) on delete cascade,
  desc_item   text,
  und         text,
  cantidad    numeric not null default 0,
  precio_unit numeric not null default 0,
  orden       integer not null default 0
);

-- ---------------------------------------------------------------------
-- 7. Trigger genérico: actualiza "actualizado_en" en cada edición
--    (reutiliza set_actualizado_en() si ya existe de otro módulo;
--    si no existe, la crea)
-- ---------------------------------------------------------------------
create or replace function set_actualizado_en()
returns trigger as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_loteo_lotes_actualizado on loteo_lotes;
create trigger trg_loteo_lotes_actualizado before update on loteo_lotes
  for each row execute function set_actualizado_en();

drop trigger if exists trg_loteo_centros_actualizado on loteo_centros;
create trigger trg_loteo_centros_actualizado before update on loteo_centros
  for each row execute function set_actualizado_en();

drop trigger if exists trg_loteo_registros_actualizado on loteo_registros_gastos;
create trigger trg_loteo_registros_actualizado before update on loteo_registros_gastos
  for each row execute function set_actualizado_en();

drop trigger if exists trg_loteo_casas_actualizado on loteo_casas_comerciales;
create trigger trg_loteo_casas_actualizado before update on loteo_casas_comerciales
  for each row execute function set_actualizado_en();

drop trigger if exists trg_loteo_cotizaciones_actualizado on loteo_cotizaciones;
create trigger trg_loteo_cotizaciones_actualizado before update on loteo_cotizaciones
  for each row execute function set_actualizado_en();

drop trigger if exists trg_loteo_ordenes_actualizado on loteo_ordenes_compra;
create trigger trg_loteo_ordenes_actualizado before update on loteo_ordenes_compra
  for each row execute function set_actualizado_en();

-- ---------------------------------------------------------------------
-- 8. Seguridad: Row Level Security (RLS)
--    Misma política estándar del proyecto: cualquier usuario
--    autenticado puede leer/crear/editar/eliminar.
-- ---------------------------------------------------------------------
alter table loteo_lotes              enable row level security;
alter table loteo_centros            enable row level security;
alter table loteo_registros_gastos   enable row level security;
alter table loteo_casas_comerciales  enable row level security;
alter table loteo_casas_ejecutivos   enable row level security;
alter table loteo_cotizaciones       enable row level security;
alter table loteo_cotizacion_items   enable row level security;
alter table loteo_ordenes_compra     enable row level security;
alter table loteo_orden_items        enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array[
    'loteo_lotes','loteo_centros','loteo_registros_gastos',
    'loteo_casas_comerciales','loteo_casas_ejecutivos',
    'loteo_cotizaciones','loteo_cotizacion_items',
    'loteo_ordenes_compra','loteo_orden_items'
  ]
  loop
    if not exists (select 1 from pg_policies where tablename=t and policyname='Usuarios autenticados pueden ver '||t) then
      execute format('create policy "Usuarios autenticados pueden ver %1$s" on %1$s for select to authenticated using (true)', t);
      execute format('create policy "Usuarios autenticados pueden crear %1$s" on %1$s for insert to authenticated with check (true)', t);
      execute format('create policy "Usuarios autenticados pueden editar %1$s" on %1$s for update to authenticated using (true)', t);
      execute format('create policy "Usuarios autenticados pueden eliminar %1$s" on %1$s for delete to authenticated using (true)', t);
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 9. Habilitar tiempo real
-- ---------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array[
    'loteo_lotes','loteo_centros','loteo_registros_gastos',
    'loteo_casas_comerciales','loteo_casas_ejecutivos',
    'loteo_cotizaciones','loteo_cotizacion_items',
    'loteo_ordenes_compra','loteo_orden_items'
  ]
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname='supabase_realtime' and schemaname='public' and tablename=t
    ) then
      execute format('alter publication supabase_realtime add table %I', t);
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 10. Bucket de Storage para adjuntos (gastos y órdenes de compra)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('loteo-documentos', 'loteo-documentos', false)
on conflict (id) do nothing;

do $$
begin
  if not exists (select 1 from pg_policies where tablename='objects' and schemaname='storage' and policyname='Usuarios autenticados pueden ver adjuntos loteo') then
    create policy "Usuarios autenticados pueden ver adjuntos loteo"
      on storage.objects for select to authenticated
      using (bucket_id = 'loteo-documentos');
    create policy "Usuarios autenticados pueden subir adjuntos loteo"
      on storage.objects for insert to authenticated
      with check (bucket_id = 'loteo-documentos');
    create policy "Usuarios autenticados pueden eliminar adjuntos loteo"
      on storage.objects for delete to authenticated
      using (bucket_id = 'loteo-documentos');
  end if;
end $$;

-- =====================================================================
-- Fin del script. Después de correrlo, avísame para seguir con
-- 01b_migracion_lotes_centros.sql, que carga los 3 tipos de lote y
-- los 10 centros de costo que hoy están hardcodeados en el HTML.
-- =====================================================================
