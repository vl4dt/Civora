# Costo del proyecto MVP

RS-33 agrega una vista basica de costo del proyecto basada en subcontratos y estimaciones.

## Invariantes

- El presupuesto aprobado se muestra como referencia de linea base; en el MVP actual conserva partidas y recursos, no un monto monetario total.
- El monto contratado es la suma del monto contractual vigente de los subcontratos del proyecto.
- El pagable acumulado valora las cantidades aceptadas por calidad para las partidas vinculadas a cada subcontrato, usando el mismo precio unitario congelable introducido en RS-31.
- El estimado acumulado es la suma de estimaciones generadas.
- El saldo basico es monto contratado menos estimado acumulado.

## Acceso

Todos los miembros asignados al proyecto pueden consultar la vista de costo. RS-33 no agrega aprobaciones financieras ni cierres mensuales.

RS-35 reutiliza estos totales dentro del reporte interno basico del MVP. Ver `docs/INTERNAL_REPORT.md`.
