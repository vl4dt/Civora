# Autenticacion interna

Civora usa sesiones seguras de Phoenix con correo electronico y contrasena para
usuarios internos de RS Ingenieria. No existe registro publico.

## Crear un usuario

Con la base de datos disponible, ejecuta:

```powershell
mix civora.accounts.create_user usuario@rsingenieria.com "una-clave-de-al-menos-12-caracteres"
```

El comando confirma la cuenta inmediatamente y nunca imprime la contrasena. En
staging debe ejecutarse desde un entorno con acceso a la misma base de datos,
definiendo `DATABASE_URL` y `SECRET_KEY_BASE` como en Render.

La administracion de cuentas desde la aplicacion corresponde a RS-17.

## Recuperacion de acceso

La pantalla de inicio de sesion permite solicitar un enlace de acceso por
correo. En desarrollo, los mensajes se consultan en `/dev/mailbox`.

Antes del piloto debe configurarse un adaptador de correo transaccional en
produccion. Mientras no exista ese proveedor, el flujo queda implementado y
probado, pero Render no puede entregar los enlaces al usuario.

## Superficie protegida

- `/` requiere una sesion autenticada.
- `/users/settings` requiere autenticacion y reautenticacion para cambios
  sensibles.
- `/users/log-in` y los enlaces temporales son publicos.
- `/health` permanece publico para las comprobaciones de Render.
