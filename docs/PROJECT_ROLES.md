# Roles por proyecto

RS-17 introduce asignaciones internas por proyecto. Un usuario puede tener una
sola asignacion y un solo rol dentro de cada proyecto.

## Roles MVP

| Rol | Identificador |
| --- | --- |
| Administrador | `administrador` |
| Director de proyecto | `director_proyecto` |
| Presupuesto | `presupuesto` |
| Calidad | `calidad` |
| Finanzas | `finanzas` |
| Consulta | `consulta` |

Los roles no son globales. La misma persona puede tener roles diferentes en
proyectos distintos.

## Permisos iniciales

- Solo usuarios asignados pueden listar o consultar un proyecto.
- Todos los miembros del proyecto pueden consultar sus asignaciones.
- Solo el rol `administrador` puede agregar, cambiar o retirar asignaciones.
- Cada proyecto conserva al menos un administrador para evitar quedar sin
  gestion de acceso.

Los permisos funcionales de presupuesto, calidad y finanzas se agregaran en los
milestones correspondientes. RS-17 no concede acceso implicito fuera del
proyecto asignado.

## Integracion con proyectos

La tabla `projects` contiene nombre, cliente/referencia, estado y descripcion.
Cada proyecto puede tener fases opcionales de diseno, presupuesto,
planificacion, construccion, supervision y cierre.

Al crear un proyecto mediante `Civora.Projects.create_project/2`, el usuario del
scope se registra atomicamente como su primer administrador.
