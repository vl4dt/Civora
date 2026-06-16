# Gestion de Proyectos de Arquitectura y Construccion

Este contexto define el lenguaje del sistema que organiza el trabajo de RS Ingenieria desde la contratacion hasta el cierre de los proyectos.

## Language

**Proyecto**:
Acuerdo principal con un cliente para prestar uno o varios servicios, organizado en fases opcionales como diseno, presupuesto, planificacion, construccion, supervision y cierre.
_Avoid_: Obra, contrato

**Fase del proyecto**:
Parte contratada del proyecto que agrupa trabajo con un proposito y alcance definidos. Una fase puede existir sin que el proyecto incluya las demas.
_Avoid_: Etapa, modulo

**Control financiero del proyecto**:
Seguimiento consolidado del presupuesto, los compromisos, los costos reales y el resultado financiero del proyecto, construido a partir del control detallado de sus unidades de trabajo.

**Control financiero de unidad de trabajo**:
Seguimiento del presupuesto y los costos reales asociados a una unidad ejecutable, incluyendo materiales y mano de obra subcontratada.

**Partida de obra**:
Unidad comun para presupuestar, contratar, medir el avance y controlar la calidad de un trabajo de construccion.
_Avoid_: Actividad, renglon, tarea

**Subcontrato**:
Acuerdo para ejecutar la mano de obra de una o varias partidas de obra bajo condiciones de alcance, precio y pago definidas.
_Avoid_: Partida, proveedor

**Modalidad de suministro**:
Distribucion de la responsabilidad por la mano de obra y los materiales de un subcontrato. Puede ser solo mano de obra, mano de obra con materiales o mixta con aportes definidos para cada parte.
_Avoid_: Tipo de contrato

**Ficha de rendimiento**:
Plantilla reutilizable que define los recursos y cantidades normalmente requeridos para producir una unidad de una partida de obra, incluyendo materiales, mano de obra y desperdicio previsto.
_Avoid_: Partida, ficha de presupuesto

**Ficha presupuestada**:
Copia de una ficha de rendimiento incorporada a un presupuesto, cuyos recursos, cantidades y precios pueden ajustarse para ese proyecto sin depender de cambios posteriores en la plantilla original.
_Avoid_: Ficha de rendimiento

**Presupuesto aprobado**:
Version del presupuesto aceptada como referencia comercial y financiera del proyecto. Permanece inalterable despues de su aprobacion.

**Revision de presupuesto**:
Nueva version trazable de un presupuesto que conserva la version anterior y documenta los cambios realizados despues de su aprobacion.
_Avoid_: Edicion de presupuesto

**Orden de cambio**:
Solicitud trazable para agregar, modificar o eliminar alcance durante la construccion, con impacto identificado en costo y plazo. Solo modifica el presupuesto vigente cuando es aprobada.
_Avoid_: Revision de presupuesto, trabajo extra

**Linea base del presupuesto**:
Presupuesto aprobado que sirve como referencia inalterable para comparar ordenes de cambio, costos reales y resultado financiero.
_Avoid_: Presupuesto vigente

**Aprobacion de orden de cambio**:
Autorizacion conjunta que requiere validacion tecnica y financiera de RS Ingenieria y aceptacion del cliente antes de ejecutar o incorporar una orden de cambio.

**Cambio de emergencia**:
Trabajo inmediato no aprobado previamente que resulta indispensable para proteger vidas, evitar danos a la obra o a terceros, o impedir una perdida material mayor. Requiere evidencia, costo estimado, responsable y notificacion al cliente el mismo dia.
_Avoid_: Trabajo urgente, cambio verbal

**Avance ejecutado**:
Cantidad de trabajo que el subcontratista reporta o que se constata fisicamente como realizada en una partida de obra, aun cuando no haya superado el control de calidad.
_Avoid_: Avance pagable

**Avance pagable**:
Cantidad del avance ejecutado que fue inspeccionada y aceptada conforme a los criterios de calidad, y que puede incluirse en un pago al subcontratista.
_Avoid_: Avance ejecutado

**Aceptacion parcial**:
Aprobacion de una cantidad y ubicacion especificas del avance ejecutado de una partida, sin requerir que toda la partida este terminada o aceptada.
_Avoid_: Cierre de partida

**No conformidad**:
Registro formal de trabajo que incumple los criterios de calidad de una partida, identificado por ubicacion, defecto, evidencia, responsable, fecha limite y disposicion. La cantidad afectada permanece no pagable hasta su cierre.
_Avoid_: Observacion, pendiente

**Disposicion de no conformidad**:
Resolucion definida para una no conformidad, que puede exigir corregir, rehacer o aceptar excepcionalmente el trabajo observado.

**Correccion reportada**:
Declaracion del subcontratista de que atendio una no conformidad y que el trabajo esta listo para una nueva inspeccion. No constituye aceptacion ni cierre.

**Cierre de no conformidad**:
Aceptacion emitida por el responsable tecnico de RS Ingenieria despues de reinspeccionar y documentar la correccion. Una aceptacion excepcional requiere ademas las autorizaciones correspondientes.

**Plantilla de control de calidad**:
Lista reutilizable de criterios de inspeccion asociada a un tipo de partida y a un momento de control, como preinicio, ejecucion, antes de ocultar trabajos o recepcion final.
_Avoid_: Inspeccion, checklist ejecutado

**Control de calidad del proyecto**:
Copia versionada de una plantilla de control de calidad asignada a una partida del proyecto. Conserva sus criterios aunque la plantilla original cambie posteriormente.
_Avoid_: Plantilla de control de calidad

**Punto de espera**:
Control obligatorio que impide continuar, cubrir o iniciar trabajo dependiente hasta que el responsable tecnico lo inspeccione y libere con evidencia.
_Avoid_: Inspeccion informativa

**Liberacion de punto de espera**:
Autorizacion tecnica documentada que permite continuar el trabajo bloqueado por un punto de espera.

**Actividad de obra**:
Unidad temporal y espacial usada para programar la ejecucion de una parte de una partida de obra. Una partida puede distribuirse en varias actividades por sector, nivel o periodo.
_Avoid_: Partida de obra, tarea

**Dependencia de actividades**:
Relacion que condiciona el inicio o finalizacion de una actividad de obra al progreso, terminacion o liberacion de otra.

**Asignacion de actividad**:
Vinculo exclusivo entre una actividad de obra y una sola partida. Las actividades de diferentes partidas permanecen separadas aunque compartan ubicacion o periodo.

**Metodo de medicion de avance**:
Forma definida para cuantificar el progreso de una partida mediante cantidad fisica o hitos ponderados. Se fija antes de registrar avances y permanece estable durante su ejecucion.

**Hito ponderado**:
Resultado verificable al que se asigna una proporcion del avance total de una partida cuando esta no se mide adecuadamente por unidades fisicas.
_Avoid_: Porcentaje estimado

**Acreditacion de hito**:
Reconocimiento completo del peso de un hito despues de verificar y aprobar su resultado. Un hito no admite acreditacion parcial y el conjunto de hitos de una partida debe sumar exactamente cien por ciento.

**Consumo teorico**:
Cantidad de material esperada para el avance ejecutado de una actividad o partida, calculada a partir de su ficha presupuestada.
_Avoid_: Material entregado, consumo real

**Consumo real**:
Cantidad de material efectivamente utilizada en una actividad o sector, independiente de la cantidad entregada o asignada.
_Avoid_: Material entregado, consumo teorico

**Desviacion de material**:
Diferencia entre el consumo real y el consumo teorico de un material para una actividad, sector o partida.
_Avoid_: Desperdicio

**Desperdicio de material**:
Cantidad identificada de material que no queda incorporada al trabajo ejecutado ni se devuelve para otro uso.
_Avoid_: Desviacion de material

**Movimiento de material**:
Registro trazable de entrada, entrega, devolucion, transferencia o ajuste que modifica la existencia de un material en una ubicacion del proyecto.

**Ajuste de material**:
Correccion autorizada de una existencia que requiere motivo y evidencia cuando los movimientos registrados no coinciden con la cantidad fisica.
_Avoid_: Consumo manual

**Existencia de material**:
Cantidad disponible de un material en una ubicacion, determinada por su existencia inicial y el historial de movimientos.
_Avoid_: Consumo real

**Ubicacion de material**:
Lugar controlado donde se mantiene existencia de materiales, como una bodega o un frente de trabajo dentro de un proyecto.

**Transferencia interna de material**:
Movimiento de material entre ubicaciones del mismo proyecto que conserva su asignacion financiera.

**Transferencia entre proyectos**:
Movimiento trazable que retira material y costo de un proyecto para reasignarlos a otro.
_Avoid_: Transferencia interna de material

**Costo de transferencia**:
Costo real registrado que acompana al material transferido entre proyectos, reduciendo el costo del proyecto de origen y aumentando el del receptor. Requiere aceptacion de los responsables de ambos proyectos.
_Avoid_: Precio presupuestado, precio actual

**Costo promedio ponderado**:
Valor unitario de existencia calculado a partir del costo y la cantidad disponible de un material en un proyecto y ubicacion. Se utiliza para valorar salidas y transferencias cuando no se exige seguimiento por lote.

**Lote de material**:
Conjunto identificable de material cuya procedencia o caracteristicas deben conservarse por requisitos tecnicos, de calidad o garantia.

**Recepcion de material**:
Ingreso confirmado de material a una ubicacion del proyecto, incluso cuando la entrega del proveedor ocurre directamente en un frente de trabajo.
_Avoid_: Compra, consumo

**Entrega de material a actividad**:
Salida de una ubicacion que asigna material a una actividad y responsable determinados. Puede capturarse junto con una recepcion directa, pero conserva un movimiento separado.
_Avoid_: Recepcion de material

**Solicitud de compra**:
Peticion trazable de materiales requeridos por una o varias partidas, sustentada en existencias, consumo pendiente y cantidad teorica restante. Las cantidades adicionales requieren una justificacion.
_Avoid_: Orden de compra, compra

**Compra de emergencia**:
Compra realizada sin solicitud previamente aprobada para atender una emergencia documentada, sujeta a regularizacion y autorizacion posterior.
_Avoid_: Compra directa

**Orden de compra**:
Compromiso de compra emitido a un proveedor que puede consolidar solicitudes de varios proyectos. Cada linea conserva el proyecto, la partida y la ubicacion de destino para distribuir costo y recepcion.
_Avoid_: Solicitud de compra

**Linea de compra**:
Asignacion de una cantidad y costo de material a un proyecto, partida y ubicacion de destino dentro de una orden de compra consolidada.

**Politica de compras**:
Reglas configurables por rango de monto que determinan la cantidad de cotizaciones y los niveles de aprobacion requeridos antes de emitir una orden de compra.

**Cotizacion de proveedor**:
Oferta recibida de un proveedor para atender total o parcialmente una necesidad de compra bajo precios, condiciones y vigencia definidos.

**Adjudicacion de compra**:
Seleccion justificada de una cotizacion considerando costo total, plazo, calidad, disponibilidad, garantia, condiciones de pago y desempeno previo. No requiere elegir automaticamente el menor precio.
_Avoid_: Cotizacion mas barata

**Contraparte**:
Persona o empresa externa que puede actuar como proveedor de materiales, subcontratista o ambos, compartiendo una identidad comercial y fiscal unica.
_Avoid_: Proveedor, subcontratista

**Rol de contraparte**:
Forma en que una contraparte participa en una relacion concreta con RS Ingenieria, ya sea como proveedor o como subcontratista.

**Evaluacion de subcontratista**:
Valoracion realizada al cierre de cada subcontrato sobre calidad, plazo, productividad, seguridad, orden, documentacion y respuesta a no conformidades. Combina resultados medibles con la apreciacion documentada del responsable tecnico.

**Historial de subcontratista**:
Conjunto de evaluaciones y resultados acumulados por una contraparte en su rol de subcontratista.

**Elegibilidad de contraparte**:
Estado que determina si una contraparte puede recibir nuevas adjudicaciones. Puede estar habilitada, condicionada a justificacion y aprobacion especial, o bloqueada hasta su rehabilitacion.
_Avoid_: Calificacion

**Plan de mejora de contraparte**:
Compromiso aprobado que identifica causas, acciones, responsables, plazos y evidencias requeridas para corregir un desempeno deficiente.

**Rehabilitacion de contraparte**:
Decision de direccion que restablece la elegibilidad despues de verificar el cumplimiento de un plan de mejora. No ocurre automaticamente por el paso del tiempo.

**Estimacion de subcontrato**:
Solicitud periodica y acumulativa de pago basada en avance pagable, que considera deducciones, anticipos amortizados, retenciones, pagos anteriores y saldo.
_Avoid_: Avance ejecutado, factura

**Monto contractual vigente**:
Valor maximo pagable de un subcontrato compuesto por su monto original y las ordenes de cambio aprobadas que le correspondan.
_Avoid_: Presupuesto de partida

**Anticipo de subcontrato**:
Pago inicial sujeto a las condiciones definidas en un subcontrato y recuperado mediante una amortizacion proporcional o programada.

**Retencion de subcontrato**:
Porcion descontada de cada estimacion como garantia de cumplimiento, cuya tasa y condiciones de liberacion se establecen en el subcontrato.

**Amortizacion de anticipo**:
Recuperacion del anticipo mediante deducciones aplicadas a las estimaciones segun el metodo definido en el subcontrato.

**Liberacion de retencion**:
Pago total o parcial de la retencion al cumplirse condiciones verificables definidas en el subcontrato, como la recepcion de los trabajos o el fin de la garantia sin pendientes.
_Avoid_: Pago automatico por fecha

**Cierre de subcontrato**:
Confirmacion de que el alcance contratado fue terminado y aceptado, las no conformidades fueron cerradas, la estimacion final fue conciliada, los bienes fueron devueltos, los documentos y garantias fueron entregados y la evaluacion fue completada.
_Avoid_: Cierre de partida, fin de garantia

**Cierre de partida**:
Confirmacion tecnica y financiera de que todo el alcance de una partida fue ejecutado, aceptado y conciliado. Puede ocurrir mientras sus garantias permanecen vigentes.
_Avoid_: Cierre de subcontrato, fin de garantia

**Garantia vigente**:
Obligacion posterior al cierre tecnico que permanece activa durante el plazo acordado y conserva responsables, cobertura y vencimiento.

**Proyecto cerrado**:
Proyecto cuyo alcance fue entregado, sus costos e ingresos fueron conciliados y su expediente de cierre esta completo, aunque puedan permanecer garantias vigentes.
_Avoid_: Proyecto archivado

**Proyecto en garantia**:
Periodo posterior al cierre durante el cual se gestionan exclusivamente reclamos y obligaciones de garantia.
_Avoid_: Proyecto activo

**Proyecto archivado**:
Proyecto cerrado sin garantias ni responsabilidades pendientes, conservado como historial definitivo.

**Plantilla de expediente de cierre**:
Conjunto reutilizable de documentos y evidencias requeridos segun el tipo de proyecto, sus fases y alcance contratado.

**Expediente de cierre**:
Conjunto aplicable de documentos y evidencias que acredita la entrega tecnica, contractual, financiera y documental de un proyecto.
_Avoid_: Carpeta de archivos

**Documento tecnico**:
Documento controlado del proyecto identificado por codigo y disciplina, con autor, revisor, estado e historial de revisiones.

**Revision documental**:
Version inalterable de un documento tecnico emitida en una fecha y por un motivo determinados. Las revisiones anteriores se conservan aunque dejen de estar vigentes.

**Revision vigente para construccion**:
Unica revision aprobada de un documento tecnico que esta autorizada para ejecutar trabajos en obra.
_Avoid_: Ultimo archivo cargado

**Distribucion documental**:
Entrega controlada de una revision a los responsables afectados, con registro de destinatarios, fecha de envio y acuse de recepcion.

**Revision obsoleta**:
Revision reemplazada que permanece en el historial pero no esta autorizada para ejecutar trabajos.

**Acuse documental**:
Confirmacion de que un destinatario recibio y reconoce la revision distribuida, sin que ello sustituya su aprobacion tecnica.

**Consulta tecnica**:
Solicitud formal de aclaracion sobre documentos o condiciones de obra, vinculada a una ubicacion, responsables, fecha limite y respuesta aprobada.
_Avoid_: Mensaje, instruccion verbal

**Respuesta tecnica**:
Aclaracion aprobada de una consulta tecnica que orienta la ejecucion pero no modifica por si sola el alcance, costo, plazo ni los documentos vigentes.

**Instruccion de campo**:
Indicacion registrada en obra que requiere confirmacion escrita antes de autorizar trabajo. Si afecta diseno, alcance, costo o plazo, debe continuar mediante el proceso formal correspondiente.
_Avoid_: Orden verbal, autorizacion de cambio

**Bitacora diaria de obra**:
Registro obligatorio de una jornada de construccion que documenta clima, recursos, actividades, cantidades, materiales, visitas, instrucciones, incidentes, restricciones y evidencia fotografica.
_Avoid_: Reporte semanal

**Adenda de bitacora**:
Correccion o informacion adicional trazable que se incorpora despues del cierre de una bitacora sin modificar su contenido original.

**Cierre de bitacora**:
Confirmacion del responsable de campo al final de la jornada o al inicio de la siguiente que vuelve inalterable la bitacora, aun cuando permanezca pendiente de revision tecnica.

**Revision de bitacora**:
Validacion posterior realizada por el responsable tecnico sobre una bitacora cerrada, sin capacidad de alterar su contenido original.

**Incidente de seguridad**:
Evento relacionado con la obra que causa o puede causar dano a personas, bienes o ambiente y requiere clasificacion, atencion, evidencia, investigacion y acciones correctivas.
_Avoid_: No conformidad

**Detencion por seguridad**:
Suspension obligatoria de las actividades afectadas por un incidente grave hasta que las condiciones sean evaluadas y liberadas formalmente.

**Liberacion de seguridad**:
Autorizacion documentada para reanudar actividades despues de verificar que los riesgos que originaron una detencion fueron controlados.

**Condicion insegura**:
Situacion observable que aumenta el riesgo de dano y requiere una accion preventiva aunque no haya ocurrido un evento.

**Casi accidente**:
Evento sin dano que tuvo el potencial de causar una lesion, perdida material o afectacion ambiental.
_Avoid_: Incidente con dano

**Accion preventiva**:
Medida asignada a un responsable y fecha limite para eliminar o reducir una condicion de riesgo antes de que produzca dano.

**Autoridad de detencion**:
Facultad de cualquier persona en obra para detener de inmediato una actividad ante un riesgo grave e inminente, sin autorizacion previa ni sancion cuando actua de buena fe.
_Avoid_: Liberacion de seguridad

**Permiso de trabajo**:
Autorizacion temporal y localizada requerida antes de ejecutar una actividad de alto riesgo, que identifica responsables, controles y equipo de seguridad. Pierde vigencia cuando cambian las condiciones autorizadas.

**Actividad de alto riesgo**:
Actividad cuya ejecucion requiere controles y autorizacion adicionales por su potencial de causar danos graves, como trabajo en altura, excavacion, izaje, espacio confinado, electricidad energizada o trabajo en caliente.

**Bloqueo por permiso**:
Impedimento para iniciar o continuar una actividad de alto riesgo cuando no existe un permiso de trabajo vigente asociado. El bloqueo se restablece si el permiso expira o es revocado.

**Entregable de diseno**:
Resultado verificable de una disciplina de diseno con responsable, fecha, revisiones, dependencias y criterios de aprobacion definidos.
_Avoid_: Porcentaje de diseno, documento tecnico

**Disciplina de diseno**:
Area tecnica responsable de producir y coordinar entregables especializados, como arquitectura, estructuras o instalaciones.

**Aprobacion tecnica de diseno**:
Confirmacion interna de RS Ingenieria de que un entregable esta completo, coordinado y apto para ser emitido. No se sustituye por la aceptacion del cliente.

**Aceptacion de diseno**:
Conformidad del cliente con un entregable emitido cuando el contrato requiere su participacion. No sustituye la aprobacion ni la responsabilidad tecnica.

**Ronda de revision**:
Periodo formal en que el cliente revisa una version congelada de uno o varios entregables y presenta comentarios dentro de una fecha limite.

**Comentario de revision**:
Observacion numerada dentro de una ronda que debe resolverse como aceptada, rechazada con fundamento o pendiente de aclaracion.

**Comentario tardio**:
Observacion recibida despues del cierre de una ronda de revision, susceptible de tratarse como cambio de alcance.

**Ronda incluida**:
Ronda de revision comprendida dentro del alcance y honorarios contratados para un entregable de diseno.

**Ronda adicional**:
Ronda no incluida en el contrato que requiere una orden de cambio, salvo cuando sea necesaria para corregir un error atribuible a RS Ingenieria.

**Correccion de diseno**:
Modificacion necesaria para subsanar un error u omision atribuible a RS Ingenieria, sin considerarse alcance adicional para el cliente.
_Avoid_: Cambio solicitado

**Clasificacion de modificacion de diseno**:
Decision justificada que determina si una modificacion es una correccion atribuible a RS Ingenieria o un cambio solicitado sujeto a orden de cambio. Requiere propuesta del director del proyecto y aprobacion de una segunda autoridad interna.

**Revision de coordinacion**:
Verificacion formal de compatibilidad entre entregables de distintas disciplinas antes de su aprobacion para construccion.

**Interferencia de diseno**:
Conflicto identificado entre disciplinas que requiere responsable, resolucion y verificacion. Una interferencia critica bloquea la emision para construccion.
_Avoid_: Comentario de revision

**Resolucion de interferencia**:
Propuesta elaborada por la disciplina responsable y validada por todas las disciplinas afectadas antes de que el coordinador de diseno cierre la interferencia.

**Origen de linea base**:
Conjunto de revisiones tecnicas utilizadas para preparar una linea base de presupuesto o cronograma.

**Impacto de revision**:
Evaluacion de las partidas, cantidades, fichas y actividades potencialmente afectadas por una nueva revision tecnica, sin modificarlas automaticamente.

**Aprobacion de impacto**:
Decision del director del proyecto basada en la evaluacion conjunta de diseno, presupuesto y construccion sobre los efectos de una nueva revision. Los impactos contractuales requieren una orden de cambio.

**Costo del proyecto**:
Valor comprometido o incurrido para ejecutar el proyecto, independiente de lo cobrado al cliente.

**Ingreso del proyecto**:
Valor contractual facturable o facturado al cliente por el alcance entregado.
_Avoid_: Cobro

**Flujo de caja del proyecto**:
Entradas y salidas reales de dinero asociadas al proyecto segun su fecha de cobro o pago.
_Avoid_: Rentabilidad

**Compromiso de costo**:
Obligacion aprobada de pago asumida mediante un subcontrato, orden de compra u otro acuerdo, aunque aun no se haya recibido ni pagado.
_Avoid_: Costo pagado

**Metodo de facturacion**:
Regla contractual que determina como se genera ingreso facturable en una fase del proyecto, mediante anticipo, cuotas, hitos, avance aprobado, entregables o reembolso de costos mas honorarios.

**Ingreso facturable**:
Valor que cumple las condiciones contractuales para solicitar pago al cliente, aunque aun no haya sido facturado ni cobrado.
_Avoid_: Ingreso facturado, cobro

**Cuenta al cliente**:
Solicitud preparada para facturacion que reune el ingreso facturable y requiere validacion tecnica del director del proyecto y validacion contractual y financiera antes de emitirse.
_Avoid_: Factura, cobro

**Facturacion autorizada**:
Cuenta al cliente que completo las revisiones internas y puede convertirse en factura o documento de cobro.

**Anticipo del cliente**:
Cobro inicial sujeto a las condiciones de una fase o contrato, cuyo saldo pendiente se reduce mediante la amortizacion acordada.

**Retencion del cliente**:
Porcion del ingreso facturado que el cliente mantiene pendiente de pago hasta que se cumplan las condiciones contractuales de liberacion.

**Amortizacion del anticipo del cliente**:
Aplicacion gradual del anticipo recibido contra cuentas posteriores segun el metodo definido en la fase o contrato.

**Costo estimado para terminar**:
Pronostico del costo adicional requerido para completar el alcance pendiente de una partida o proyecto.

**Costo final proyectado**:
Suma del costo incurrido, los compromisos pendientes y el costo estimado para terminar.

**Utilidad proyectada**:
Diferencia esperada entre el ingreso contractual vigente y el costo final proyectado del proyecto.
_Avoid_: Utilidad realizada

**Actualizacion de pronostico**:
Revision trazable del costo estimado para terminar, propuesta por el responsable de la partida y aprobada por el director del proyecto. Los cambios superiores al umbral definido requieren revision financiera adicional.

**Umbral de control**:
Limite configurable por proyecto o partida que activa una alerta al detectar una desviacion relevante de costo, consumo, plazo, calidad, compras, consultas, flujo de caja o utilidad.

**Alerta de gestion**:
Situacion activada por un umbral que requiere responsable, fecha limite, seguimiento y cierre documentado.
_Avoid_: Notificacion

**Escalamiento de alerta**:
Elevacion automatica de una alerta a una autoridad superior segun su severidad y tiempo vencido, sin liberar al responsable original de atenderla.

**Rol de trabajo**:
Conjunto general de responsabilidades que una persona puede ejercer, como direccion, diseno, presupuesto, campo, calidad, seguridad, compras o finanzas.

**Asignacion de proyecto**:
Vinculo que otorga a una persona un rol y alcance de acceso especificos dentro de un proyecto determinado.
_Avoid_: Rol global

**Participante externo**:
Cliente o contraparte autorizado a interactuar solo con la informacion y procesos que le corresponden dentro de un proyecto.

**Portal del cliente**:
Espacio limitado donde el cliente revisa entregables, aprueba ordenes de cambio, acepta cuentas, consulta avance publicado y obtiene documentos de entrega, sin acceso a costos internos, margenes ni evaluaciones.

**Portal del subcontratista**:
Espacio limitado a los subcontratos propios donde una contraparte reporta avance, correcciones, personal, evidencia y estimaciones, sujetas a validacion de RS Ingenieria.

**Portal del proveedor**:
Espacio previsto para una version posterior donde proveedores de materiales podran atender solicitudes, ordenes, entregas y documentos de cobro. No forma parte del alcance inicial.

**Registro sin conexion**:
Captura local de informacion de campo cuando no existe conectividad, pendiente de sincronizacion posterior sin perder autoria, fecha ni evidencia.

**Conflicto de sincronizacion**:
Contradiccion entre cambios realizados sin conexion y el estado vigente del proyecto que requiere una resolucion trazable.

**Conciliacion de conflicto**:
Decision autorizada que resuelve cambios concurrentes conservando ambas versiones, su autoria y sus fechas. Ningun cambio se descarta automaticamente por el orden de sincronizacion.
_Avoid_: Ultimo cambio gana

**Responsable de conciliacion**:
Autoridad funcional del proceso afectado que resuelve un conflicto de sincronizacion. Cuando el conflicto afecta informacion aprobada, la resolucion requiere una segunda autorizacion.

**Evidencia fotografica**:
Imagen vinculada a un registro del proyecto con autor, fecha y procedencia identificados. Puede capturarse directamente o importarse, y registra ubicacion cuando esta disponible.

**Fotografia importada**:
Evidencia fotografica obtenida fuera del sistema y marcada expresamente con esa procedencia.
_Avoid_: Captura directa

**Invalidacion de evidencia**:
Marca trazable que declara una evidencia como no valida o reemplazada sin eliminarla del historial, indicando motivo, responsable y fecha.
_Avoid_: Eliminacion de evidencia

**Registro de auditoria**:
Historial inalterable de aprobaciones, rechazos, cambios financieros y modificaciones de registros cerrados, con actor, fecha, motivo y estados anterior y posterior.
_Avoid_: Bitacora diaria de obra

**Politica de conservacion**:
Regla configurable que mantiene la informacion tecnica, contractual, financiera, documental y de auditoria por al menos diez anos despues del cierre del proyecto, extendiendose mientras existan garantias, reclamos u obligaciones pendientes.

**Exportacion de proyecto**:
Paquete portable con documentos originales, registros y aprobaciones en PDF, evidencias, datos tabulares en formatos abiertos e indice de contenido, utilizable sin depender del sistema.

**Expediente del cliente**:
Paquete de entrega con disenos, aprobaciones, cambios, avances publicados, actas, garantias y entregables que excluye margenes, costos internos, comparativas, evaluaciones y comunicaciones internas.
_Avoid_: Exportacion de proyecto

**Tablero de cartera**:
Vista directiva de todos los proyectos que resume costo, plazo, calidad, seguridad, flujo de caja, utilidad proyectada, decisiones pendientes y carga del equipo, con trazabilidad hasta los registros de origen.

**Salud del proyecto**:
Estado verde, amarillo o rojo determinado por la dimension critica mas desfavorable del proyecto y acompanado de su causa dominante. No se calcula mediante un promedio que pueda ocultar riesgos graves.

**Evaluacion directiva**:
Valoracion temporal y comentada emitida por direccion para aportar contexto a la salud calculada, sin modificarla ni ocultarla.

**Reporte semanal interno**:
Resumen periodico para RS Ingenieria que presenta avance, costos, riesgos, productividad, problemas y acciones del proyecto.

**Reporte semanal del cliente**:
Resumen periodico publicado al cliente con avance, hitos, evidencia, decisiones requeridas, cambios y proximos pasos, excluyendo informacion reservada.

**Reporte publicado**:
Edicion inalterable de un reporte semanal que conserva exactamente la informacion comunicada en su fecha de emision.

**Fe de erratas**:
Correccion vinculada a un reporte publicado que explica y sustituye informacion incorrecta sin modificar la edicion original.

**Decision requerida**:
Eleccion pendiente que documenta asunto, opciones, recomendacion, autoridad responsable, fecha limite e impacto de no responder.
_Avoid_: Tarea, alerta

**Atraso por decision pendiente**:
Demora documentada causada por una decision no recibida dentro del plazo, que genera alerta e impacto potencial pero no modifica automaticamente el cronograma contractual.

**Reprogramacion interna**:
Ajuste operativo de fechas y secuencias para gestionar la ejecucion sin modificar el plazo contractual aprobado.
_Avoid_: Ampliacion de plazo

**Ampliacion de plazo**:
Modificacion de la fecha contractual del proyecto autorizada mediante una orden de cambio aprobada.
_Avoid_: Reprogramacion interna

**Linea base contractual del cronograma**:
Programa aprobado que representa las fechas comprometidas con el cliente y solo cambia mediante una ampliacion de plazo.

**Linea base operativa**:
Programa interno aprobado que guia la ejecucion vigente y puede actualizarse mediante reprogramacion sin alterar el plazo contractual.

**Pronostico de cronograma**:
Fechas esperadas de terminacion calculadas con el progreso, las dependencias y las condiciones actuales.

**Historial de reprogramaciones**:
Conjunto de lineas base operativas anteriores y sus causas, conservado para explicar la evolucion del plan.

**Calendario laboral**:
Regla de tiempo aplicable a un proyecto o actividad que define jornadas, turnos, fines de semana, feriados y restricciones locales.

**Evento de plazo**:
Hecho documentado que puede afectar el programa, identificado por causa, periodo, actividades, evidencia y responsabilidad preliminar. No concede por si solo una ampliacion de plazo.

**Impacto de plazo**:
Efecto demostrado de un evento sobre las fechas del proyecto considerando calendario laboral, actividades afectadas, criticidad, holgura y mitigacion posible.
_Avoid_: Duracion del evento

**Analisis de plazo aprobado**:
Evaluacion preparada por planificacion, validada con la evidencia de construccion y autorizada por el director del proyecto antes de sustentar una reclamacion o ampliacion.

**Cuadrilla de referencia**:
Composicion de oficios y cantidad de personas prevista en una ficha de rendimiento para producir una unidad de trabajo bajo una jornada definida.

**Productividad planificada**:
Cantidad de trabajo esperada por cuadrilla y unidad de tiempo segun la ficha presupuestada.

**Productividad real**:
Relacion entre la cantidad ejecutada y aceptada y el esfuerzo de mano de obra utilizado en una actividad.

**Trabajador de subcontratista**:
Persona individual asignada por un subcontratista a un proyecto. Su control detallado de acceso, asistencia, seguridad, permisos y capacitacion esta previsto para una segunda version.

**Oficio**:
Especialidad laboral con la que participa un trabajador dentro de una cuadrilla o actividad.

**Habilitacion de trabajador**:
Validacion prevista para una segunda version que determinara si un trabajador puede ingresar o ejecutar tareas segun documentos, capacitaciones, oficio y riesgos aplicables. No forma parte del alcance inicial.

**Asistencia individual**:
Registro de entrada, salida, subcontrato y actividad de cada trabajador, previsto para una segunda version. No forma parte del alcance inicial.

**Cuadrilla reportada**:
Cantidad de personas por oficio que un subcontratista declara como presente en una actividad durante una jornada, utilizada en la primera version para analizar productividad sin asistencia individual.

**Gestion de equipos y maquinaria**:
Control de asignacion, uso, costos, mantenimiento, combustible y demas informacion de equipos y maquinaria, previsto para una segunda version. No forma parte del alcance inicial.

**Biblioteca de precios**:
Repositorio actualizable de precios de materiales y mano de obra clasificados por region, fecha y fuente, independiente de las fichas de rendimiento.

**Precio presupuestado**:
Copia del precio tomado de la biblioteca o definido manualmente para un presupuesto, conservando fecha, fuente y condiciones aunque la biblioteca cambie despues.
_Avoid_: Precio vigente

**Precio propuesto**:
Precio sugerido para la biblioteca con fuente, fecha, region y condiciones, pendiente de aprobacion antes de usarse como referencia vigente.

**Precio vigente**:
Precio aprobado dentro de la biblioteca que puede utilizarse como referencia para nuevos presupuestos.

**Precio rechazado**:
Precio propuesto que no fue aprobado para uso en presupuestos, conservado como referencia historica con su motivo de rechazo.

**Umbral de variacion de precio**:
Limite configurable por categoria que exige una aprobacion adicional o respaldo cuando un precio propuesto se aleja significativamente del precio vigente.

**Material sustituto**:
Material alternativo que puede reemplazar a otro solo bajo condiciones de compatibilidad tecnica, aprobacion y evaluacion de costo o alcance.
_Avoid_: Reemplazo automatico

**Autorizacion de sustitucion**:
Decision tecnica que permite usar un material sustituto en una partida o actividad especifica. Si afecta costo, plazo o alcance, requiere el proceso contractual correspondiente.

**Unidad base de material**:
Unidad principal usada para controlar existencia, consumo y comparacion de un material.

**Conversion de unidad**:
Relacion aprobada entre unidades de medida de un material, con fuente, vigencia y condiciones de uso.

**Importe financiero**:
Valor monetario identificado con moneda, precio antes de impuesto, impuesto aplicable, total y tipo de cambio cuando corresponda.

**Tipo de cambio aplicado**:
Tasa utilizada para convertir importes entre monedas en un documento o linea, conservada para evitar recalculos historicos.

**Retencion fiscal**:
Descuento o monto retenido por obligacion legal o tributaria, independiente de las retenciones contractuales de cumplimiento.
_Avoid_: Retencion de subcontrato, retencion del cliente

**Cierre mensual de proyecto**:
Fotografia inalterable de avance, costos, compromisos, ingresos, utilidad proyectada, flujo de caja, alertas y variaciones de un proyecto al cierre de un periodo.

**Ajuste posterior al cierre**:
Correccion registrada despues de un cierre mensual que afecta el periodo actual sin reescribir la fotografia ya publicada.

**Aprobacion de cierre mensual**:
Validacion conjunta de direccion de proyecto y finanzas antes de publicar un cierre mensual, cubriendo avance, riesgos, pronostico, costos, ingresos, compromisos, caja y diferencias criticas.

**Exportacion contable**:
Salida configurable de informacion financiera para registro contable externo, incluida en la primera version sin integracion directa con un sistema contable.

**Integracion contable**:
Conexion directa con un sistema contable externo prevista para una segunda version, una vez estabilizados los procesos financieros internos.

**Datos contractuales operativos**:
Informacion necesaria para administrar un contrato dentro del sistema, como partes, alcance, monto, fechas, condiciones de pago, retenciones, garantias, documentos adjuntos y aprobaciones.

**Gestion legal de contratos**:
Redaccion, negociacion, firma electronica avanzada y administracion juridica integral de contratos, prevista para una segunda version.

**Aceptacion electronica simple**:
Registro de aprobacion, rechazo o conformidad realizado dentro del sistema por un usuario identificado, conservando fecha, accion, comentario y contexto tecnico disponible.

**Firma electronica avanzada**:
Mecanismo formal de firma con requisitos legales reforzados, previsto para una segunda version o para integracion cuando el caso contractual lo exija.

**Canal auxiliar**:
Medio externo como correo o mensajeria usado para comunicacion o notificacion, sin sustituir los registros oficiales del sistema.
_Avoid_: Fuente oficial

**Fuente oficial del proyecto**:
Conjunto de registros formalizados dentro del sistema que gobiernan aprobaciones, cambios, consultas, no conformidades, cuentas y decisiones.

**Evidencia externa**:
Archivo, nota o referencia originada fuera del sistema y vinculada manualmente a un registro oficial para aportar contexto o respaldo.

**Importacion automatica de comunicaciones**:
Captura directa de correos o mensajes externos dentro del sistema, prevista para una segunda version por su complejidad y sensibilidad.

**Alcance de primera version**:
Conjunto inicial del sistema enfocado en proyectos, fases, roles, fichas de rendimiento, precios, presupuestos, subcontratos, avance pagable, estimaciones, calidad, materiales, compras, inventario, consumo, bitacora, evidencias, reportes, finanzas de proyecto, cuentas al cliente, cierres mensuales, portal cliente y portal subcontratista limitado.

**Alcance de segunda version**:
Evolucion posterior del sistema que incluye portal del proveedor, gestion de equipos y maquinaria, asistencia individual, habilitacion de trabajadores, integraciones contables, gestion legal de contratos, firma electronica avanzada e importacion automatica de comunicaciones.

**Control basico de diseno**:
Gestion incluida en la primera version para entregables, revisiones, aprobacion tecnica, aceptacion del cliente, coordinacion e impacto sobre presupuesto y construccion, sin cubrir produccion avanzada de diseno.

**Gestion avanzada de diseno**:
Gestion detallada de tareas de diseno, cargas de disenadores, revision grafica avanzada o modelado, prevista para una segunda version.

**Modelo BIM controlado**:
Archivo de modelo tratado como documento tecnico con revision, disciplina, responsable, estado y relacion con entregables, sin visor ni deteccion automatica de interferencias en la primera version.

**Funciones BIM avanzadas**:
Visor, mediciones automaticas y deteccion automatica de interferencias de modelos BIM, previstas para una segunda version.
