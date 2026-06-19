# Staging en Render

Staging usa un Blueprint de Render definido en `render.yaml`. El Blueprint crea
un servicio web Phoenix y una base PostgreSQL 16 administrada en la misma region.

## Configuracion

| Variable | Origen | Uso |
| --- | --- | --- |
| `DATABASE_URL` | Referencia a `civora-staging-db` | Conexion Ecto a PostgreSQL. |
| `SECRET_KEY_BASE` | Generada por Render | Firma y cifra datos de Phoenix. |
| `ELIXIR_VERSION` | `1.20.1` | Fija la version del runtime. |
| `POOL_SIZE` | `5` | Limita conexiones del servicio de staging. |
| `RENDER_EXTERNAL_HOSTNAME` | Proporcionada por Render | Configura el host publico de Phoenix. |
| `PORT` | Proporcionada por Render | Puerto HTTP donde escucha Phoenix. |

`PHX_HOST` puede definirse manualmente para usar un dominio personalizado. Si
existe, tiene prioridad sobre `RENDER_EXTERNAL_HOSTNAME`.

## Comandos de despliegue

Render ejecuta:

```text
Build: ./bin/render-build.sh
Start: _build/prod/rel/civora/bin/render-start
Health check: /health
```

El build compila dependencias, activos y una release OTP. El inicio aplica las
migraciones pendientes antes de levantar Phoenix. Staging usa una sola instancia
gratuita; si se cambia a un plan pagado, las migraciones deben moverse a
`preDeployCommand` para separarlas del inicio del servidor.

## Crear staging

1. Fusionar `render.yaml` en `main` y confirmar que GitHub contiene el archivo.
2. Abrir el [Blueprint de Civora en Render](https://dashboard.render.com/blueprint/new?repo=https://github.com/vl4dt/Civora).
3. Autorizar acceso al repositorio `vl4dt/Civora` si Render lo solicita.
4. Revisar los recursos `civora-staging` y `civora-staging-db`.
5. Aplicar el Blueprint y esperar a que el despliegue quede `Live`.
6. Abrir la URL del servicio y verificar que `/` y `/health` respondan `200`.

El plan gratuito de PostgreSQL es apropiado solo para staging temporal. Render
elimina estas bases despues de su periodo de vigencia, por lo que staging debe
usar datos descartables y recreables.
