# Fichas de rendimiento

RS-21 introduce una biblioteca global de fichas de rendimiento reutilizables.
Una ficha no pertenece a un proyecto y puede convertirse posteriormente en una
ficha presupuestada historica para una partida.

Cada ficha conserva nombre, descripcion, unidad producida y uno o mas recursos.
Cada recurso identifica si es material o mano de obra, su unidad y la cantidad
normalmente requerida para producir una unidad de obra. La productividad diaria
y el porcentaje de desperdicio son opcionales cuando no aplican.

Las cantidades y la productividad deben ser mayores que cero. El desperdicio
debe estar entre 0% y 100%.

Todos los usuarios internos pueden consultar la biblioteca. Los usuarios con
una asignacion `administrador`, `director_proyecto` o `presupuesto` en al menos
un proyecto pueden crear fichas reutilizables. La copia historica y su
asociacion con una partida corresponden a RS-22.
