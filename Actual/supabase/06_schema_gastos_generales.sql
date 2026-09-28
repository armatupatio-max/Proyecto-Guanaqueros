-- =====================================================================
-- ESQUEMA: Gastos generales del proyecto
-- =====================================================================
-- Un gasto puede quedar atado a una etapa específica (como hasta
-- ahora) O ser un gasto general del proyecto completo (financiamiento,
-- legal, administración) que no pertenece a ninguna etapa. Para eso,
-- etapa_id deja de ser obligatorio: NULL = gasto general.
-- =====================================================================

alter table loteo_registros_gastos alter column etapa_id drop not null;

-- =====================================================================
-- Fin del script.
-- =====================================================================
