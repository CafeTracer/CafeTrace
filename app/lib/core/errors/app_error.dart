/// Jerarquía de errores del dominio.
/// Permite manejar errores sin depender de Dio ni de detalles de infraestructura.
sealed class AppError {
  final String message;
  const AppError(this.message);
}

/// Error de red: sin conexión, timeout, DNS
class NetworkError extends AppError {
  const NetworkError([super.message = 'Sin conexión. Verifica tu red.']);
}

/// Error 401: token inválido o expirado
class UnauthorizedError extends AppError {
  const UnauthorizedError([super.message = 'Sesión expirada. Inicia sesión nuevamente.']);
}

/// Error 403: rol insuficiente
class ForbiddenError extends AppError {
  const ForbiddenError([super.message = 'No tienes permiso para realizar esta acción.']);
}

/// Error 404: recurso no encontrado
class NotFoundError extends AppError {
  const NotFoundError([super.message = 'El recurso solicitado no existe.']);
}

/// Error 409: conflicto (ej. código de lote duplicado)
class ConflictError extends AppError {
  const ConflictError([super.message = 'Ya existe un registro con ese dato.']);
}

/// Error 400/422: datos inválidos del servidor
class ValidationError extends AppError {
  final Map<String, List<String>>? fieldErrors;
  const ValidationError(super.message, {this.fieldErrors});
}

/// Error del servidor (5xx)
class ServerError extends AppError {
  const ServerError([super.message = 'Error del servidor. Intenta más tarde.']);
}

/// Error inesperado
class UnknownError extends AppError {
  const UnknownError([super.message = 'Ocurrió un error inesperado.']);
}
