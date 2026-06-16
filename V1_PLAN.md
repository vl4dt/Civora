# Civora V1 Plan

## Objetivo

Construir la primera version de Civora como un sistema propietario para gestionar proyectos de arquitectura y construccion, empezando por el flujo que conecta ejecucion, calidad y dinero:

**Proyecto -> partida de obra -> ficha presupuestada -> control de calidad -> avance pagable -> estimacion de subcontrato -> costo del proyecto**

Este flujo sera el tracer bullet de V1. Debe atravesar modelo de dominio, interfaz, permisos, auditoria, reportes basicos y persistencia real antes de expandir el resto de modulos.

## Principios de Ejecucion

- GitHub es la fuente oficial para codigo, PRD, CONTEXT, ADRs y decisiones duraderas.
- Linear sera la herramienta de planificacion, ejecucion y seguimiento.
- Cada decision de dominio estable debe reflejarse en `CONTEXT.md`.
- Cada decision dificil de revertir debe registrarse como ADR.
- Cada issue de Linear debe entregar una porcion vertical comprobable.
- El producto debe evitar automatismos peligrosos: no pagar avance sin calidad, no reescribir presupuestos aprobados, no sobrescribir conflictos offline y no ocultar riesgos criticos por promedios.

## Stack Propuesto para Validar

- Backend: Elixir + Phoenix.
- Web interna: Phoenix LiveView.
- API: Phoenix JSON API para clientes offline y futuras integraciones.
- Base de datos: PostgreSQL con Ecto.
- Jobs: Oban.
- Realtime: Phoenix PubSub/Channels cuando aporte valor operativo.
- Evidencias y documentos: almacenamiento compatible con S3.
- Campo offline: PWA o app movil con almacenamiento local y sincronizacion explicita.
- Seguimiento: Linear + GitHub.

La seleccion definitiva del stack debe cerrarse con un ADR antes de iniciar implementacion fuerte.

## Fase 0: Preparacion del Trabajo

Resultado esperado: el equipo puede trabajar de forma ordenada, con repositorio, proyecto Linear y reglas basicas.

Entregables:

- Repositorio GitHub configurado.
- Linear workspace, initiative y proyectos creados.
- Convenciones de issues, ramas, commits y PRs.
- Plantillas de issue para feature, bug, decision y spike.
- ADR de stack tecnico.
- Plan de ambientes: desarrollo local, staging y produccion futura.

Criterios de salida:

- Todo trabajo nuevo puede trazarse desde Linear hasta GitHub.
- El equipo sabe donde viven decisiones, tareas y codigo.
- El stack tecnico inicial esta aceptado.

## Fase 1: Fundacion Tecnica

Resultado esperado: aplicacion base desplegable con autenticacion, roles iniciales, auditoria basica y estructura de dominio.

Entregables:

- Proyecto Phoenix inicial.
- Configuracion de PostgreSQL.
- Autenticacion inicial.
- Modelo base de usuarios, roles de trabajo y asignaciones de proyecto.
- Estructura inicial de contextos de dominio.
- Registro de auditoria para acciones relevantes.
- Pipeline basico de pruebas.
- Deploy inicial a staging.

Criterios de salida:

- Un usuario puede iniciar sesion.
- Un usuario puede pertenecer a un proyecto con rol especifico.
- Una accion relevante deja auditoria.
- La app puede desplegarse repetidamente.

## Fase 2: Tracer Bullet Operativo

Resultado esperado: primer flujo vertical completo desde proyecto hasta costo por estimacion.

Entregables:

- Crear proyecto y fase.
- Crear partida de obra.
- Crear ficha de rendimiento reutilizable.
- Crear ficha presupuestada dentro de un presupuesto.
- Aprobar presupuesto como linea base inicial.
- Crear subcontrato vinculado a una o varias partidas.
- Registrar actividad de obra vinculada a una partida.
- Registrar avance ejecutado.
- Ejecutar control de calidad basico.
- Convertir avance aceptado en avance pagable.
- Crear estimacion de subcontrato.
- Registrar impacto en costo del proyecto.

Criterios de salida:

- El sistema impide estimar avance no aceptado por calidad.
- El presupuesto aprobado queda inalterable.
- La estimacion no excede el monto contractual vigente.
- El costo del proyecto refleja el compromiso y la estimacion.
- El flujo tiene pruebas automatizadas de punta a punta.

## Fase 3: Calidad y No Conformidades

Resultado esperado: el control de calidad deja de ser una casilla simple y se convierte en un flujo formal.

Entregables:

- Plantillas de control de calidad.
- Controles versionados por proyecto.
- Aceptacion parcial por cantidad y ubicacion.
- No conformidades.
- Correccion reportada por subcontratista.
- Reinspeccion y cierre por RS Ingenieria.
- Puntos de espera.
- Bloqueo de avance pagable por no conformidades abiertas.

Criterios de salida:

- Una no conformidad mantiene cantidad afectada como no pagable.
- Un punto de espera bloquea trabajo dependiente hasta liberacion.
- Los criterios historicos de una inspeccion no cambian aunque cambie la plantilla.

## Fase 4: Materiales, Compras e Inventario

Resultado esperado: materiales se controlan desde necesidad hasta consumo real y desviacion.

Entregables:

- Biblioteca de materiales, unidades y conversiones.
- Biblioteca de precios.
- Solicitudes de compra.
- Cotizaciones y politica de compras.
- Ordenes de compra con lineas por proyecto, partida y ubicacion.
- Recepcion de material.
- Entrega de material a actividad.
- Existencias por ubicacion.
- Transferencias internas y entre proyectos.
- Costo promedio ponderado.
- Consumo teorico, consumo real, desperdicio y desviacion.

Criterios de salida:

- El consumo real se calcula por movimientos.
- Una compra consolidada reparte costo por linea.
- Una transferencia entre proyectos mueve material y costo real.
- El sistema muestra desviacion entre consumo teorico y real.

## Fase 5: Finanzas de Proyecto

Resultado esperado: el sistema muestra costo, ingreso, flujo de caja y utilidad proyectada sin mezclarlos.

Entregables:

- Costo del proyecto.
- Compromisos de costo.
- Ingreso del proyecto.
- Metodo de facturacion por fase.
- Cuenta al cliente.
- Facturacion autorizada.
- Anticipo del cliente, amortizacion y retencion.
- Retencion fiscal.
- Costo estimado para terminar.
- Costo final proyectado.
- Utilidad proyectada.
- Cierre mensual de proyecto.
- Exportacion contable V1.

Criterios de salida:

- Una cuenta al cliente requiere validacion tecnica y financiera.
- El cierre mensual queda congelado.
- Ajustes posteriores no reescriben cierres.
- La utilidad proyectada cambia al actualizar pronosticos.

## Fase 6: Bitacora, Evidencias y Offline

Resultado esperado: campo puede registrar informacion critica aunque no tenga conexion estable.

Entregables:

- Bitacora diaria de obra.
- Cierre y revision de bitacora.
- Adendas.
- Evidencia fotografica.
- Evidencia externa.
- Invalidacion de evidencia.
- Registro sin conexion para bitacoras, fotos, controles, avances y movimientos de material.
- Sincronizacion inicial.
- Conflictos de sincronizacion.
- Conciliacion autorizada.

Criterios de salida:

- Un registro creado sin conexion conserva autor, fecha y evidencia.
- Dos cambios concurrentes se conservan hasta conciliacion.
- La evidencia aprobada no puede eliminarse.

## Fase 7: Reportes, Tablero y Portales

Resultado esperado: direccion, cliente y subcontratista tienen visibilidad adecuada sin exponer informacion reservada.

Entregables:

- Tablero de cartera.
- Salud del proyecto por dimension critica mas desfavorable.
- Evaluacion directiva separada.
- Reporte semanal interno.
- Reporte semanal del cliente.
- Reporte publicado congelado.
- Fe de erratas.
- Portal del cliente.
- Portal del subcontratista.
- Expediente del cliente.
- Exportacion de proyecto.

Criterios de salida:

- El cliente no ve costos internos, margenes ni evaluaciones.
- El subcontratista solo ve sus subcontratos.
- Un reporte publicado conserva exactamente lo comunicado.
- La salud roja no puede ocultarse por promedio.

## Fase 8: Beta Interna

Resultado esperado: RS Ingenieria puede usar Civora en un proyecto piloto controlado.

Entregables:

- Proyecto piloto configurado.
- Carga inicial de partidas, fichas y precios.
- Flujo completo de avance, calidad, estimacion y costo.
- Reporte semanal real.
- Cierre mensual simulado o real.
- Lista de ajustes antes de V1.

Criterios de salida:

- El equipo puede operar un ciclo semanal real.
- Las decisiones criticas quedan trazadas.
- Los errores detectados se convierten en issues priorizados.

## Fase 9: V1 Completa

Resultado esperado: Civora V1 queda lista para operar proyectos reales con alcance inicial.

Entregables:

- Modulos V1 completos.
- Pruebas principales automatizadas.
- Documentacion de operacion.
- Politica de respaldo y recuperacion.
- Politica de conservacion inicial.
- Checklist de seguridad y permisos.
- Preparacion de soporte.

Criterios de salida:

- V1 cumple el alcance definido en `PRD.md`.
- Las exclusiones de V2 permanecen fuera.
- El sistema puede sostener un proyecto real de RS Ingenieria.

## Estructura Recomendada en Linear

Initiative:

- `Civora V1`

Projects:

- `Fundacion tecnica`
- `Tracer bullet operativo`
- `Calidad y no conformidades`
- `Materiales, compras e inventario`
- `Subcontratos y estimaciones`
- `Finanzas y cierres mensuales`
- `Bitacora, evidencias y offline`
- `Reportes y tablero`
- `Portal cliente`
- `Portal subcontratista`
- `Beta interna`

Labels:

- `v1`
- `v2`
- `domain`
- `backend`
- `frontend`
- `offline`
- `quality`
- `materials`
- `finance`
- `subcontracts`
- `reports`
- `portal`
- `security`
- `decision`
- `spike`

Issue template:

```md
## Contexto

## Resultado esperado

## Criterios de aceptacion

## Fuera de alcance

## Referencias
- PRD:
- CONTEXT:
- ADR:
```

## Primeros Issues Recomendados

1. Crear ADR de stack tecnico.
2. Crear proyecto Phoenix base.
3. Configurar PostgreSQL y Ecto.
4. Crear autenticacion inicial.
5. Modelar usuarios, roles y asignaciones de proyecto.
6. Modelar proyecto y fase del proyecto.
7. Modelar partida de obra.
8. Modelar ficha de rendimiento y ficha presupuestada.
9. Modelar presupuesto aprobado.
10. Modelar subcontrato y monto contractual vigente.
11. Modelar avance ejecutado y avance pagable.
12. Modelar control de calidad basico.
13. Modelar estimacion de subcontrato.
14. Crear prueba end-to-end del tracer bullet.

## Riesgos Principales

- V1 es amplia; si no se respeta el tracer bullet, el proyecto puede dispersarse.
- Offline-first condiciona arquitectura y debe probarse temprano.
- Calidad y pagos estan fuertemente acoplados; un modelo debil permitiria pagar trabajo no aceptado.
- Materiales y costos pueden volverse complejos rapidamente; hay que empezar con reglas claras y medibles.
- Portales externos requieren permisos estrictos para no exponer informacion reservada.

## Proxima Decision

Cerrar el ADR de stack tecnico para confirmar Elixir/Phoenix, PostgreSQL, Oban, almacenamiento S3-compatible y estrategia PWA/app para campo offline.
