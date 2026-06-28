# Control de calidad basico

RS-28 modela el control de calidad como la revision tecnica de un registro de
avance ejecutado.

## Invariantes

- Cada control pertenece a un proyecto, una partida y un avance ejecutado de esa
  misma partida.
- Cada avance ejecutado admite un solo control de calidad en RS-28.
- La cantidad aceptada debe ser mayor o igual que cero y no puede superar la
  cantidad ejecutada.
- La cantidad rechazada se calcula como diferencia entre cantidad ejecutada y
  cantidad aceptada.
- Si existe cantidad rechazada, el control debe conservar el motivo tecnico.
- Un rechazo parcial o total puede marcarse como origen de una no conformidad.
  RS-28 guarda esa decision; RS-29 permite crear la no conformidad vinculada.
- La creacion del control, la marca `payable` del avance ejecutado y el evento
  de auditoria se guardan en una sola transaccion.

## Estados

- `accepted`: toda la cantidad ejecutada fue aceptada.
- `partially_accepted`: una parte queda aceptada y otra rechazada.
- `rejected`: no se acepto cantidad pagable.

Un avance ejecutado queda `payable = true` cuando su control acepta una cantidad
mayor que cero. La cantidad pagable exacta vive en el control de calidad.
Cuando existe una no conformidad abierta, la cantidad rechazada por ese control
permanece como cantidad afectada no pagable.

## Acceso

Todos los miembros asignados al proyecto pueden consultar los controles.
Administradores, directores de proyecto y miembros con rol `calidad` pueden
registrarlos.
