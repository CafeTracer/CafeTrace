# Arquitectura del repositorio

## Enfoque elegido
Se usa una mezcla ligera de **Vertical Slice** y **Arquitectura Hexagonal**:

- **Vertical Slice**: cada módulo tiene sus propios archivos de entrada, reglas y acceso a datos.
- **Hexagonal ligera**: el núcleo transversal vive en `app/core` y `app/db`, mientras que los módulos encapsulan sus casos de uso.

## Módulos
- `auth`: autenticación JWT.
- `catalogos`: tablas maestras.
- `usuarios`: gestión de usuarios y roles.
- `fincas`: gestión de fincas.
- `lotes`: gestión de lotes y estado derivado.
- `registros`: historial de postcosecha y detalles de variables.
- `alertas`: atención y consulta de alertas.

## Reglas importantes
1. El estado del lote **no se guarda duplicado** en `lote`.
2. Las alertas apuntan al `registro_variable_detalle`.
3. Los módulos de escritura están delimitados por rol.
4. El endpoint batch de registros está pensado para futuros payloads JSON.
