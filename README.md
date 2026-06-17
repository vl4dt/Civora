# Civora

Sistema de gestion de proyectos de arquitectura y construccion para RS Ingenieria.

## Aplicacion Phoenix

El MVP usa Phoenix/Elixir con PostgreSQL, de acuerdo con `docs/adr/0004-stack-tecnico-del-mvp.md` y `docs/adr/0005-monolito-modular-phoenix.md`.

### Requisitos locales

- Elixir `1.20.1-otp-29` gestionado con Mise.
- PostgreSQL local para los pasos con base de datos.

### Comandos basicos

```powershell
mise install
mix deps.get
mix ecto.create
mix phx.server
```

La aplicacion queda disponible en `http://localhost:4000`.

Para ejecutar pruebas:

```powershell
mix test
```

## Documentacion inicial

- `PRD.md`: definicion inicial del producto, alcance V1/V2, historias de usuario y decisiones funcionales.
- `CONTEXT.md`: lenguaje canonico del dominio.
- `docs/adr/`: decisiones relevantes de producto y arquitectura.

## Estado

Aplicacion Phoenix base creada para el MVP. La siguiente configuracion funcional de base de datos y Ecto se trabaja en RS-13.
