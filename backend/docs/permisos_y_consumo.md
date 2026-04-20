# Permisos, consumo y gestión

## Roles
### Administrador
- CRUD completo en todos los recursos.
- Activa/desactiva usuarios.
- Crea catálogos.
- Puede eliminar registros o fincas si la integridad lo permite.

### Operario
- Puede consultar catálogos.
- Puede crear y editar fincas.
- Puede crear y editar lotes.
- Puede crear registros y sus detalles.
- Consulta alertas, pero no las atiende.

### Supervisor
- Consulta usuarios.
- Consulta fincas, lotes, registros y alertas.
- Atiende alertas.
- No modifica catálogos globales.

## Delimitación de consumo
- Listados generales: deben paginarse luego con `limit` y `offset`.
- Batch de registros: máximo 50 variables por operación.
- Login: se recomienda limitar por IP con Nginx o gateway.
- Lotes y registros: deben mantenerse con soft delete cuando afecten trazabilidad.

## Recomendaciones futuras
- Aplicar rate limiting.
- Agregar auditoría por tabla sensible.
- Separar endpoints CRUD de endpoints de negocio.
