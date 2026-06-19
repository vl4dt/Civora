# Staging en Render

Staging usa un Blueprint de Render definido en `render.yaml`. El Blueprint crea
un servicio web Phoenix y una base PostgreSQL 16 administrada en la misma region.

## Configuracion

| Variable | Origen | Uso |
| --- | --- | --- |
| `DATABASE_URL` | Referencia a `civora-staging-db` | Conexion Ecto a PostgreSQL. |
| `SECRET_KEY_BASE` | Definida en Render | Firma y cifra datos de Phoenix; debe tener al menos 64 bytes. |
| `ELIXIR_VERSION` | `1.20.1` | Fija la version del runtime. |
| `POOL_SIZE` | `5` | Limita conexiones del servicio de staging. |
| `RENDER_EXTERNAL_HOSTNAME` | Proporcionada por Render | Configura el host publico de Phoenix. |
| `PORT` | Proporcionada por Render | Puerto HTTP donde escucha Phoenix. |
| `R2_ENDPOINT` | Definida en Render | Endpoint S3 de Cloudflare R2. |
| `R2_BUCKET` | Definida en Render | Bucket privado de staging. |
| `R2_ACCESS_KEY_ID` | Definida en Render | Identificador del token R2. |
| `R2_SECRET_ACCESS_KEY` | Definida en Render | Secreto del token R2. |

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
4. Generar `SECRET_KEY_BASE` con `mix phx.gen.secret` y pegar el resultado cuando Render lo solicite.
5. Revisar los recursos `civora-staging` y `civora-staging-db`.
6. Aplicar el Blueprint y esperar a que el despliegue quede `Live`.
7. Abrir la URL del servicio y verificar que `/` y `/health` respondan `200`.

El plan gratuito de PostgreSQL es apropiado solo para staging temporal. Render
elimina estas bases despues de su periodo de vigencia, por lo que staging debe
usar datos descartables y recreables.
