# Actividades de obra

RS-26 modela la actividad de obra como la unidad temporal y espacial usada para
programar la ejecucion de una parte de una partida.

## Invariantes

- Cada actividad pertenece a un proyecto y a una sola partida de obra.
- Una partida puede tener varias actividades.
- La actividad conserva ubicacion o sector y descripcion.
- La base de datos usa una llave foranea compuesta para impedir que una
  actividad apunte a una partida de otro proyecto.
- La creacion de la actividad y su evento `work_activity_created` se guardan en
  una sola transaccion.

## Acceso

Todos los miembros asignados al proyecto pueden listar y consultar las
actividades de sus partidas. Solo administradores y directores de proyecto
pueden crearlas.

RS-26 no registra avance ejecutado, avance pagable, dependencias entre
actividades ni asignaciones de recursos. Esos flujos pertenecen a milestones
posteriores.
