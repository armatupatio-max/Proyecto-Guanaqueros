-- =====================================================================
-- SENSIBILIDAD por etapa
-- =====================================================================
-- Multiplicadores que se aplican al calcular (no modifican lo ingresado):
--   sens_ingresos -> sobre el UF/m² de Partida 1
--   sens_costos   -> sobre el Unitario de los centros de costo (Partida 2)
-- 1 = sin cambio, 0.7 = 70%, 1.2 = +20%.
-- =====================================================================

alter table loteo_etapas add column if not exists sens_ingresos numeric not null default 1 check (sens_ingresos > 0);
alter table loteo_etapas add column if not exists sens_costos   numeric not null default 1 check (sens_costos > 0);
