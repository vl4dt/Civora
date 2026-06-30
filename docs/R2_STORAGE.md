# Almacenamiento en Cloudflare R2

Civora almacena binarios privados en Cloudflare R2 y conserva en PostgreSQL
solo metadatos, relaciones, estados y trazabilidad. La integracion usa la API
compatible con S3 mediante `Civora.Storage`.

## Variables

| Variable | Ejemplo | Descripcion |
| --- | --- | --- |
| `R2_ENDPOINT` | `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` | Endpoint S3 de la cuenta. |
| `R2_BUCKET` | `civora-staging` | Bucket privado de Civora. |
| `R2_ACCESS_KEY_ID` | secreto | Access Key ID del token R2. |
| `R2_SECRET_ACCESS_KEY` | secreto | Secret Access Key del token R2. |

La region S3 se configura como `auto`, segun el requisito de Cloudflare R2.
El adaptador R2 devuelve `{:error, {:not_configured, variables}}` mientras falte
alguna variable, sin intentar conectarse a AWS u otro proveedor. La frontera
`Civora.Storage` usa R2 cuando esta configurado y cae a almacenamiento local
cuando R2 sigue diferido.

## Crear recursos

1. En Cloudflare, abrir **Storage & databases > R2 > Overview**.
2. Crear un bucket privado para el ambiente, por ejemplo `civora-staging`.
3. Abrir **Manage in API Tokens** y crear un token con permiso
   **Object Read & Write**, limitado al bucket de Civora.
4. Guardar el Access Key ID y Secret Access Key; Cloudflare no vuelve a mostrar
   el secreto.
5. Copiar el endpoint S3 mostrado por Cloudflare.
6. En Render, abrir `civora-staging > Environment`, definir las cuatro variables
   y desplegar la ultima revision de `main`.

No guardar credenciales R2 en Git, archivos `.env` versionados, Linear ni
mensajes de revision.

## API base

```elixir
:ok =
  Civora.Storage.put_object("evidence/project-123/photo.jpg", jpeg,
    content_type: "image/jpeg"
  )

{:ok, jpeg} = Civora.Storage.get_object("evidence/project-123/photo.jpg")
```

La carga funcional desde navegador y los metadatos de evidencia se implementan
desde RS-34. Las URLs temporales de descarga siguen fuera del alcance basico.

## Respaldo local temporal

Mientras R2 no tenga credenciales, `Civora.Storage.Local` guarda los binarios en
`LOCAL_STORAGE_ROOT`, o `priv/storage` si la variable no existe. Esto permite
validar RS-34 en local y staging, pero en Render el filesystem es efimero y no
debe considerarse retencion documental.
