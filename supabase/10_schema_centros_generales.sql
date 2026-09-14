-- =====================================================================
-- ESQUEMA: Centros de costo generales del proyecto
-- =====================================================================
-- Un centro de costo (Partida 2) puede ahora ser general del proyecto
-- (no atado a ninguna etapa) — igual que ya es posible con los gastos
-- reales. NULL en etapa_id = gasto general (ej. Arquitectura,
-- Ingeniería). Se gestionan desde el Flujo Consolidado.
-- =====================================================================

alter table loteo_centros alter column etapa_id drop not null;

-- =====================================================================
-- Fin del script.
-- =====================================================================
