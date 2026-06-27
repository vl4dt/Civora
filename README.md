# Civora

Sistema de gestion de proyectos de arquitectura y construccion para RS Ingenieria.

## Aplicacion Phoenix

El MVP usa Phoenix/Elixir con PostgreSQL, de acuerdo con `docs/adr/0004-stack-tecnico-del-mvp.md` y `docs/adr/0005-monolito-modular-phoenix.md`.

### Requisitos locales

- Elixir `1.20.1-otp-29` gestionado con Mise.
- Docker Desktop con Docker Compose para PostgreSQL 16.

### Comandos basicos

```powershell
mise install
mix deps.get
docker compose up -d db
mix ecto.setup
mix phx.server
```

La aplicacion queda disponible en `http://localhost:4000`.

El servicio local usa `postgres:postgres@localhost/civora_dev`. Para usar otra
instancia, define `DATABASE_URL` con formato
`ecto://USUARIO:CLAVE@HOST/BASE_DE_DATOS` antes de ejecutar Mix.

Para ejecutar pruebas:

```powershell
mix test
```

Las pruebas crean y migran `civora_test` automaticamente. `TEST_DATABASE_URL`
permite cambiar esa conexion sin afectar desarrollo. Para detener PostgreSQL:

```powershell
docker compose down
```

## Staging

La configuracion reproducible de staging vive en `render.yaml`. El procedimiento,
las variables y los comandos de despliegue estan documentados en
`docs/RENDER_STAGING.md`.

La configuracion y API base de almacenamiento privado en Cloudflare R2 estan
documentadas en `docs/R2_STORAGE.md`.

La autenticacion interna, creacion de usuarios y recuperacion de acceso estan
documentadas en `docs/AUTHENTICATION.md`.

Los roles MVP, asignaciones y permisos iniciales por proyecto estan documentados
en `docs/PROJECT_ROLES.md`.

El registro inalterable y los contratos de eventos criticos estan documentados
en `docs/AUDIT.md`.

Las partidas de obra, sus invariantes y permisos estan documentadas en
`docs/WORK_ITEMS.md`.

La biblioteca reutilizable de fichas de rendimiento esta documentada en
`docs/PERFORMANCE_SHEETS.md`.

Las copias historicas por partida usadas en presupuesto estan documentadas en
`docs/BUDGETED_PERFORMANCE_SHEETS.md`.

La generacion y aprobacion de la linea base inalterable estan documentadas en
`docs/APPROVED_BUDGETS.md`.

Las identidades globales usadas como proveedores o subcontratistas estan documentadas en
`docs/COUNTERPARTIES.md`.

Los acuerdos de subcontrato, sus partidas y condiciones iniciales estan documentados en
`docs/SUBCONTRACTS.md`.

Las actividades de obra vinculadas a partidas estan documentadas en
`docs/WORK_ACTIVITIES.md`.

## Documentacion inicial

- `PRD.md`: definicion inicial del producto, alcance V1/V2, historias de usuario y decisiones funcionales.
- `CONTEXT.md`: lenguaje canonico del dominio.
- `docs/adr/`: decisiones relevantes de producto y arquitectura.

## Estado

Aplicacion Phoenix base con PostgreSQL y Ecto configurados para desarrollo local.
