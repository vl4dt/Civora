# Cloudflare R2 para evidencias y documentos

El MVP almacenara evidencias y documentos en Cloudflare R2, manteniendo en PostgreSQL solo los metadatos, relaciones, estados y trazabilidad de cada archivo. Se elige R2 por su compatibilidad con S3, costo operativo favorable y capacidad de escalar el manejo de fotografias, PDFs y adjuntos sin guardar binarios dentro de la base de datos.
