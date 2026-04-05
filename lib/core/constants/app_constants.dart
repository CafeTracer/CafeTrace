/// Centraliza todas las constantes de la aplicación.
/// Para cambiar entre desarrollo y producción, solo modificar [baseUrl].
class AppConstants {
  AppConstants._();

  // ── Entorno ──────────────────────────────────────────────────────────────
  static const String baseUrl = 'http://10.0.2.2:8000';
  // En producción usar: 'https://{elastic-ip-ec2}'
  // 10.0.2.2 es localhost del host cuando se usa emulador Android
  static const bool useMockRepositories = true;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ── Secure Storage keys ──────────────────────────────────────────────────
  static const String jwtTokenKey = 'jwt_token';
  static const String userDataKey = 'user_data';

  // ── Endpoints ────────────────────────────────────────────────────────────
  static const String loginEndpoint = '/auth/login';
  static const String usuariosEndpoint = '/usuarios';
  static const String fincasEndpoint = '/fincas';
  static const String lotesEndpoint = '/lotes';
  static const String registrosEndpoint = '/registros';
  static const String reporteEndpoint = '/reporte';

  // ── Paginación ───────────────────────────────────────────────────────────
  static const int pageSize = 20;

  // ── UI ───────────────────────────────────────────────────────────────────
  static const String appName = 'CaféTrace';
  static const String appTagline = 'Trazabilidad postcosecha';
}
