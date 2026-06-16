# PRD: Sistema de Gestion de Proyectos de Arquitectura y Construccion

## Problem Statement

RS Ingenieria necesita un sistema para gestionar proyectos de arquitectura y construccion desde la contratacion hasta el cierre, manteniendo control tecnico, financiero, documental y operativo en un solo lugar.

La forma de trabajo combina diseno propio, presupuesto, planificacion, construccion con mano de obra subcontratada, control de calidad, control de materiales, compras, estimaciones, cuentas al cliente, reportes y cierre. Hoy estos procesos pueden dispersarse entre documentos, mensajeria, hojas de calculo y memoria operativa, lo que dificulta responder preguntas criticas: que se aprobo, que se ejecuto, que se puede pagar, cuanto material debio consumirse, cuanto se gasto realmente, que falta por decidir y cual sera la utilidad final del proyecto.

La primera version debe ordenar el flujo principal sin intentar resolver todo el negocio de una vez. Debe crear una fuente oficial del proyecto, funcionar en campo con conexion inestable y preservar la trazabilidad de decisiones, evidencias, aprobaciones y cambios.

## Solution

Construir una plataforma de gestion integral para proyectos de arquitectura y construccion, centrada en el control de proyectos, fases, roles, fichas de rendimiento, precios, presupuestos, subcontratos, avance pagable, estimaciones, calidad, materiales, compras, inventario, consumo, bitacora, evidencias, reportes, finanzas de proyecto, cuentas al cliente, cierres mensuales, portal del cliente y portal del subcontratista limitado.

El sistema debe distinguir con claridad los conceptos clave del negocio:

- Proyecto como acuerdo principal con el cliente, compuesto por fases opcionales.
- Partida de obra como unidad comun para presupuestar, contratar, medir avance y controlar calidad.
- Actividad de obra como unidad temporal y espacial de programacion.
- Ficha de rendimiento como plantilla reutilizable.
- Ficha presupuestada como copia historica ajustable dentro de un presupuesto.
- Avance ejecutado como trabajo realizado.
- Avance pagable como trabajo aceptado por calidad y habilitado para estimacion.
- Presupuesto aprobado como linea base inalterable.
- Orden de cambio como mecanismo formal para modificar alcance, costo o plazo.
- Fuente oficial del proyecto como conjunto de registros formalizados dentro del sistema.

La V1 debe permitir que campo capture bitacoras, fotografias, inspecciones, avances, movimientos de material y registros de seguridad sin conexion. La sincronizacion posterior debe conservar autoria, fecha y evidencia. Si existen cambios concurrentes, se conservaran ambas versiones hasta una conciliacion autorizada.

## User Stories

1. Como director de proyecto, quiero crear un proyecto con fases opcionales, para reflejar contratos de solo diseno, solo supervision, construccion o combinaciones.
2. Como director de proyecto, quiero asignar roles por proyecto, para que cada persona vea y actue solo donde corresponde.
3. Como usuario interno, quiero consultar el contexto de un proyecto, para entender fases, responsables, presupuesto, avance, calidad y finanzas.
4. Como responsable de diseno, quiero registrar entregables de diseno por disciplina, para controlar revisiones, fechas, responsables y aprobaciones.
5. Como responsable de diseno, quiero emitir una revision documental, para conservar el historial de documentos tecnicos.
6. Como responsable tecnico, quiero marcar una revision como vigente para construccion, para evitar usar archivos obsoletos.
7. Como responsable tecnico, quiero distribuir una revision documental con acuse, para confirmar que los responsables afectados la recibieron.
8. Como coordinador de diseno, quiero registrar interferencias de diseno, para bloquear emisiones criticas hasta resolver conflictos entre disciplinas.
9. Como coordinador de diseno, quiero asignar responsable y validadores a cada interferencia, para que ninguna disciplina cierre sola un conflicto compartido.
10. Como director de proyecto, quiero clasificar una modificacion de diseno como correccion o cambio solicitado, para saber quien asume el costo.
11. Como cliente, quiero revisar entregables de diseno en el portal del cliente, para aprobar o comentar lo que me corresponde.
12. Como cliente, quiero emitir comentarios dentro de una ronda de revision, para que mis observaciones queden numeradas y trazables.
13. Como responsable de diseno, quiero cerrar una ronda de revision, para separar comentarios incluidos de comentarios tardios.
14. Como presupuesto, quiero mantener una biblioteca de precios por region, fecha y fuente, para preparar presupuestos con datos controlados.
15. Como presupuesto, quiero proponer precios y enviarlos a aprobacion, para evitar que datos no validados se usen en presupuestos.
16. Como direccion, quiero que variaciones fuertes de precio requieran aprobacion adicional, para controlar precios atipicos.
17. Como presupuesto, quiero crear fichas de rendimiento reutilizables, para calcular materiales, mano de obra, desperdicio y productividad esperada.
18. Como presupuesto, quiero que cada presupuesto use fichas presupuestadas congeladas, para que cambios futuros en plantillas no alteren presupuestos historicos.
19. Como presupuesto, quiero manejar unidades base y conversiones aprobadas, para evitar errores en compras, consumos y costos.
20. Como presupuesto, quiero definir materiales sustitutos con autorizacion, para controlar reemplazos tecnicos y su impacto.
21. Como director de proyecto, quiero aprobar un presupuesto como linea base, para comparar cambios, costos reales y utilidad.
22. Como director de proyecto, quiero que un presupuesto aprobado no se edite directamente, para conservar la trazabilidad comercial.
23. Como director de proyecto, quiero crear revisiones de presupuesto, para documentar cambios posteriores a aprobacion.
24. Como director de proyecto, quiero gestionar ordenes de cambio, para agregar, modificar o eliminar alcance con impacto en costo y plazo.
25. Como cliente, quiero aprobar ordenes de cambio desde el portal del cliente, para formalizar cambios de alcance, costo o plazo.
26. Como responsable tecnico, quiero registrar cambios de emergencia, para documentar trabajos inmediatos por seguridad o prevencion de danos.
27. Como planificador, quiero crear actividades de obra vinculadas a una sola partida, para programar sectores o periodos sin romper el presupuesto.
28. Como planificador, quiero definir dependencias entre actividades, para controlar secuencia y bloqueos.
29. Como planificador, quiero manejar linea base contractual, linea base operativa, pronostico e historial de reprogramaciones, para separar compromiso y plan interno.
30. Como planificador, quiero configurar calendarios laborales por proyecto o actividad, para representar jornadas, turnos, feriados y restricciones.
31. Como planificador, quiero registrar eventos de plazo, para documentar lluvia, falta de acceso, suspensiones u otras causas.
32. Como director de proyecto, quiero aprobar analisis de plazo antes de presentarlos al cliente, para sustentar ampliaciones sin automatismos.
33. Como responsable de campo, quiero registrar avance ejecutado por actividad, cantidad y ubicacion, para documentar lo realizado.
34. Como responsable de calidad, quiero inspeccionar avance ejecutado, para determinar que cantidad se convierte en avance pagable.
35. Como responsable de calidad, quiero aceptar parcialmente una partida por cantidad y ubicacion, para no esperar el cierre total.
36. Como subcontratista, quiero reportar avance y evidencia desde mi portal, para solicitar revision y pago.
37. Como responsable tecnico, quiero validar el avance reportado por subcontratistas, para evitar pagos sin aceptacion.
38. Como responsable de calidad, quiero usar plantillas de control de calidad por tipo de partida y momento de inspeccion, para estandarizar criterios.
39. Como responsable de calidad, quiero que los controles del proyecto sean copias versionadas, para conservar criterios historicos.
40. Como responsable de calidad, quiero definir puntos de espera, para impedir continuar o cubrir trabajos sin liberacion.
41. Como responsable de calidad, quiero registrar no conformidades, para dar seguimiento a defectos, responsables, evidencia y plazo.
42. Como subcontratista, quiero reportar una correccion, para solicitar reinspeccion.
43. Como responsable tecnico, quiero cerrar no conformidades solo despues de reinspeccionar, para mantener autoridad tecnica.
44. Como director de proyecto, quiero permitir aceptaciones excepcionales con autorizaciones adicionales, para resolver casos especiales sin perder trazabilidad.
45. Como responsable de compras, quiero crear solicitudes de compra desde necesidades de partidas, para justificar cantidades contra existencia y consumo pendiente.
46. Como responsable de compras, quiero consolidar ordenes de compra de varios proyectos, para negociar mejor sin perder asignacion por linea.
47. Como responsable de compras, quiero aplicar politicas de compras por rango de monto, para exigir cotizaciones y aprobaciones adecuadas.
48. Como responsable de compras, quiero adjudicar una cotizacion que no sea la mas barata con justificacion, para considerar plazo, calidad, garantia y riesgo.
49. Como almacen, quiero registrar recepciones de material en ubicaciones del proyecto, para controlar existencias.
50. Como almacen, quiero registrar entregas de material a actividad, para asignar consumo a responsable, partida y ubicacion.
51. Como almacen, quiero transferir materiales entre ubicaciones del mismo proyecto, para mantener trazabilidad fisica.
52. Como direccion, quiero transferir materiales entre proyectos con costo real, para reasignar costo correctamente.
53. Como finanzas, quiero valorar salidas y transferencias con costo promedio ponderado, para mantener un metodo operativo simple.
54. Como responsable de materiales, quiero comparar consumo teorico contra consumo real, para detectar desviaciones y desperdicios.
55. Como responsable de materiales, quiero que el consumo real se calcule desde movimientos, para evitar cifras manuales sin respaldo.
56. Como responsable de materiales, quiero registrar ajustes de material con motivo y evidencia, para corregir diferencias fisicas sin borrar historial.
57. Como responsable de subcontratos, quiero crear subcontratos que agrupen una o varias partidas, para reflejar la forma real de contratar mano de obra.
58. Como responsable de subcontratos, quiero definir modalidad de suministro por subcontrato, para saber si materiales los aporta RS Ingenieria, el subcontratista o ambos.
59. Como responsable de subcontratos, quiero configurar anticipo, amortizacion y retencion por subcontrato, para aplicar condiciones negociadas.
60. Como subcontratista, quiero presentar estimaciones basadas en avance pagable, para cobrar trabajo aceptado.
61. Como finanzas, quiero impedir pagos que excedan el monto contractual vigente, para controlar compromisos.
62. Como finanzas, quiero liberar retenciones por tramos, para asociar pagos a recepcion y fin de garantia.
63. Como responsable tecnico, quiero cerrar subcontratos con checklist tecnico, financiero y documental, para asegurar cumplimiento.
64. Como responsable tecnico, quiero evaluar subcontratistas al cierre, para alimentar su historial.
65. Como direccion, quiero definir elegibilidad de contraparte como habilitada, condicionada o bloqueada, para controlar nuevas adjudicaciones.
66. Como direccion, quiero rehabilitar contrapartes solo mediante plan de mejora, para evitar que el tiempo borre desempenos deficientes.
67. Como responsable de campo, quiero registrar bitacora diaria de obra, para documentar clima, recursos, actividades, cantidades, materiales, visitas, instrucciones, incidentes y restricciones.
68. Como responsable de campo, quiero cerrar la bitacora al final del dia o inicio del siguiente, para volverla inalterable.
69. Como responsable tecnico, quiero revisar bitacoras cerradas, para validar sin alterar el contenido original.
70. Como responsable de campo, quiero agregar adendas de bitacora, para corregir o ampliar informacion sin reescribir el original.
71. Como usuario de campo, quiero capturar evidencia fotografica con autor, fecha y ubicacion cuando exista, para respaldar registros.
72. Como usuario de campo, quiero importar fotografias externas marcadas como tales, para aprovechar evidencia recibida fuera del sistema.
73. Como responsable tecnico, quiero invalidar evidencia sin eliminarla, para corregir errores manteniendo historial.
74. Como usuario de campo, quiero trabajar sin conexion en bitacoras, fotografias, inspecciones, avances, materiales y seguridad, para operar en obras con conectividad inestable.
75. Como responsable de conciliacion, quiero resolver conflictos de sincronizacion conservando ambas versiones, para no perder informacion concurrente.
76. Como responsable de seguridad, quiero registrar incidentes de seguridad separados de no conformidades, para investigarlos con su propio flujo.
77. Como usuario en obra, quiero registrar condiciones inseguras y casi accidentes, para activar acciones preventivas.
78. Como cualquier persona en obra, quiero poder detener una actividad ante riesgo grave e inminente, para proteger vidas y bienes.
79. Como responsable de seguridad, quiero liberar formalmente una detencion por seguridad, para reanudar solo cuando el riesgo este controlado.
80. Como responsable de seguridad, quiero exigir permisos de trabajo para actividades de alto riesgo, para controlar altura, excavacion, izaje, espacios confinados, electricidad energizada y trabajo en caliente.
81. Como planificador, quiero bloquear actividades de alto riesgo sin permiso vigente, para evitar ejecucion no autorizada.
82. Como finanzas, quiero separar costo, ingreso y flujo de caja del proyecto, para distinguir rentabilidad de liquidez.
83. Como finanzas, quiero configurar metodos de facturacion por fase, para manejar anticipos, cuotas, hitos, avance, entregables o reembolso de costos mas honorarios.
84. Como director de proyecto, quiero preparar cuentas al cliente con validacion tecnica y financiera, para facturar solo ingreso facturable.
85. Como cliente, quiero aceptar cuentas desde el portal, para confirmar documentos de cobro cuando corresponda.
86. Como finanzas, quiero manejar anticipo del cliente, amortizacion y retencion del cliente, para controlar saldos por cobrar.
87. Como finanzas, quiero separar retenciones fiscales de retenciones contractuales, para aplicar reglas legales y de cumplimiento distintas.
88. Como finanzas, quiero calcular costo final proyectado y utilidad proyectada, para detectar desviaciones antes del cierre.
89. Como responsable de partida, quiero proponer actualizaciones de pronostico, para reflejar costo estimado para terminar.
90. Como director de proyecto, quiero aprobar actualizaciones de pronostico, para mantener control sobre utilidad esperada.
91. Como direccion, quiero configurar umbrales de control, para activar alertas por costo, consumo, plazo, calidad, compras, consultas, caja o utilidad.
92. Como responsable asignado, quiero gestionar alertas con fecha limite y cierre, para que no sean simples notificaciones.
93. Como direccion, quiero que alertas vencidas escalen automaticamente, para no perder asuntos criticos.
94. Como finanzas, quiero realizar cierres mensuales de proyecto, para congelar avance, costos, compromisos, ingresos, utilidad, caja y variaciones.
95. Como director de proyecto, quiero aprobar cierres mensuales junto con finanzas, para publicar solo informacion conciliada.
96. Como finanzas, quiero registrar ajustes posteriores al cierre, para corregir sin reescribir fotografias historicas.
97. Como finanzas, quiero exportar informacion contable, para alimentar contabilidad externa sin integracion directa en V1.
98. Como direccion, quiero ver un tablero de cartera, para monitorear costo, plazo, calidad, seguridad, caja, utilidad, decisiones y carga del equipo.
99. Como direccion, quiero que la salud del proyecto use la peor dimension critica, para que un problema grave no quede oculto por promedios.
100. Como direccion, quiero agregar una evaluacion directiva separada, para aportar contexto sin alterar la salud calculada.
101. Como director de proyecto, quiero generar reporte semanal interno, para revisar avance, costos, riesgos, productividad, problemas y acciones.
102. Como cliente, quiero recibir reporte semanal del cliente, para conocer avance, hitos, evidencia, decisiones requeridas, cambios y proximos pasos.
103. Como director de proyecto, quiero que reportes publicados queden congelados, para conservar lo comunicado en cada fecha.
104. Como director de proyecto, quiero emitir fe de erratas, para corregir reportes sin modificar la version original.
105. Como director de proyecto, quiero registrar decisiones requeridas, para documentar opciones, recomendacion, responsable, fecha limite e impacto.
106. Como director de proyecto, quiero registrar atrasos por decision pendiente, para sustentar impacto sin cambiar automaticamente el cronograma.
107. Como cliente, quiero acceder solo al expediente del cliente, para recibir documentos, avances, cambios, actas, garantias y entregables sin informacion reservada.
108. Como RS Ingenieria, quiero exportar un proyecto completo en formatos abiertos, para conservar portabilidad y continuidad sin depender del sistema.
109. Como administrador, quiero configurar politica de conservacion, para mantener informacion tecnica, contractual, financiera, documental y de auditoria al menos diez anos.
110. Como auditor interno, quiero consultar registro de auditoria inalterable, para reconstruir aprobaciones, rechazos, cambios financieros y modificaciones de registros cerrados.
111. Como administrador, quiero registrar datos contractuales operativos, para controlar contratos sin implementar gestion legal completa en V1.
112. Como usuario autorizado, quiero usar aceptacion electronica simple, para aprobar, rechazar o dar conformidad dentro del sistema.
113. Como usuario interno, quiero adjuntar evidencia externa manualmente, para respaldar registros con informacion recibida por canales auxiliares.
114. Como administrador, quiero que correo y mensajeria sean canales auxiliares, para que la fuente oficial del proyecto siga siendo el sistema.
115. Como subcontratista, quiero ver solo mis subcontratos, avances, evidencias, correcciones y estimaciones, para operar sin acceder a informacion reservada.
116. Como cliente, quiero ver solo informacion publicada y decisiones que me corresponden, para participar sin acceder a costos internos o margenes.
117. Como direccion, quiero diferenciar alcance de primera version y segunda version, para priorizar el producto sin dispersarlo.
118. Como responsable de diseno, quiero registrar modelos BIM como documentos controlados, para conservar revision y estado sin requerir visor BIM en V1.

## Implementation Decisions

- La primera version debe centrarse en el flujo operativo y financiero principal: proyectos, fases, roles, fichas de rendimiento, precios, presupuestos, subcontratos, avance pagable, estimaciones, calidad, materiales, compras, inventario, consumo, bitacora, evidencias, reportes, finanzas, cuentas al cliente, cierres mensuales, portal cliente y portal subcontratista limitado.
- El sistema debe usar Proyecto como agregado principal de trabajo. Un proyecto contiene fases opcionales, asignaciones de proyecto, documentos, presupuestos, partidas, actividades, subcontratos, compras, controles, finanzas y reportes.
- La Partida de obra debe ser la unidad economica y de calidad. Debe soportar presupuesto, subcontrato, medicion de avance, calidad, materiales, costo, estimaciones y cierre.
- La Actividad de obra debe ser la unidad temporal y espacial del cronograma. Cada actividad pertenece a una sola partida, aunque una partida pueda dividirse en multiples actividades por sector, nivel o periodo.
- El presupuesto aprobado debe ser inalterable. Cambios posteriores se gestionan por revision de presupuesto u orden de cambio, segun corresponda.
- La Ficha de rendimiento es reutilizable. Al usarla en presupuesto se genera una Ficha presupuestada historica e independiente de cambios futuros en la plantilla.
- La biblioteca de precios debe separar Precio propuesto, Precio vigente, Precio rechazado y Precio presupuestado. Los precios presupuestados conservan fuente, fecha y condiciones.
- Materiales, unidades, conversiones y sustituciones deben estar gobernados mediante aprobaciones, porque afectan presupuesto, compras, consumo y calidad.
- El avance pagable depende de inspeccion y aceptacion de calidad. Avance ejecutado no debe convertirse automaticamente en pago.
- Los checklist de calidad deben manejarse como plantillas reutilizables que generan controles versionados dentro del proyecto.
- Los puntos de espera bloquean trabajo dependiente hasta liberacion tecnica documentada.
- Las no conformidades tienen ciclo propio: registro, disposicion, correccion reportada, reinspeccion y cierre por RS Ingenieria.
- Los subcontratos pueden agrupar una o varias partidas y definir modalidad de suministro: solo mano de obra, mano de obra con materiales o mixta.
- Las estimaciones de subcontrato se calculan sobre avance pagable y no pueden exceder el monto contractual vigente.
- Anticipos, amortizaciones y retenciones de subcontrato son condiciones configurables por subcontrato.
- Las compras nacen de solicitudes vinculadas a partidas. Una orden de compra puede consolidar solicitudes de varios proyectos, manteniendo lineas con proyecto, partida y ubicacion.
- La politica de compras debe ser configurable por rango de monto, cantidad de cotizaciones y niveles de aprobacion.
- La adjudicacion de compra puede no elegir el menor precio, pero debe justificar costo total, plazo, calidad, disponibilidad, garantia, condiciones de pago o desempeno previo.
- El inventario debe manejar ubicaciones dentro de proyecto, transferencias internas y transferencias entre proyectos.
- Las transferencias entre proyectos trasladan material con costo real registrado y requieren aceptacion de responsables de ambos proyectos.
- El costo promedio ponderado sera el metodo general para valorar salidas y transferencias cuando no se requiera trazabilidad por lote.
- El consumo real se calcula desde movimientos de material, no como cifra manual. Los ajustes requieren motivo y evidencia.
- La bitacora diaria de obra es obligatoria, se cierra al final de la jornada o inicio de la siguiente y queda inalterable; correcciones posteriores se agregan como adendas.
- La evidencia fotografica debe conservar autor, fecha, procedencia y ubicacion cuando exista. Evidencia aprobada no se elimina; se invalida o reemplaza con traza.
- La primera version debe soportar registro sin conexion para procesos de campo criticos. Esta decision esta registrada en ADR-0001.
- Los conflictos de sincronizacion conservan ambas versiones hasta conciliacion autorizada. No se aplica "ultimo cambio gana".
- Seguridad se gestiona separada de calidad: incidentes, condiciones inseguras, casi accidentes, acciones preventivas, detencion por seguridad, liberacion de seguridad y permisos de trabajo.
- Actividades de alto riesgo requieren permiso vigente. Sin permiso vigente, la actividad queda bloqueada.
- El diseno en V1 sera control basico: entregables, revisiones, aprobacion tecnica, aceptacion del cliente, coordinacion e impacto sobre presupuesto y construccion.
- Modelos BIM se manejan como documentos controlados en V1. Visor, mediciones automaticas y deteccion automatica de interferencias quedan fuera.
- Documentos tecnicos deben manejar revisiones inalterables, distribucion, acuses, revision vigente para construccion y revision obsoleta.
- Consultas tecnicas, respuestas tecnicas e instrucciones de campo no modifican por si solas alcance, costo, plazo ni documentos vigentes.
- El cronograma debe separar linea base contractual, linea base operativa, pronostico e historial de reprogramaciones.
- Ampliaciones de plazo requieren orden de cambio aprobada. Reprogramaciones internas no modifican el compromiso contractual.
- Eventos de plazo no otorgan automaticamente ampliaciones; deben analizarse por calendario, criticidad, holgura y mitigacion.
- Finanzas debe separar costo del proyecto, ingreso del proyecto y flujo de caja del proyecto.
- Cuentas al cliente requieren validacion tecnica del director y validacion contractual y financiera antes de facturacion autorizada.
- Anticipo del cliente, amortizacion, retencion del cliente, retenciones fiscales e impuestos deben modelarse explicitamente.
- El sistema debe calcular costo final proyectado y utilidad proyectada usando costo incurrido, compromisos pendientes y costo estimado para terminar.
- Las actualizaciones de pronostico requieren propuesta del responsable y aprobacion del director, con revision financiera adicional sobre umbrales.
- Cierres mensuales congelan avance, costos, compromisos, ingresos, utilidad, flujo de caja, alertas y variaciones. Ajustes posteriores no reescriben cierres.
- En V1 se entregara exportacion contable configurable, no integracion contable directa. Esta decision esta registrada en ADR-0002.
- El tablero de cartera debe mostrar salud de costo, plazo, calidad, seguridad, flujo de caja, utilidad proyectada, decisiones pendientes y carga del equipo con trazabilidad al origen.
- La salud del proyecto se calcula por la dimension critica mas desfavorable, no por promedio. Direccion puede agregar evaluacion directiva separada, sin alterar el indicador.
- Reportes semanales internos y del cliente salen de los mismos datos, pero con contenido distinto. Los reportes publicados quedan congelados.
- El portal del cliente permite revisar entregables, aprobar ordenes de cambio, aceptar cuentas, consultar avance publicado y descargar documentos, sin ver costos internos, margenes, evaluaciones ni informacion reservada.
- El portal del subcontratista permite operar solo sobre subcontratos propios: reportar avance, correcciones, personal, evidencias y estimaciones sujetas a validacion.
- La fuente oficial del proyecto es el sistema. Correo y mensajeria son canales auxiliares.
- V1 permite evidencia externa manual. Importacion automatica de correos o mensajes queda para V2.
- Datos contractuales operativos entran en V1. Gestion legal completa, negociacion y firma electronica avanzada quedan para V2.
- La aceptacion electronica simple entra en V1 para aprobaciones, rechazos y conformidades dentro del sistema.
- El alcance inicial y las exclusiones de V2 estan registrados en ADR-0003.

## Testing Decisions

- Las pruebas deben validar comportamiento observable del negocio, no detalles internos de implementacion.
- Las pruebas principales deben organizarse alrededor de flujos completos: presupuesto aprobado, orden de cambio, avance pagable, estimacion, compra, consumo, no conformidad, bitacora, cierre mensual y reporte publicado.
- La primera gran costura de prueba debe ser el Proyecto completo, verificando que fases, roles, documentos, partidas, actividades, subcontratos, compras y finanzas se conecten sin romper invariantes.
- El flujo de presupuesto debe probar que fichas presupuestadas y precios presupuestados no cambian cuando se actualizan fichas reutilizables o biblioteca de precios.
- El flujo de orden de cambio debe probar aprobacion interna y del cliente, impacto en presupuesto vigente y conservacion de linea base.
- El flujo de calidad debe probar que avance ejecutado no genera avance pagable hasta aceptacion, que la aceptacion parcial funciona y que no conformidades bloquean pago de cantidades afectadas.
- El flujo de punto de espera debe probar bloqueo de actividades dependientes hasta liberacion tecnica.
- El flujo de subcontrato debe probar modalidad de suministro, monto contractual vigente, anticipo, amortizacion, retencion, estimaciones y cierre.
- El flujo de materiales debe probar recepcion, entrega a actividad, transferencia interna, transferencia entre proyectos, costo promedio ponderado, existencia, consumo real, consumo teorico y desviacion.
- El flujo de compras debe probar solicitudes, cotizaciones, politica de compras, adjudicacion justificada y orden de compra consolidada por lineas.
- El flujo offline debe probar captura local, sincronizacion posterior, conservacion de autoria y fecha, conflicto de sincronizacion y conciliacion sin perdida de versiones.
- El flujo documental debe probar revisiones, revision vigente para construccion, obsolescencia, distribucion documental y acuse.
- El flujo de diseno debe probar entregables, aprobacion tecnica, aceptacion del cliente, rondas de revision, comentarios tardios e impacto de revision.
- El flujo de plazo debe probar linea base contractual, linea base operativa, reprogramacion interna, evento de plazo, impacto de plazo y ampliacion por orden de cambio.
- El flujo financiero debe probar costo, ingreso, flujo de caja, cuenta al cliente, facturacion autorizada, anticipo del cliente, retencion del cliente, retencion fiscal, costo final proyectado y utilidad proyectada.
- El flujo de cierre mensual debe probar doble aprobacion, congelamiento del cierre y ajustes posteriores sin reescritura.
- El flujo de reportes debe probar versiones internas y del cliente, exclusion de informacion reservada y congelamiento de reportes publicados.
- El flujo de portales debe probar permisos por asignacion de proyecto, visibilidad limitada de cliente y subcontratista, y ausencia de informacion reservada.
- El registro de auditoria debe probar que aprobaciones, rechazos, cambios financieros y modificaciones de registros cerrados quedan inalterables.
- Las pruebas de exportacion deben validar que exportacion de proyecto, expediente del cliente y exportacion contable contienen lo que corresponde y excluyen lo reservado.

## Out of Scope

- Seleccion de stack de desarrollo.
- Portal del proveedor.
- Gestion de equipos y maquinaria.
- Asistencia individual diaria.
- Habilitacion de trabajadores por documentos, capacitaciones, oficio o riesgos.
- Integracion contable directa.
- Gestion legal completa de contratos.
- Firma electronica avanzada.
- Importacion automatica de correos o mensajes.
- Gestion avanzada de diseno.
- Cargas detalladas de disenadores.
- Revision grafica avanzada.
- Visor BIM.
- Mediciones automaticas BIM.
- Deteccion automatica de interferencias BIM.
- Mantenimiento, combustible, telemetria o costos detallados de maquinaria.
- Redaccion, negociacion y firma avanzada de documentos legales.
- Automatizacion completa de mensajeria externa.

## Further Notes

- Este PRD usa la terminologia del `CONTEXT.md` como lenguaje canonico del dominio.
- Las decisiones de producto registradas en ADR deben respetarse durante el diseno tecnico: operacion de campo sin conexion, exportacion contable antes de integracion directa y alcance inicial centrado en control integral de proyecto.
- El producto debe evitar automatismos peligrosos: no actualizar presupuestos aprobados por cambios de fichas, no pagar avance sin calidad, no modificar plazo contractual sin orden de cambio, no sobrescribir conflictos offline y no ocultar problemas criticos mediante promedios.
- La marca RS Ingenieria comunica orden, respaldo tecnico, comunicacion y calidad; el sistema debe reforzar esos atributos mediante trazabilidad, evidencia, claridad financiera y reportes profesionales.
- La V1 debe ser suficientemente completa para operar proyectos reales, pero disciplinada en sus exclusiones para no dispersar el desarrollo antes de validar el nucleo.
