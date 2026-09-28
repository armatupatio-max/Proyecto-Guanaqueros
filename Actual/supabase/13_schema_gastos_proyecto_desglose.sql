-- =====================================================================
-- ESQUEMA: Desglose (sub-costos + ítems) para Gastos de Proyecto
-- =====================================================================
-- Hasta ahora un "gasto de proyecto" era un monto suelto. Desde ahora
-- se edita exactamente igual que un centro de costo de Partida 2: puede
-- tener sub-costos, y cada sub-costo tiene ítems con su propia
-- cantidad, unidad y valor unitario. El monto total ya no se ingresa
-- a mano — se calcula sumando los ítems (igual que loteo_centros).
--
-- Migración de datos: los gastos ya existentes (por ahora solo tienen
-- un "monto" suelto, sin desglose) se convierten en un gasto sin
-- sub-costos con UN solo ítem que reproduce ese mismo monto total
-- (cantidad 1, unitario = monto). El total en UF queda exactamente
-- igual — lo único que no se puede reconstruir es la cantidad/unidad/
-- valor unitario originales de cada ítem, porque una migración anterior
-- ya los había resumido a un solo número (monto). Desde la nueva
-- interfaz se puede agregar el desglose más fino a mano.
-- =====================================================================

alter table loteo_gastos_proyecto add column if not exists tiene_subcentros boolean not null default false;
alter table loteo_gastos_proyecto add column if not exists subcentros jsonb not null default '[]'::jsonb;
alter table loteo_gastos_proyecto add column if not exists items jsonb not null default '[]'::jsonb;

update loteo_gastos_proyecto
set tiene_subcentros = false,
    items = jsonb_build_array(jsonb_build_object('nombre', nombre, 'cantidad', 1, 'unitario', monto, 'und', 'UN'))
where items = '[]'::jsonb;

-- =====================================================================
-- Fin del script.
-- =====================================================================
