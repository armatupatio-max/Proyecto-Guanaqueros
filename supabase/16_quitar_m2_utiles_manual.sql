-- =====================================================================
-- QUITAR "Superficie útil proyectada por etapa" (m² manual)
-- =====================================================================
-- El prorrateo "por m² útil" ya no depende de una tabla editada a
-- mano — se calcula directo desde Partida 1 de cada etapa: superficie
-- útil de una etapa = suma de (unidades × m²) de sus lotes. La columna
-- ya no se usa en ningún lado del código.
-- =====================================================================

alter table loteo_etapas drop column if exists m2_utiles_proyectados;

-- =====================================================================
-- Fin del script.
-- =====================================================================
