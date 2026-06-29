# Subcontratos

RS-25 modela el acuerdo operativo para ejecutar una o varias partidas de un proyecto.

## Invariantes

- Cada subcontrato pertenece a un proyecto y a una contraparte global habilitada como `subcontratista` o `ambos`.
- Un subcontrato agrupa una o varias partidas del mismo proyecto. Claves foraneas compuestas protegen esta frontera tambien en PostgreSQL.
- La modalidad de suministro es `solo_mano_obra`, `mano_obra_materiales` o `mixta`.
- El monto contractual vigente debe ser positivo. En RS-25 se inicializa al crear el acuerdo; cambios posteriores requeriran un flujo aprobado propio.
- Anticipo, retencion y amortizacion son porcentajes simples entre 0 y 100.
- La creacion del subcontrato, sus vinculos a partidas y el evento `subcontract_created` se guardan en una sola transaccion.
- RS-31 agrega estimaciones de subcontrato basadas en avance pagable no estimado previamente. Ver `docs/SUBCONTRACT_ESTIMATES.md`.

## Acceso

Todos los miembros asignados al proyecto pueden listar y consultar sus subcontratos. Solo administradores y directores de proyecto pueden crearlos.

RS-25 no implementa cambios al monto vigente, cierre contractual ni condiciones legales avanzadas.
