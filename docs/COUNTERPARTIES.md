# Contrapartes

RS-24 introduce la identidad global de una persona o empresa externa antes de vincularla a un proyecto.

- `counterparties` conserva nombre, rol y contacto opcional.
- Los roles canonicos del MVP son proveedor, subcontratista y ambos.
- El contacto es texto libre opcional para una persona, telefono o correo operativo.
- Las contrapartes son globales y visibles para usuarios autenticados porque representan una identidad comercial compartida entre proyectos.
- `counterparties.id` es la referencia estable que usara el subcontrato de RS-25. La asociacion, permisos por proyecto y auditoria de esa relacion pertenecen a la transaccion del subcontrato.

No se modelan todavia datos fiscales, elegibilidad, evaluaciones ni historial. Esos conceptos permanecen fuera del alcance de RS-24.
