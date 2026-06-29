# Estimaciones de subcontrato

RS-31 crea el primer flujo de estimacion de subcontrato a partir de avance pagable.

## Invariantes

- Una estimacion pertenece a un proyecto y a un subcontrato del mismo proyecto.
- Solo se pueden seleccionar controles de calidad con cantidad aceptada mayor que cero.
- Cada control de calidad puede incluirse en una sola linea de estimacion.
- Las lineas deben corresponder a partidas vinculadas al subcontrato.
- La cantidad estimada viene de la cantidad aceptada por calidad.
- El precio unitario y el monto de cada linea quedan congelados al generar la estimacion.
- La estimacion se crea con estado `generated`.
- La estimacion, sus lineas y el evento `estimate_created` se guardan en una sola transaccion.

## Calculo inicial

RS-31 no cambia el modelo de subcontrato de RS-25, que aun no tiene precios por partida. Para esta primera version, el precio unitario usado por la estimacion se deriva del monto contractual vigente dividido entre la suma de cantidades contratadas en las partidas del subcontrato. Las siguientes iteraciones podran reemplazar este calculo con precios de linea, ordenes de cambio, anticipos, amortizaciones, retenciones y pagos anteriores.

## Acceso

Todos los miembros asignados al proyecto pueden consultar estimaciones y cantidades pagables pendientes. Solo administradores, directores de proyecto y finanzas pueden generar estimaciones.
