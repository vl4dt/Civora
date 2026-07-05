# RS-37 - Plan de validacion end-user MVP

RS-37 valida el flujo funcional completo del MVP con el dataset piloto de
staging. No debe marcarse como terminado hasta que el Product Owner o usuario
final ejecute la prueba, confirme el resultado y registre los ajustes
posteriores.

## Alcance

Validar el recorrido desde proyecto hasta costo:

- Proyecto y fase.
- Presupuesto y partidas.
- Actividades y avance ejecutado.
- Calidad, rechazo y no conformidad.
- Evidencia ficticia.
- Subcontratos y estimaciones.
- Costo acumulado.
- Reporte interno.
- Auditoria.

RS-37 no crea el dataset. Esa preparacion pertenece a RS-36. La guia de usuario
para acompanar esta validacion esta en `docs/USER_MANUAL_MVP.md`.

## Prerequisitos

- Staging disponible en <https://civora-staging.onrender.com>.
- RS-36 desplegado y ejecutado en staging.
- Proyecto visible: `MVP Piloto Simulado - Residencial Las Palmas`.
- Usuario recomendado: `piloto.admin@civora.test`.
- Clave: `Civora pilot 2026!`.
- Navegador actualizado.
- Medio para registrar la demo final: grabacion de pantalla, notas firmadas o
  comentario resumido en Linear con evidencias.

Limitacion conocida: mientras R2 este diferido, la evidencia usa fallback local
en Render. Se valida metadata, carga, relaciones y auditoria; no se valida
retencion durable de binarios entre reinicios o redeploys.

## Criterio de clasificacion de hallazgos

Use estas categorias al final de la prueba:

| Categoria | Uso |
| --- | --- |
| Bloquea RS-37 | Impide ejecutar o entender el flujo completo proyecto-costo. |
| V1 antes de lanzamiento | No bloquea la demo funcional, pero debe resolverse antes de uso real. |
| Backlog | Mejora, pulido o extension que puede esperar. |

## Guion de validacion

Marcar cada punto durante la sesion.

### 1. Acceso

- [ ] Abrir <https://civora-staging.onrender.com>.
- [ ] Iniciar sesion con `piloto.admin@civora.test`.
- [ ] Confirmar que aparece la pantalla `Proyectos`.
- [ ] Confirmar que aparece `MVP Piloto Simulado - Residencial Las Palmas`.

Resultado esperado: el usuario entra sin ayuda tecnica y encuentra el proyecto.

### 2. Proyecto y fase

- [ ] Abrir el proyecto piloto.
- [ ] Confirmar estado `Activo`.
- [ ] Confirmar referencia `RS-36 / Dataset piloto MVP`.
- [ ] Confirmar la fase `Construccion piloto`.

Resultado esperado: existe 1 proyecto y 1 fase de construccion.

### 3. Presupuesto y partidas

- [ ] Entrar a `Presupuesto`.
- [ ] Confirmar que el presupuesto esta aprobado.
- [ ] Confirmar que existen 4 partidas presupuestadas.
- [ ] Entrar a `Partidas`.
- [ ] Confirmar que las 4 partidas son visibles.

Resultado esperado: el usuario entiende la linea base y las partidas del MVP.

### 4. Actividades, avance y evidencia

- [ ] Abrir una partida.
- [ ] Revisar actividades asociadas.
- [ ] Revisar avances ejecutados.
- [ ] Confirmar que hay evidencia ficticia relacionada cuando aplica.
- [ ] Confirmar que no se uso informacion real o sensible.

Resultado esperado: el usuario entiende que el avance ejecutado es entrada
operativa y todavia puede depender de calidad para ser pagable.

### 5. Calidad y no conformidad

- [ ] Abrir `Concreto en zapatas y pedestales`.
- [ ] Confirmar aceptacion parcial de avance.
- [ ] Confirmar cantidad rechazada.
- [ ] Confirmar 1 no conformidad abierta.
- [ ] Confirmar defecto:
  `Cangrejera localizada en pedestal P3 posterior al desencofrado`.

Resultado esperado: el usuario ve como calidad afecta avance pagable y genera
seguimiento.

### 6. Subcontratos y estimaciones

- [ ] Entrar a `Subcontratos`.
- [ ] Confirmar que existen 2 subcontratos.
- [ ] Abrir cada subcontrato.
- [ ] Revisar partidas cubiertas y condiciones comerciales.
- [ ] Confirmar que existen 2 estimaciones.
- [ ] Confirmar que las lineas usan avance pagable, no avance rechazado.

Resultado esperado: el usuario entiende como Civora conecta subcontrato,
avance aprobado y estimacion.

### 7. Costo

- [ ] Entrar a `Costo`.
- [ ] Revisar monto contratado.
- [ ] Revisar estimado acumulado.
- [ ] Revisar saldo basico.
- [ ] Confirmar que el costo acumulado proviene de las estimaciones.

Resultado esperado: se cumple el recorrido desde proyecto hasta costo.

### 8. Reporte interno

- [ ] Entrar a `Reporte`.
- [ ] Confirmar 4 partidas presupuestadas.
- [ ] Confirmar avance estimado/pagable.
- [ ] Confirmar 1 no conformidad abierta.
- [ ] Confirmar costo acumulado.
- [ ] Confirmar 2 estimaciones.

Resultado esperado: el reporte permite presentar el estado del proyecto en una
vista consolidada.

### 9. Auditoria

- [ ] Entrar a `Auditoria`.
- [ ] Confirmar eventos de proyecto y presupuesto.
- [ ] Confirmar eventos de avance, calidad y no conformidad.
- [ ] Confirmar eventos de estimacion y evidencia.
- [ ] Confirmar actor, accion, entidad y fecha.

Resultado esperado: las acciones criticas del flujo quedan trazadas.

## Registro de demo final

Al terminar la sesion, registrar:

- Fecha y hora de la prueba.
- Persona que ejecuto la validacion.
- Usuario piloto utilizado.
- Resultado general: aprobado, aprobado con observaciones o bloqueado.
- Link o ubicacion de la grabacion/demo final.
- Lista de hallazgos clasificados como `Bloquea RS-37`, `V1 antes de
  lanzamiento` o `Backlog`.

## Cierre de RS-37

RS-37 puede cerrarse solo cuando:

- El flujo proyecto-costo fue ejecutado en staging.
- El Product Owner confirmo validacion funcional.
- La demo final quedo registrada.
- Los ajustes posteriores quedaron priorizados para V1 o backlog.

Si aparece un bloqueo, mantener RS-37 abierto y crear o priorizar el issue
correspondiente antes de repetir la validacion.

