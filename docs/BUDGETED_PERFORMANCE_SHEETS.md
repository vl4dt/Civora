# Fichas presupuestadas

RS-22 introduce la ficha presupuestada como copia historica y editable de una
ficha de rendimiento dentro de un proyecto. Cada partida admite una ficha
presupuestada y conserva la referencia a la plantilla de origen solo como
procedencia.

Al generar la copia se duplican nombre, descripcion, unidad, productividad,
desperdicio y todos los recursos con sus cantidades. No se consultan esos datos
desde la plantilla despues de la copia, por lo que cambios futuros en la
biblioteca reutilizable no alteran el presupuesto del proyecto.

Todos los miembros del proyecto pueden consultar la ficha presupuestada. Los
roles `administrador`, `director_proyecto` y `presupuesto` pueden generarla y
ajustar sus datos mientras el presupuesto permanece editable. Una vez aprobado
el presupuesto del proyecto, la ficha queda disponible solo para consulta y la
linea base conserva su propia copia inalterable.

La base de datos garantiza que la partida y la ficha presupuestada pertenezcan
al mismo proyecto y que exista como maximo una ficha por partida.
