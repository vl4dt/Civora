# Dataset piloto MVP

RS-36 carga un dataset simulado y realista para validar el flujo MVP sin usar
un proyecto real ni informacion sensible. El dataset es idempotente: puede
ejecutarse varias veces y reutiliza los registros piloto existentes en vez de
duplicarlos.

## Contenido

- 1 proyecto: `MVP Piloto Simulado - Residencial Las Palmas`.
- 1 fase de construccion.
- 6 usuarios internos de prueba con roles MVP.
- 4 partidas con fichas de rendimiento y presupuesto aprobado.
- 2 contrapartes subcontratistas.
- 2 subcontratos.
- 2 avances ejecutados por partida.
- Controles de calidad para los avances, incluyendo aceptacion parcial.
- 1 no conformidad abierta originada desde control de calidad.
- 2 estimaciones de subcontrato.
- 3 evidencias ficticias en texto plano asociadas a avance, calidad y no
  conformidad.

Las evidencias son ficticias y no contienen datos sensibles. Mientras R2 no
este configurado, Civora usa el fallback local documentado en
`docs/R2_STORAGE.md` y `docs/RENDER_STAGING.md`: se validan metadatos, carga,
relaciones, restricciones y auditoria, pero no la retencion durable de binarios
entre reinicios o redeploys.

## Ejecutar localmente

Con PostgreSQL local levantado y migraciones aplicadas:

```powershell
mix civora.seed_pilot_dataset
```

Si el `mix` del PATH no encuentra Erlang en Windows, ejecutar con Mise:

```powershell
mise exec -c "mix civora.seed_pilot_dataset"
```

Usuarios creados por el loader:

| Rol | Email |
| --- | --- |
| Administrador | `piloto.admin@civora.test` |
| Director de proyecto | `piloto.director@civora.test` |
| Presupuesto | `piloto.presupuesto@civora.test` |
| Calidad | `piloto.calidad@civora.test` |
| Finanzas | `piloto.finanzas@civora.test` |
| Consulta | `piloto.consulta@civora.test` |

Todos usan la clave inicial `Civora pilot 2026!`.

## Ejecutar en Render staging

Despues de desplegar una version que incluya RS-36 y correr migraciones, abrir
una Shell del servicio `civora-staging` en Render y ejecutar:

```bash
_build/prod/rel/civora/bin/civora eval "Civora.Release.seed_pilot_dataset()"
```

El comando puede repetirse si staging se recrea o si el primer intento queda
interrumpido antes de completar el dataset. No marca RS-37 listo por si solo;
RS-37 debe ejecutarse despues de confirmar que staging contiene este dataset.

Para la validacion end-user, usar el manual `docs/USER_MANUAL_MVP.md` y el
guion de ejecucion `docs/RS37_VALIDATION_PLAN.md`.
