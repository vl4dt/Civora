# MVP Execution Rules

## Milestone Acceptance Criteria

### M0: Decision Tecnica

- Stack tecnico documentado y aceptado.
- Reglas de GitHub + Linear definidas.
- Ambientes previstos: local, staging y produccion.
- Proveedor de despliegue y storage definidos.

### M1: Base Operativa

- Login funcional.
- Usuarios internos creados.
- Roles MVP asignables por proyecto.
- Proyecto y fase del proyecto creados.
- Auditoria basica funcionando para acciones criticas.

### M2: Presupuesto y Partidas

- Partidas de obra creadas.
- Fichas de rendimiento creadas.
- Fichas presupuestadas generadas.
- Presupuesto aprobado como linea base.
- Presupuesto aprobado inalterable.

### M3: Subcontrato y Avance

- Contrapartes creadas.
- Subcontratos vinculados a partidas.
- Actividades de obra creadas.
- Avance ejecutado registrado por cantidad y ubicacion.

### M4: Calidad y Avance Pagable

- Control de calidad basico aplicado a avance ejecutado.
- Aceptacion parcial registrada.
- No conformidad simple registrada y cerrada.
- Avance pagable calculado desde avance aceptado.
- Avance rechazado no puede estimarse.

### M5: Estimacion y Costo

- Estimacion creada solo con avance pagable.
- Estimacion validada contra monto contractual vigente.
- Costo del proyecto actualizado.
- Reporte interno basico disponible.

### M6: Piloto Interno

- Dataset piloto cargado.
- Flujo completo ejecutado por RS Ingenieria.
- Product Owner valida funcionalmente el MVP.
- Ajustes posteriores quedan priorizados para V1.

## Definition of Ready

Un issue puede pasar a `Ready` solo si incluye:

- Resultado esperado.
- Actor o rol afectado.
- Criterios de aceptacion.
- Fuera de alcance.
- Referencias a PRD, CONTEXT o ADR.
- Datos de prueba cuando apliquen.
- Dependencias conocidas.

## Definition of Done

Un issue puede pasar a `Done` solo si:

- El codigo fue mergeado a `main`.
- Las migraciones aplicables fueron probadas en staging.
- Las pruebas relevantes pasan.
- El PR contiene evidencia de prueba.
- El cambio fue desplegado en staging.
- El Product Owner valido funcionalmente cuando afecta negocio.
- La documentacion fue actualizada si cambio dominio o decisiones.

## Linear Workflow

Estados:

- `Backlog`
- `Ready`
- `In Progress`
- `In Review`
- `Staging`
- `Done`
- `Blocked`

Labels:

- `mvp`
- `backend`
- `frontend`
- `domain`
- `database`
- `quality`
- `budget`
- `subcontracts`
- `costs`
- `evidence`
- `audit`
- `devops`
- `decision`
- `bug`
- `blocked`

## Pull Request Requirements

Todo PR debe incluir:

- Link al issue de Linear.
- Resumen de cambios.
- Como se probo.
- Capturas si toca UI.
- Notas de migracion si cambia base de datos.
- Riesgos o limites conocidos.

## Branch Naming

- Desarrollador humano: `dev/linear-id-descripcion-corta`
- Codex/agente: `codex/linear-id-descripcion-corta`

## Product Owner

El Product Owner valida funcionalmente cada entrega que afecte el flujo de negocio. La validacion tecnica del desarrollador no sustituye la validacion funcional.

## Milestone Demo

Cada milestone debe cerrarse con una demo en staging de 15 a 30 minutos. La demo debe mostrar el flujo entregado, explicar que se completo, declarar que quedo fuera, exponer riesgos o decisiones pendientes y terminar con aceptacion funcional del Product Owner o una lista de ajustes.

## Seguimiento Semanal

Durante el MVP se realizara una revision semanal de 30 minutos. Linear debe estar actualizado antes de cada revision. Cualquier bloqueo de mas de 24 horas debe marcarse como `Blocked` con comentario de causa, impacto y ayuda requerida. Las decisiones importantes deben registrarse como ADR o actualizar `CONTEXT.md` cuando cambien lenguaje de dominio.

## Control de Alcance

Todo cambio nuevo entra primero a `Backlog`. Solo puede incorporarse al MVP si ayuda directamente a responder que se presupuesto, que se contrato, que se ejecuto, que fue aceptado por calidad, y que se puede pagar y como afecta el costo del proyecto. Si es util pero no esencial, se etiqueta para V1. Si requiere portal externo, offline completo, inventario completo, facturacion al cliente o tablero de cartera, se pospone automaticamente fuera del MVP salvo decision explicita del Product Owner con impacto documentado.
