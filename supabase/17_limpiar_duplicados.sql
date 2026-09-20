-- =====================================================================
-- LIMPIEZA: filas duplicadas en loteo_lotes y loteo_centros
-- =====================================================================
-- Dos guardados casi simultáneos de una misma etapa (cada uno borra y
-- reinserta todo) podían dejar filas repetidas. Este script elimina
-- SOLO copias exactas dentro de la misma etapa, quedándose con la más
-- antigua de cada grupo. No toca filas que difieran en algo.
-- =====================================================================

delete from loteo_lotes a
using loteo_lotes b
where a.etapa_id = b.etapa_id
  and a.nombre = b.nombre
  and a.unidades = b.unidades
  and a.m2 = b.m2
  and a.ufm2 = b.ufm2
  and a.id > b.id;

delete from loteo_centros a
using loteo_centros b
where a.etapa_id = b.etapa_id
  and a.nombre = b.nombre
  and a.tiene_subcentros = b.tiene_subcentros
  and a.subcentros = b.subcentros
  and a.items = b.items
  and a.id > b.id;

-- Diagnóstico: cómo está escrito cada centro en cada etapa (para ver
-- diferencias de tildes/espacios, p. ej. "Areas verdes" vs "Áreas verdes").
select e.nombre as etapa, '[' || c.nombre || ']' as centro
from loteo_centros c
join loteo_etapas e on e.id = c.etapa_id
where c.nombre <> 'Gastos de Proyecto'
order by lower(c.nombre), e.orden;
