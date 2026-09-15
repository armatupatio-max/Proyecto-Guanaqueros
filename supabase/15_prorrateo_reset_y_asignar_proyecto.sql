-- =====================================================================
-- REINICIO DE PRORRATEO: nuevo tipo "proyecto" (sin prorratear)
-- =====================================================================
-- Se agrega un cuarto tipo de prorrateo, 'proyecto': el gasto queda
-- registrado solo en Flujo de Proyecto, sin asignarse a ninguna etapa.
-- Es el estado por defecto para un gasto nuevo, y también a donde cae
-- automáticamente un gasto "asignado a una etapa específica" si esa
-- etapa se elimina.
--
-- Se resetea el prorrateo de TODOS los gastos ya existentes (a pedido
-- del usuario, para volver a probar la lógica desde cero) — el nombre
-- y el desglose completo (sub-costos/ítems) de cada gasto NO se tocan,
-- solo se limpia su forma de prorrateo, dejándolos en "Asignar a
-- proyecto" hasta que se elija de nuevo cómo repartirlos.
-- =====================================================================

alter table loteo_gastos_proyecto drop constraint if exists loteo_gastos_proyecto_tipo_prorrateo_check;
alter table loteo_gastos_proyecto add constraint loteo_gastos_proyecto_tipo_prorrateo_check
  check (tipo_prorrateo in ('proyecto','m2','parejo','etapa'));

update loteo_gastos_proyecto
set tipo_prorrateo = 'proyecto',
    etapa_especifica_id = null;

alter table loteo_gastos_proyecto alter column tipo_prorrateo set default 'proyecto';

-- =====================================================================
-- Fin del script.
-- =====================================================================
