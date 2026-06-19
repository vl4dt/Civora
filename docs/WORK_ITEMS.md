# Partidas de obra

RS-20 introduce la partida de obra como unidad economica y de calidad dentro de
un proyecto. Cada partida pertenece obligatoriamente a una fase del mismo
proyecto y conserva:

- descripcion;
- unidad de medida;
- cantidad con hasta cuatro decimales.

La base de datos aplica una llave foranea compuesta para impedir que una partida
apunte a una fase de otro proyecto. La cantidad debe ser mayor que cero.

Todos los miembros asignados al proyecto pueden listar y consultar sus partidas.
Los roles `administrador`, `director_proyecto` y `presupuesto` pueden crearlas.
Cada creacion agrega de forma atomica un evento `work_item_created` al registro
inalterable de auditoria del proyecto.
