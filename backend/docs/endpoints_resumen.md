# Resumen de endpoints

## Auth
- POST `/api/v1/auth/login`
- GET `/api/v1/auth/me`

## Catálogos
- GET `/api/v1/catalogos/{catalogo}`
- POST `/api/v1/catalogos/roles`
- POST `/api/v1/catalogos/departamentos`
- POST `/api/v1/catalogos/municipios`
- POST `/api/v1/catalogos/variedades`
- POST `/api/v1/catalogos/estados-lote`
- POST `/api/v1/catalogos/tipos-actividad`
- POST `/api/v1/catalogos/unidades-medida`
- POST `/api/v1/catalogos/variables`

## Usuarios
- GET `/api/v1/usuarios`
- POST `/api/v1/usuarios`
- PUT `/api/v1/usuarios/{id_usuario}`
- DELETE `/api/v1/usuarios/{id_usuario}`

## Fincas
- GET `/api/v1/fincas`
- POST `/api/v1/fincas`
- PUT `/api/v1/fincas/{id_finca}`
- DELETE `/api/v1/fincas/{id_finca}`

## Lotes
- GET `/api/v1/lotes`
- GET `/api/v1/lotes/{id_lote}`
- POST `/api/v1/lotes`
- PUT `/api/v1/lotes/{id_lote}`
- DELETE `/api/v1/lotes/{id_lote}`

## Registros
- GET `/api/v1/registros`
- POST `/api/v1/registros`
- PUT `/api/v1/registros/{id_registro}`
- DELETE `/api/v1/registros/{id_registro}`
- POST `/api/v1/registros/lotes/{id_lote}`

## Alertas
- GET `/api/v1/alertas`
- PATCH `/api/v1/alertas/{id_alerta}/atender`
