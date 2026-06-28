# No conformidades simples

RS-29 modela la no conformidad como el registro formal de trabajo que incumple
criterios de calidad en una partida.

## Invariantes

- Cada no conformidad pertenece a un proyecto y una partida.
- Puede vincularse a un control de calidad y, por esa ruta, al avance ejecutado
  revisado.
- Tambien puede registrarse directamente sobre una partida cuando el defecto no
  nace de un control de calidad capturado en Civora.
- Debe conservar defecto, ubicacion, responsable, estado y cantidad afectada.
- Cuando nace de un control de calidad, la cantidad afectada se toma de la
  cantidad rechazada por calidad. Esa cantidad permanece no pagable mientras la
  no conformidad este abierta.
- Un control de calidad solo puede originar una no conformidad en RS-29.
- El cierre conserva notas de reinspeccion y fecha de cierre.
- La creacion y el cierre insertan eventos de auditoria dentro de la misma
  transaccion.

## Estados

- `open`: defecto pendiente de corregir, rehacer, disponer o reinspeccionar.
- `closed`: responsable tecnico cerro la no conformidad despues de documentar la
  reinspeccion.

## Acceso

Todos los miembros asignados al proyecto pueden consultar no conformidades.
Administradores, directores de proyecto y miembros con rol `calidad` pueden
registrarlas y cerrarlas.
