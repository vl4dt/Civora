# Auditoria basica

Civora mantiene un registro inalterable de acciones criticas por proyecto. Cada
evento identifica proyecto, actor, fecha, accion, tipo e identificador de la
entidad afectada. Tambien puede conservar motivo y estados anterior/posterior.

## Inmutabilidad

La aplicacion solo expone operaciones para agregar y consultar eventos. Ademas,
PostgreSQL usa el trigger `audit_events_immutable` para rechazar cualquier
`UPDATE` o `DELETE` sobre `audit_events`.

Los eventos conservan referencias restrictivas al proyecto y al actor. Un
proyecto o usuario con historial no puede eliminarse destruyendo su auditoria.

## Acciones actuales

- Creacion de proyecto.
- Creacion de fase del proyecto.
- Creacion de partida de obra.
- Creacion de subcontrato y sus partidas vinculadas.
- Creacion de actividad de obra.
- Registro de avance ejecutado.
- Aceptacion o rechazo de calidad.
- Asignacion de usuario al proyecto.
- Cambio de rol por proyecto.
- Retiro de una asignacion.

Estas acciones y su evento se escriben dentro de la misma transaccion.

## Contratos para milestones posteriores

La taxonomia reserva las acciones `budget_approved` y `estimate_created`.
Los contextos de presupuesto y estimacion deben
insertar esos eventos mediante `Civora.Audit.event_changeset/3` dentro de la
misma transaccion que aprueba o genera el registro de negocio. Calidad usa
`quality_accepted` y `quality_rejected` para controles registrados en RS-28.

## Consulta

Todo miembro asignado a un proyecto puede consultar `/projects/:id/audit`.
Usuarios sin asignacion reciben la misma respuesta de no encontrado usada por
el resto de las rutas privadas del proyecto.
