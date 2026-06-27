# Avance ejecutado

RS-27 modela el avance ejecutado como la cantidad fisica reportada para una
actividad de obra.

## Invariantes

- Cada registro pertenece a un proyecto, una partida y una actividad de esa
  misma partida.
- La cantidad ejecutada debe ser mayor que cero.
- El registro conserva la ubicacion o sector reportado al momento de captura.
- Todo avance ejecutado se crea con `payable = false`. Convertirlo en avance
  pagable requiere un flujo posterior de calidad.
- La base de datos usa llaves foraneas compuestas para impedir que el avance
  apunte a una actividad o partida de otro proyecto.
- La creacion del avance y su evento `executed_progress_created` se guardan en
  una sola transaccion.

## Acceso

Todos los miembros asignados al proyecto pueden listar y consultar el avance
ejecutado. Solo administradores y directores de proyecto pueden registrarlo en
RS-27.

RS-27 no implementa aceptacion de calidad, avance pagable, estimaciones ni pago
de subcontrato.
