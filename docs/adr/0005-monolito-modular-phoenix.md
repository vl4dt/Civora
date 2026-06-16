# Monolito modular Phoenix para el MVP

El MVP se construira como una sola aplicacion Phoenix modular, separando el dominio en contextos internos como cuentas, proyectos, presupuestos, subcontratos, calidad, avance, costos, evidencias y auditoria. Se evita iniciar con microservicios o un monorepo complejo porque el principal riesgo del MVP esta en validar el flujo de negocio y sus invariantes, no en escalar multiples despliegues desde el primer dia.
