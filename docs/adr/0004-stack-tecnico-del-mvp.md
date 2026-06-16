# Stack tecnico del MVP

El MVP de Civora usara Elixir y Phoenix como plataforma principal, con Phoenix LiveView para la web interna, PostgreSQL con Ecto como base de datos relacional, Oban para trabajos en segundo plano y almacenamiento compatible con S3 para evidencias y documentos. Esta decision favorece productividad, concurrencia, trazabilidad, flujos de aprobacion y una base solida para evolucionar hacia API JSON y operacion offline en V1; el offline completo queda fuera del MVP pero debe ser considerado desde el diseno.
