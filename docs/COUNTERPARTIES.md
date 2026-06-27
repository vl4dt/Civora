# Contrapartes

RS-24 introduce la identidad global de una persona o empresa externa antes de vincularla a un proyecto.

- `counterparties` conserva nombre, rol y contacto opcional.
- Los roles canonicos del MVP son proveedor, subcontratista y ambos.
- El contacto es texto libre opcional para una persona, telefono o correo operativo.
- Las contrapartes son globales y visibles para usuarios autenticados porque representan una identidad comercial compartida entre proyectos.
- `counterparties.id` es la identidad estable usada por los subcontratos. Solo los roles `subcontratista` y `ambos` son elegibles para esa relacion.

No se modelan todavia datos fiscales, elegibilidad, evaluaciones ni historial. Esos conceptos permanecen fuera del alcance de RS-24.
