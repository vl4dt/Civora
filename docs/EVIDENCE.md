# Evidencia basica

RS-34 permite adjuntar evidencia desde el detalle de una partida de obra a:

- Avance ejecutado.
- Control de calidad.
- No conformidad.

Los binarios se escriben mediante `Civora.Storage` y los metadatos quedan en
PostgreSQL en `evidence_attachments`. Cada registro conserva proyecto, partida,
registro vinculado, llave de objeto, nombre original, tipo de contenido, tamano,
estado, autor y fecha de carga.

## Estado

La evidencia inicia como `valid`. La aplicacion no expone eliminacion directa:
cuando una evidencia deja de ser valida se marca como `invalidated`, con motivo,
responsable y fecha. Esta regla aplica tambien cuando el registro vinculado ya
fue aprobado, cerrado o usado como respaldo operativo.

## Auditoria

Las cargas registran `evidence_uploaded`. Las invalidaciones registran
`evidence_invalidated` con estado anterior y posterior dentro de la misma
transaccion que cambia el estado de la evidencia.

## Almacenamiento

En produccion, `Civora.Storage` usa Cloudflare R2. Mientras las credenciales no
esten configuradas, la carga desde navegador devuelve un mensaje claro y no crea
metadatos huerfanos. En pruebas se usa un adaptador en memoria para cubrir el
flujo sin depender de R2.
