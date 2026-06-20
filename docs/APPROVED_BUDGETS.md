# Presupuestos aprobados

RS-23 introduce el presupuesto del proyecto como una copia historica de las
partidas y fichas presupuestadas existentes al momento de generarlo. La copia
incluye la fase, descripcion, unidad y cantidad de cada partida. Cuando una
partida tiene ficha presupuestada, tambien conserva sus datos y recursos con
sus cantidades.

El presupuesto inicia en estado `draft`. Los roles `administrador`,
`director_proyecto` y `presupuesto` pueden generarlo y aprobarlo. Todos los
miembros asignados al proyecto pueden consultarlo. La aprobacion cambia el
estado a `approved`, registra quien y cuando aprobo, y crea el evento de
auditoria `budget_approved` dentro de la misma transaccion.

La aprobacion es una transicion unica. Despues de ella, la aplicacion bloquea
la creacion de partidas y la creacion o ajuste de fichas presupuestadas del
proyecto. La base de datos tambien rechaza actualizaciones y eliminaciones del
presupuesto aprobado, sus partidas copiadas y sus recursos, de modo que la
linea base permanece inalterable aun fuera de la interfaz.

Las revisiones de presupuesto y ordenes de cambio permanecen fuera del alcance
de M2 y se modelaran como nuevas versiones trazables, sin modificar esta linea
base.
