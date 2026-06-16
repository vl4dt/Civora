# Civora MVP Plan

## Objetivo del MVP

Validar que Civora puede controlar el flujo principal de un proyecto de construccion conectando presupuesto, ejecucion, calidad, estimacion y costo.

El MVP no busca completar V1. Busca demostrar que el nucleo del sistema funciona con datos reales o semirreales de RS Ingenieria:

**Proyecto -> partida de obra -> ficha presupuestada -> subcontrato -> avance ejecutado -> control de calidad -> avance pagable -> estimacion -> costo del proyecto**

## Definicion de MVP

El MVP es una version interna, usada por RS Ingenieria, que permite administrar un proyecto piloto con partidas, presupuesto basico, subcontrato, avance, calidad y estimaciones.

Debe responder cinco preguntas:

1. Que se presupuesto?
2. Que se contrato?
3. Que se ejecuto?
4. Que fue aceptado por calidad?
5. Que se puede pagar y como afecta el costo del proyecto?

## Usuarios del MVP

- Administrador interno.
- Director de proyecto.
- Responsable tecnico / calidad.
- Responsable de presupuesto.
- Responsable de finanzas basicas.

No entran todavia:

- Cliente externo.
- Subcontratista con portal propio.
- Proveedor.
- Personal de campo con app offline completa.

## Alcance Incluido

### 1. Fundacion

- Aplicacion base.
- Autenticacion.
- Usuarios internos.
- Roles basicos por proyecto.
- Auditoria basica de acciones criticas.
- Proyecto y fase del proyecto.

### 2. Presupuesto Minimo

- Partidas de obra.
- Fichas de rendimiento reutilizables.
- Fichas presupuestadas.
- Presupuesto inicial del proyecto.
- Aprobacion de presupuesto como linea base.
- Inmutabilidad del presupuesto aprobado.

### 3. Subcontratos Minimos

- Contraparte.
- Subcontrato vinculado a una o varias partidas.
- Modalidad de suministro.
- Monto contractual vigente.
- Anticipo, retencion y amortizacion como campos configurables simples.

### 4. Avance y Calidad Minimos

- Actividades de obra vinculadas a partidas.
- Registro de avance ejecutado por cantidad y ubicacion.
- Control de calidad basico por partida.
- Aceptacion parcial.
- Avance pagable.
- No conformidad simple.
- Cierre de no conformidad por responsable tecnico.

### 5. Estimaciones y Costo Minimo

- Estimacion de subcontrato basada en avance pagable.
- Validacion para impedir pago de avance no aceptado.
- Validacion para impedir exceder monto contractual vigente.
- Costo del proyecto por subcontratos y estimaciones.
- Vista simple de presupuesto vs estimado vs pagable.

### 6. Evidencia Basica

- Adjuntar fotografias o archivos a avance, control de calidad y no conformidad.
- Registrar autor y fecha.
- No eliminar evidencia asociada a registros aprobados.

### 7. Reporte Interno Basico

- Resumen del proyecto.
- Partidas presupuestadas.
- Avance ejecutado.
- Avance pagable.
- No conformidades abiertas.
- Estimaciones generadas.
- Costo acumulado basico.

## Fuera del MVP

- Portal del cliente.
- Portal del subcontratista.
- Portal del proveedor.
- Operacion offline completa.
- Sincronizacion y conflictos offline.
- Compras, cotizaciones e inventario completo.
- Consumo teorico vs consumo real de materiales.
- Transferencias de material.
- Costo promedio ponderado.
- Cuentas al cliente.
- Facturacion autorizada.
- Cierres mensuales.
- Exportacion contable.
- Reportes semanales publicados.
- Tablero de cartera.
- Salud del proyecto.
- Gestion avanzada de diseno.
- Modelos BIM.
- Permisos de trabajo y seguridad avanzada.
- Asistencia individual.
- Gestion de equipos y maquinaria.
- Firma electronica avanzada.

## Criterios de Exito

El MVP se considera exitoso si RS Ingenieria puede cargar un proyecto piloto y completar este flujo:

1. Crear proyecto.
2. Crear partidas.
3. Crear fichas presupuestadas.
4. Aprobar presupuesto inicial.
5. Crear subcontrato.
6. Registrar avance ejecutado.
7. Revisar calidad.
8. Aceptar avance parcial.
9. Generar estimacion.
10. Ver costo del proyecto actualizado.

Ademas:

- El sistema impide estimar cantidades no aceptadas por calidad.
- El sistema impide exceder el monto contractual vigente.
- El presupuesto aprobado no puede editarse directamente.
- La evidencia queda vinculada a registros tecnicos.
- Las acciones criticas quedan auditadas.

## Primer Proyecto Piloto Recomendado

Usar un proyecto pequeno o simulado con pocas partidas, por ejemplo:

- Muros.
- Instalacion electrica.
- Piso o acabado.
- Pintura.

Cada partida debe tener:

- Unidad de medida.
- Cantidad presupuestada.
- Precio presupuestado.
- Subcontrato asociado.
- Al menos dos registros de avance.
- Al menos un control de calidad.
- Al menos una estimacion.

## Milestones del MVP

### M0: Decision Tecnica

Resultado:

- ADR de stack tecnico aprobado.
- Reglas de trabajo GitHub + Linear definidas.

### M1: Base Operativa

Resultado:

- Aplicacion base.
- Login.
- Usuarios.
- Roles por proyecto.
- Proyecto y fases.
- Auditoria basica.

### M2: Presupuesto y Partidas

Resultado:

- Partidas.
- Fichas de rendimiento.
- Fichas presupuestadas.
- Presupuesto aprobado.

### M3: Subcontrato y Avance

Resultado:

- Contrapartes.
- Subcontratos.
- Actividades.
- Avance ejecutado.

### M4: Calidad y Avance Pagable

Resultado:

- Control de calidad basico.
- Aceptacion parcial.
- No conformidades simples.
- Avance pagable.

### M5: Estimacion y Costo

Resultado:

- Estimaciones de subcontrato.
- Validaciones de monto.
- Costo del proyecto.
- Reporte interno basico.

### M6: Piloto Interno

Resultado:

- Proyecto piloto cargado.
- Flujo completo probado por RS Ingenieria.
- Lista priorizada de ajustes para pasar de MVP a V1.

## Issues Iniciales para Linear

1. Crear ADR de stack tecnico.
2. Crear proyecto Phoenix base.
3. Configurar PostgreSQL y Ecto.
4. Implementar autenticacion interna.
5. Modelar usuarios y roles por proyecto.
6. Modelar proyecto y fase.
7. Implementar auditoria basica.
8. Modelar partida de obra.
9. Modelar ficha de rendimiento.
10. Modelar ficha presupuestada.
11. Implementar presupuesto aprobado inalterable.
12. Modelar contraparte.
13. Modelar subcontrato.
14. Modelar actividad de obra.
15. Registrar avance ejecutado.
16. Implementar control de calidad basico.
17. Implementar aceptacion parcial.
18. Implementar no conformidad simple.
19. Calcular avance pagable.
20. Generar estimacion de subcontrato.
21. Validar estimacion contra avance pagable.
22. Validar estimacion contra monto contractual vigente.
23. Calcular costo del proyecto.
24. Adjuntar evidencia basica.
25. Crear reporte interno basico.
26. Cargar proyecto piloto.
27. Ejecutar prueba completa del flujo MVP.

## Riesgos del MVP

- Intentar incluir materiales e inventario completo demasiado temprano.
- Construir portales externos antes de validar el flujo interno.
- Subestimar la complejidad de calidad y avance pagable.
- Permitir ediciones historicas sin auditoria.
- Diseñar pantallas antes de estabilizar los estados del dominio.

## Decision de Corte

El MVP termina en el momento en que RS Ingenieria puede usar Civora internamente para decidir cuanto avance de un subcontratista es pagable y como ese avance afecta el costo del proyecto.

Todo lo que no ayude directamente a esa decision pertenece a V1 posterior o V2.
