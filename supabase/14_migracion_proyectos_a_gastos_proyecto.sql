-- =====================================================================
-- MIGRACIÓN: mover "Proyectos" (Arquitectura, Ingeniería) a Gastos de
-- Proyecto, preservando el desglose completo
-- =====================================================================
-- Las migraciones anteriores (11 y 12) no llegaron a mover realmente
-- el centro "Proyectos" — sigue existiendo como un centro de costo
-- normal, y "loteo_gastos_proyecto" está vacío. Este script sí lo
-- mueve: cada sub-costo de "Proyectos" (ej. Arquitectura, Ingeniería)
-- pasa a ser su propio gasto de proyecto, con sus ítems (cantidad,
-- unidad, valor unitario) copiados tal cual — sin resumir a un solo
-- número — y prorrateado 100% a Etapa 1 (se puede cambiar después
-- desde Flujo de Proyecto).
--
-- Nota: los gastos ya registrados en "Registro de gastos" contra el
-- centro "Proyectos" (costo real) NO se tocan — van a seguir
-- apareciendo bajo el nombre "Proyectos" en el resumen por centro de
-- costo, solo que ese centro ya no tendrá una línea de presupuesto
-- propia en Partida 2 (el presupuesto se mueve a Gastos de Proyecto).
--
-- Seguro de correr una sola vez: si no encuentra un centro "Proyectos"
-- no hace nada.
-- =====================================================================

do $$
declare
  etapa1_id bigint;
  proyectos_row loteo_centros%rowtype;
  sc jsonb;
  gasto_items jsonb;
  gasto_monto numeric;
begin
  select id into etapa1_id from loteo_etapas where nombre = 'Etapa 1' order by orden limit 1;
  if etapa1_id is null then
    raise notice 'No se encontró una etapa llamada "Etapa 1" — no se migró nada.';
    return;
  end if;

  select * into proyectos_row from loteo_centros where nombre = 'Proyectos' limit 1;
  if not found then
    raise notice 'No se encontró un centro de costo "Proyectos" — no se migró nada.';
    return;
  end if;

  if proyectos_row.tiene_subcentros then
    for sc in select jsonb_array_elements(proyectos_row.subcentros)
    loop
      gasto_items := coalesce(sc->'items', '[]'::jsonb);
      select coalesce(sum(coalesce((item->>'cantidad')::numeric,0) * coalesce((item->>'unitario')::numeric,0)),0)
        into gasto_monto
        from jsonb_array_elements(gasto_items) as item;
      insert into loteo_gastos_proyecto (nombre, monto, tipo_prorrateo, etapa_especifica_id, tiene_subcentros, subcentros, items)
      values (sc->>'nombre', gasto_monto, 'etapa', etapa1_id, false, '[]'::jsonb, gasto_items);
    end loop;
  else
    for sc in select jsonb_array_elements(coalesce(proyectos_row.items,'[]'::jsonb))
    loop
      gasto_monto := coalesce((sc->>'cantidad')::numeric,0) * coalesce((sc->>'unitario')::numeric,0);
      insert into loteo_gastos_proyecto (nombre, monto, tipo_prorrateo, etapa_especifica_id, tiene_subcentros, subcentros, items)
      values (sc->>'nombre', gasto_monto, 'etapa', etapa1_id, false, '[]'::jsonb, jsonb_build_array(sc));
    end loop;
  end if;

  delete from loteo_centros where id = proyectos_row.id;

  raise notice 'Migrados los sub-costos de "Proyectos" a gastos de proyecto (asignados a Etapa 1), con su desglose completo.';
end $$;

-- =====================================================================
-- Fin del script.
-- =====================================================================
