-- =====================================================================
-- MIGRACIÓN: Mover el centro "Proyectos" de Etapa 1 a Gasto General
-- =====================================================================
-- Traslada el centro de costo "Proyectos" (con todo su desglose:
-- sub-costos e ítems, incluyendo Arquitectura e Ingeniería) desde
-- Etapa 1 hacia los gastos generales del proyecto (etapa_id null),
-- preservando exactamente los valores ya cargados. No duplica: borra
-- el original de Etapa 1 después de copiarlo.
--
-- Es seguro correrlo una sola vez — si ya no existe "Proyectos" en
-- Etapa 1 (por ejemplo si ya se corrió antes), no hace nada.
-- =====================================================================

do $$
declare
  etapa1_id bigint;
  centro_row loteo_centros%rowtype;
begin
  select id into etapa1_id from loteo_etapas where nombre = 'Etapa 1' order by orden limit 1;
  if etapa1_id is null then
    raise notice 'No se encontró una etapa llamada "Etapa 1" — no se hizo ningún cambio.';
    return;
  end if;

  select * into centro_row from loteo_centros where etapa_id = etapa1_id and nombre = 'Proyectos' limit 1;
  if not found then
    raise notice 'No se encontró el centro "Proyectos" en Etapa 1 — no se hizo ningún cambio.';
    return;
  end if;

  insert into loteo_centros (nombre, cls, tiene_subcentros, subcentros, items, etapa_id, orden)
  values (centro_row.nombre, centro_row.cls, centro_row.tiene_subcentros, centro_row.subcentros, centro_row.items, null, 0);

  delete from loteo_centros where id = centro_row.id;

  raise notice 'Centro "Proyectos" movido de Etapa 1 a Gasto General.';
end $$;

-- =====================================================================
-- Fin del script.
-- =====================================================================
