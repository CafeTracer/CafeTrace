import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../models/models.dart';

// ── Auth ─────────────────────────────────────────────────────────────────────
class AuthRepositoryImpl implements AuthRepository {
  final _dio = ApiClient.instance.dio;
  final _storage = const FlutterSecureStorage();

  @override
  Future<Sesion> login({required String correo, required String password}) async {
    // Datos de prueba para testing
    if (correo == 'admin@test.com' && password == 'admin123') {
      final usuario = Usuario(
        id: 1,
        idRol: 1,
        nombre: 'Admin',
        apellido: 'Test',
        correo: 'admin@test.com',
        telefono: null,
        activo: true,
        fechaCreacion: DateTime.now(),
      );
      const token = 'mock_admin_token';
      await _storage.write(key: AppConstants.jwtTokenKey, value: token);
      await _storage.write(key: AppConstants.userDataKey, value: jsonEncode({
        'id_usuario': usuario.id,
        'id_rol': usuario.idRol,
        'nombre': usuario.nombre,
        'apellido': usuario.apellido,
        'correo': usuario.correo,
        'telefono': usuario.telefono,
        'activo': usuario.activo,
        'fecha_creacion': usuario.fechaCreacion.toIso8601String(),
      }));
      return Sesion(token: token, usuario: usuario);
    }

    if (correo == 'user@test.com' && password == 'user123') {
      final usuario = Usuario(
        id: 2,
        idRol: 2,
        nombre: 'Usuario',
        apellido: 'Test',
        correo: 'user@test.com',
        telefono: '123456789',
        activo: true,
        fechaCreacion: DateTime.now(),
      );
      const token = 'mock_user_token';
      await _storage.write(key: AppConstants.jwtTokenKey, value: token);
      await _storage.write(key: AppConstants.userDataKey, value: jsonEncode({
        'id_usuario': usuario.id,
        'id_rol': usuario.idRol,
        'nombre': usuario.nombre,
        'apellido': usuario.apellido,
        'correo': usuario.correo,
        'telefono': usuario.telefono,
        'activo': usuario.activo,
        'fecha_creacion': usuario.fechaCreacion.toIso8601String(),
      }));
      return Sesion(token: token, usuario: usuario);
    }

    // Login normal via API
    final resp = await _dio.post(
      AppConstants.loginEndpoint,
      data: {'correo': correo, 'password': password},
    );
    final tokenModel = LoginResponseModel.fromJson(resp.data as Map<String, dynamic>);

    // Guardar token en secure storage
    await _storage.write(key: AppConstants.jwtTokenKey, value: tokenModel.accessToken);

    // Obtener datos del usuario con el token recién guardado
    final userResp = await _dio.get('/auth/me');
    final usuario = UsuarioModel.fromJson(userResp.data as Map<String, dynamic>).toDomain();

    // Persistir datos del usuario para uso offline
    await _storage.write(key: AppConstants.userDataKey, value: jsonEncode({
      'id_usuario': usuario.id,
      'id_rol': usuario.idRol,
      'nombre': usuario.nombre,
      'apellido': usuario.apellido,
      'correo': usuario.correo,
      'telefono': usuario.telefono,
      'activo': usuario.activo,
      'fecha_creacion': usuario.fechaCreacion.toIso8601String(),
    }));

    return Sesion(token: tokenModel.accessToken, usuario: usuario);
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: AppConstants.jwtTokenKey);
    await _storage.delete(key: AppConstants.userDataKey);
  }

  @override
  Future<Sesion?> getSesionActual() async {
    final token = await _storage.read(key: AppConstants.jwtTokenKey);
    final userData = await _storage.read(key: AppConstants.userDataKey);
    if (token == null || userData == null) return null;

    try {
      final json = jsonDecode(userData) as Map<String, dynamic>;
      final usuario = UsuarioModel.fromJson(json).toDomain();
      return Sesion(token: token, usuario: usuario);
    } catch (_) {
      return null;
    }
  }
}

// ── Usuario ──────────────────────────────────────────────────────────────────
class UsuarioRepositoryImpl implements UsuarioRepository {
  final _dio = ApiClient.instance.dio;

  @override
  Future<List<Usuario>> listarUsuarios() async {
    try {
      final resp = await _dio.get(AppConstants.usuariosEndpoint);
      final list = resp.data as List;
      return list.map((e) => UsuarioModel.fromJson(e as Map<String, dynamic>).toDomain()).toList();
    } catch (_) {
      return [
        Usuario(
          id: 1,
          idRol: 1,
          nombre: 'Admin',
          apellido: 'Test',
          correo: 'admin@test.com',
          telefono: null,
          activo: true,
          fechaCreacion: DateTime.now(),
        ),
        Usuario(
          id: 2,
          idRol: 2,
          nombre: 'Usuario',
          apellido: 'Test',
          correo: 'user@test.com',
          telefono: '123456789',
          activo: true,
          fechaCreacion: DateTime.now(),
        ),
      ];
    }
  }

  @override
  Future<Usuario> crearUsuario({
    required int idRol,
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    String? telefono,
  }) async {
    final resp = await _dio.post(AppConstants.usuariosEndpoint, data: {
      'id_rol': idRol,
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'password': password,
      if (telefono != null) 'telefono': telefono,
    });
    return UsuarioModel.fromJson(resp.data as Map<String, dynamic>).toDomain();
  }

  @override
  Future<Usuario> actualizarEstado({required int idUsuario, required bool activo}) async {
    final resp = await _dio.patch(
      '${AppConstants.usuariosEndpoint}/$idUsuario/estado',
      data: {'activo': activo},
    );
    return UsuarioModel.fromJson(resp.data as Map<String, dynamic>).toDomain();
  }
}

// ── Finca ────────────────────────────────────────────────────────────────────
class FincaRepositoryImpl implements FincaRepository {
  final _dio = ApiClient.instance.dio;

  @override
  Future<List<Finca>> listarFincas() async {
    try {
      final resp = await _dio.get(AppConstants.fincasEndpoint);
      final list = resp.data as List;
      return list.map((e) => FincaModel.fromJson(e as Map<String, dynamic>).toDomain()).toList();
    } catch (_) {
      // Datos de prueba
      return [
        Finca(
          id: 1,
          idMunicipio: 1,
          nombre: 'Finca El Café',
          propietario: 'Juan Pérez',
          direccion: 'Dirección de prueba',
          latitud: 14.6349,
          longitud: -90.5069,
          areaHectareas: 10.5,
          descripcion: 'Finca de prueba para testing',
          fechaCreacion: DateTime.now(),
        ),
        Finca(
          id: 2,
          idMunicipio: 2,
          nombre: 'Finca La Esperanza',
          propietario: 'María García',
          direccion: null,
          latitud: null,
          longitud: null,
          areaHectareas: 15.0,
          descripcion: null,
          fechaCreacion: DateTime.now(),
        ),
      ];
    }
  }

  @override
  Future<Finca> crearFinca({
    required int idMunicipio,
    required String nombre,
    required String propietario,
    String? direccion,
    double? latitud,
    double? longitud,
    double? areaHectareas,
    String? descripcion,
  }) async {
    final resp = await _dio.post(AppConstants.fincasEndpoint, data: {
      'id_municipio': idMunicipio,
      'nombre': nombre,
      'propietario': propietario,
      if (direccion != null) 'direccion': direccion,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (areaHectareas != null) 'area_hectareas': areaHectareas,
      if (descripcion != null) 'descripcion': descripcion,
    });
    return FincaModel.fromJson(resp.data as Map<String, dynamic>).toDomain();
  }
}

// ── Lote ─────────────────────────────────────────────────────────────────────
class LoteRepositoryImpl implements LoteRepository {
  final _dio = ApiClient.instance.dio;

  @override
  Future<List<Lote>> listarLotes() async {
    try {
      final resp = await _dio.get(AppConstants.lotesEndpoint);
      final list = resp.data as List;
      return list.map((e) => LoteModel.fromJson(e as Map<String, dynamic>).toDomain()).toList();
    } catch (_) {
      // Datos de prueba si la API no está disponible
      return [
        Lote(
          id: 1,
          idFinca: 1,
          nombreFinca: 'Finca El Café',
          idVariedad: 1,
          nombreVariedad: 'Caturra',
          idEstadoLoteActual: 1,
          nombreEstado: 'En Crecimiento',
          codigoLote: 'LOTE001',
          fechaRegistro: DateTime.now().subtract(const Duration(days: 30)),
          cantidadKg: 500.0,
          observaciones: 'Lote de prueba',
          activo: true,
        ),
        Lote(
          id: 2,
          idFinca: 2,
          nombreFinca: 'Finca La Esperanza',
          idVariedad: 2,
          nombreVariedad: 'Bourbon',
          idEstadoLoteActual: 2,
          nombreEstado: 'Listo para Cosecha',
          codigoLote: 'LOTE002',
          fechaRegistro: DateTime.now().subtract(const Duration(days: 60)),
          cantidadKg: 750.0,
          observaciones: null,
          activo: true,
        ),
      ];
    }
  }

  @override
  Future<Lote> obtenerLote(int idLote) async {
    final resp = await _dio.get('${AppConstants.lotesEndpoint}/$idLote');
    return LoteModel.fromJson(resp.data as Map<String, dynamic>).toDomain();
  }

  @override
  Future<Lote> crearLote({
    required int idFinca,
    required int idVariedad,
    required int idEstadoLoteActual,
    required String codigoLote,
    required DateTime fechaRegistro,
    double? cantidadKg,
    String? observaciones,
  }) async {
    try {
      final resp = await _dio.post(AppConstants.lotesEndpoint, data: {
        'id_finca': idFinca,
        'id_variedad': idVariedad,
        'id_estado_lote_actual': idEstadoLoteActual,
        'codigo_lote': codigoLote,
        'fecha_registro': fechaRegistro.toIso8601String().split('T')[0],
        if (cantidadKg != null) 'cantidad_kg': cantidadKg,
        if (observaciones != null) 'observaciones': observaciones,
      });
      final data = resp.data['data'] ?? resp.data;
      return LoteModel.fromJson(data as Map<String, dynamic>).toDomain();
    } catch (_) {
      return Lote(
        id: -1,
        idFinca: idFinca,
        nombreFinca: 'Finca desconocida',
        idVariedad: idVariedad,
        nombreVariedad: 'Variedad desconocida',
        idEstadoLoteActual: idEstadoLoteActual,
        nombreEstado: 'Estado desconocido',
        codigoLote: codigoLote,
        fechaRegistro: fechaRegistro,
        cantidadKg: cantidadKg,
        observaciones: observaciones,
        activo: true,
      );
    }
  }

  @override
  Future<Lote> editarLote({
    required int idLote,
    int? idEstadoLoteActual,
    double? cantidadKg,
    String? observaciones,
  }) async {
    try {
      final resp = await _dio.put('${AppConstants.lotesEndpoint}/$idLote', data: {
        if (idEstadoLoteActual != null) 'id_estado_lote_actual': idEstadoLoteActual,
        if (cantidadKg != null) 'cantidad_kg': cantidadKg,
        if (observaciones != null) 'observaciones': observaciones,
      });
      return LoteModel.fromJson(resp.data as Map<String, dynamic>).toDomain();
    } catch (_) {
      return Lote(
        id: idLote,
        idFinca: 0,
        nombreFinca: 'Finca desconocida',
        idVariedad: 0,
        nombreVariedad: 'Variedad desconocida',
        idEstadoLoteActual: idEstadoLoteActual ?? 0,
        nombreEstado: 'Estado desconocido',
        codigoLote: 'LOTE-$idLote',
        fechaRegistro: DateTime.now(),
        cantidadKg: cantidadKg,
        observaciones: observaciones,
        activo: true,
      );
    }
  }
}

// ── Registro ─────────────────────────────────────────────────────────────────
class RegistroRepositoryImpl implements RegistroRepository {
  final _dio = ApiClient.instance.dio;

  @override
  Future<List<RegistroPostcosecha>> listarRegistros(int idLote) async {
    try {
      final resp = await _dio.get('${AppConstants.lotesEndpoint}/$idLote/registros');
      final list = resp.data as List;
      return list
          .map((e) => RegistroPostcosechaModel.fromJson(e as Map<String, dynamic>).toDomain())
          .toList();
    } catch (_) {
      // Datos de prueba
      if (idLote == 1) {
        return [
          RegistroPostcosecha(
            id: 1,
            idLote: 1,
            idUsuario: 1,
            idTipoActividad: 1,
            idEstadoLote: 1,
            fechaHora: DateTime.now().subtract(const Duration(days: 10)),
            observacion: 'Registro de prueba',
            ubicacionRegistro: null,
            creadoEn: DateTime.now(),
            variables: [
              const VariableDetalle(
                id: 1,
                idRegistro: 1,
                idVariable: 1,
                valor: 65.5,
                comentario: null,
                nombreVariable: 'Humedad',
                unidadSimbolo: '%',
              ),
            ],
            nombreUsuario: 'Admin Test',
            nombreActividad: 'Siembra',
            nombreEstado: 'En Crecimiento',
          ),
        ];
      }
      return [];
    }
  }

  @override
  Future<RegistroPostcosecha> crearRegistro({
    required int idLote,
    required int idUsuario,
    required int idTipoActividad,
    required int idEstadoLote,
    required DateTime fechaHora,
    String? observacion,
    String? ubicacionRegistro,
    required List<({int idVariable, double valor, String? comentario})> variables,
  }) async {
    final resp = await _dio.post(
      '${AppConstants.lotesEndpoint}/$idLote/registros',
      data: {
        'id_usuario': idUsuario,
        'id_tipo_actividad': idTipoActividad,
        'id_estado_lote': idEstadoLote,
        'fecha_hora': fechaHora.toIso8601String(),
        if (observacion != null) 'observacion': observacion,
        if (ubicacionRegistro != null) 'ubicacion_registro': ubicacionRegistro,
        'variables': variables.map((v) => {
          'id_variable': v.idVariable,
          'valor': v.valor,
          if (v.comentario != null) 'comentario': v.comentario,
        }).toList(),
      },
    );
    return RegistroPostcosechaModel.fromJson(resp.data as Map<String, dynamic>).toDomain();
  }

  @override
  Future<RegistroPostcosecha> editarRegistro({
    required int idRegistro,
    String? observacion,
    List<({int idVariable, double valor, String? comentario})>? variables,
  }) async {
    final resp = await _dio.put(
      '${AppConstants.registrosEndpoint}/$idRegistro',
      data: {
        if (observacion != null) 'observacion': observacion,
        if (variables != null)
          'variables': variables.map((v) => {
            'id_variable': v.idVariable,
            'valor': v.valor,
            if (v.comentario != null) 'comentario': v.comentario,
          }).toList(),
      },
    );
    return RegistroPostcosechaModel.fromJson(resp.data as Map<String, dynamic>).toDomain();
  }

  @override
  Future<void> eliminarRegistro(int idRegistro) async {
    await _dio.delete('${AppConstants.registrosEndpoint}/$idRegistro');
  }

  @override
  Future<ReporteLote> obtenerReporte(int idLote) async {
    final resp = await _dio.get('${AppConstants.lotesEndpoint}/$idLote${AppConstants.reporteEndpoint}');
    final data = resp.data as Map<String, dynamic>;
    final lote = LoteModel.fromJson(data['lote'] as Map<String, dynamic>).toDomain();
    final registros = ((data['registros'] as List?) ?? [])
        .map((e) => RegistroPostcosechaModel.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
    return ReporteLote(
      lote: lote,
      registros: registros,
      rendimientoFinal: (data['rendimiento_final'] as num?)?.toDouble(),
      resumen: data['resumen'] as String?,
    );
  }
}

// ── Catálogos ─────────────────────────────────────────────────────────────────
class CatalogoRepositoryImpl implements CatalogoRepository {
  final _dio = ApiClient.instance.dio;

  List<Catalogo> _mapList(List list, String idKey) => list
      .map((e) => CatalogoModel.fromJson(e as Map<String, dynamic>, idKey).toDomain())
      .toList();

  @override
  Future<List<Catalogo>> listarVariedades() async {
    try {
      final resp = await _dio.get('/variedades');
      return _mapList(resp.data as List, 'id_variedad');
    } catch (_) {
      return [
        Catalogo(id: 1, nombre: 'Caturra'),
        Catalogo(id: 2, nombre: 'Bourbon'),
        Catalogo(id: 3, nombre: 'Typica'),
      ];
    }
  }

  @override
  Future<List<Catalogo>> listarEstadosLote() async {
    try {
      final resp = await _dio.get('/estados-lote');
      return _mapList(resp.data as List, 'id_estado_lote');
    } catch (_) {
      return [
        Catalogo(id: 1, nombre: 'En Crecimiento'),
        Catalogo(id: 2, nombre: 'Listo para Cosecha'),
        Catalogo(id: 3, nombre: 'Cosechado'),
      ];
    }
  }

  @override
  Future<List<Catalogo>> listarTiposActividad() async {
    try {
      final resp = await _dio.get('/tipos-actividad');
      return _mapList(resp.data as List, 'id_tipo_actividad');
    } catch (_) {
      return [
        Catalogo(id: 1, nombre: 'Siembra'),
        Catalogo(id: 2, nombre: 'Fertilización'),
        Catalogo(id: 3, nombre: 'Riego'),
        Catalogo(id: 4, nombre: 'Cosecha'),
      ];
    }
  }

  @override
  Future<List<VariableMonitoreo>> listarVariablesMonitoreo() async {
    try {
      final resp = await _dio.get('/variables-monitoreo');
      final list = resp.data as List;
      return list.map((e) => VariableMonitoreoModel.fromJson(e as Map<String, dynamic>).toDomain()).toList();
    } catch (_) {
      return [
        VariableMonitoreo(
          id: 1,
          nombre: 'Humedad del Suelo',
          idUnidadMedida: 1,
          requiereAlerta: true,
          simboloUnidad: '%',
        ),
        VariableMonitoreo(
          id: 2,
          nombre: 'Temperatura',
          idUnidadMedida: 2,
          requiereAlerta: false,
          simboloUnidad: '°C',
        ),
      ];
    }
  }

  @override
  Future<List<Catalogo>> listarDepartamentos() async {
    try {
      final resp = await _dio.get('/departamentos');
      return _mapList(resp.data as List, 'id_departamento');
    } catch (_) {
      return [
        Catalogo(id: 1, nombre: 'Guatemala'),
        Catalogo(id: 2, nombre: 'Alta Verapaz'),
      ];
    }
  }

  @override
  Future<List<Catalogo>> listarMunicipios(int idDepartamento) async {
    try {
      final resp = await _dio.get('/municipios', queryParameters: {'id_departamento': idDepartamento});
      return _mapList(resp.data as List, 'id_municipio');
    } catch (_) {
      return [
        Catalogo(id: 1, nombre: 'Municipio Test'),
        Catalogo(id: 2, nombre: 'Otro Municipio'),
      ];
    }
  }
}

// ── Implementaciones Mock para desarrollo / ejercicio ──────────────────────
class MockAuthRepository implements AuthRepository {
  Sesion? _session;

  @override
  Future<Sesion> login({required String correo, required String password}) async {
    if (correo == 'admin@test.com' && password == 'admin123') {
      final usuario = Usuario(
        id: 1,
        idRol: 1,
        nombre: 'Admin',
        apellido: 'Test',
        correo: 'admin@test.com',
        telefono: null,
        activo: true,
        fechaCreacion: DateTime.now(),
      );
      _session = Sesion(token: 'mock_admin_token', usuario: usuario);
      return _session!;
    }

    if (correo == 'user@test.com' && password == 'user123') {
      final usuario = Usuario(
        id: 2,
        idRol: 2,
        nombre: 'Usuario',
        apellido: 'Test',
        correo: 'user@test.com',
        telefono: '123456789',
        activo: true,
        fechaCreacion: DateTime.now(),
      );
      _session = Sesion(token: 'mock_user_token', usuario: usuario);
      return _session!;
    }

    throw Exception('Credenciales inválidas para modo mock');
  }

  @override
  Future<void> logout() async {
    _session = null;
  }

  @override
  Future<Sesion?> getSesionActual() async {
    return _session;
  }
}

class MockUsuarioRepository implements UsuarioRepository {
  final List<Usuario> _usuarios = [
    Usuario(
      id: 1,
      idRol: 1,
      nombre: 'Admin',
      apellido: 'Test',
      correo: 'admin@test.com',
      telefono: null,
      activo: true,
      fechaCreacion: DateTime.now(),
    ),
    Usuario(
      id: 2,
      idRol: 2,
      nombre: 'Usuario',
      apellido: 'Test',
      correo: 'user@test.com',
      telefono: '123456789',
      activo: true,
      fechaCreacion: DateTime.now(),
    ),
  ];
  int _nextId = 3;

  @override
  Future<List<Usuario>> listarUsuarios() async {
    return List<Usuario>.from(_usuarios);
  }

  @override
  Future<Usuario> crearUsuario({
    required int idRol,
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    String? telefono,
  }) async {
    final nuevo = Usuario(
      id: _nextId++,
      idRol: idRol,
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      telefono: telefono,
      activo: true,
      fechaCreacion: DateTime.now(),
    );
    _usuarios.add(nuevo);
    return nuevo;
  }

  @override
  Future<Usuario> actualizarEstado({required int idUsuario, required bool activo}) async {
    final index = _usuarios.indexWhere((u) => u.id == idUsuario);
    if (index < 0) throw Exception('Usuario no encontrado');
    final usuario = _usuarios[index];
    final actualizado = Usuario(
      id: usuario.id,
      idRol: usuario.idRol,
      nombre: usuario.nombre,
      apellido: usuario.apellido,
      correo: usuario.correo,
      telefono: usuario.telefono,
      activo: activo,
      fechaCreacion: usuario.fechaCreacion,
    );
    _usuarios[index] = actualizado;
    return actualizado;
  }
}

class MockFincaRepository implements FincaRepository {
  final List<Finca> _fincas = [
    Finca(
      id: 1,
      idMunicipio: 1,
      nombre: 'Finca El Café',
      propietario: 'Juan Pérez',
      direccion: 'Dirección de prueba',
      latitud: 14.6349,
      longitud: -90.5069,
      areaHectareas: 10.5,
      descripcion: 'Finca de prueba para testing',
      fechaCreacion: DateTime.now(),
    ),
    Finca(
      id: 2,
      idMunicipio: 2,
      nombre: 'Finca La Esperanza',
      propietario: 'María García',
      direccion: null,
      latitud: null,
      longitud: null,
      areaHectareas: 15.0,
      descripcion: null,
      fechaCreacion: DateTime.now(),
    ),
  ];

  @override
  Future<List<Finca>> listarFincas() async {
    return List<Finca>.from(_fincas);
  }

  @override
  Future<Finca> crearFinca({
    required int idMunicipio,
    required String nombre,
    required String propietario,
    String? direccion,
    double? latitud,
    double? longitud,
    double? areaHectareas,
    String? descripcion,
  }) async {
    final nuevo = Finca(
      id: _fincas.length + 1,
      idMunicipio: idMunicipio,
      nombre: nombre,
      propietario: propietario,
      direccion: direccion,
      latitud: latitud,
      longitud: longitud,
      areaHectareas: areaHectareas,
      descripcion: descripcion,
      fechaCreacion: DateTime.now(),
    );
    _fincas.add(nuevo);
    return nuevo;
  }
}

class MockLoteRepository implements LoteRepository {
  final List<Lote> _lotes = [
    Lote(
      id: 1,
      idFinca: 1,
      nombreFinca: 'Finca El Café',
      idVariedad: 1,
      nombreVariedad: 'Caturra',
      idEstadoLoteActual: 1,
      nombreEstado: 'En Crecimiento',
      codigoLote: 'LOTE001',
      fechaRegistro: DateTime.now().subtract(const Duration(days: 30)),
      cantidadKg: 500.0,
      observaciones: 'Lote de prueba',
      activo: true,
    ),
    Lote(
      id: 2,
      idFinca: 2,
      nombreFinca: 'Finca La Esperanza',
      idVariedad: 2,
      nombreVariedad: 'Bourbon',
      idEstadoLoteActual: 2,
      nombreEstado: 'Listo para Cosecha',
      codigoLote: 'LOTE002',
      fechaRegistro: DateTime.now().subtract(const Duration(days: 60)),
      cantidadKg: 750.0,
      observaciones: null,
      activo: true,
    ),
  ];

  static const Map<int, String> _fincaNames = {
    1: 'Finca El Café',
    2: 'Finca La Esperanza',
  };

  static const Map<int, String> _variedadNames = {
    1: 'Caturra',
    2: 'Bourbon',
  };

  static const Map<int, String> _estadoNames = {
    1: 'En Crecimiento',
    2: 'Listo para Cosecha',
    3: 'Cosechado',
  };

  @override
  Future<List<Lote>> listarLotes() async {
    return List<Lote>.from(_lotes);
  }

  @override
  Future<Lote> obtenerLote(int idLote) async {
    final lote = _lotes.firstWhere((l) => l.id == idLote, orElse: () => throw Exception('Lote no encontrado'));
    return lote;
  }

  String _getFincaName(int idFinca) {
    return _fincaNames[idFinca] ?? 'Finca desconocida';
  }

  String _getVariedadName(int idVariedad) {
    return _variedadNames[idVariedad] ?? 'Variedad desconocida';
  }

  String _getEstadoName(int idEstado) {
    return _estadoNames[idEstado] ?? 'Estado desconocido';
  }

  @override
  Future<Lote> crearLote({
    required int idFinca,
    required int idVariedad,
    required int idEstadoLoteActual,
    required String codigoLote,
    required DateTime fechaRegistro,
    double? cantidadKg,
    String? observaciones,
  }) async {
    final nuevo = Lote(
      id: _lotes.length + 1,
      idFinca: idFinca,
      nombreFinca: _getFincaName(idFinca),
      idVariedad: idVariedad,
      nombreVariedad: _getVariedadName(idVariedad),
      idEstadoLoteActual: idEstadoLoteActual,
      nombreEstado: _getEstadoName(idEstadoLoteActual),
      codigoLote: codigoLote,
      fechaRegistro: fechaRegistro,
      cantidadKg: cantidadKg,
      observaciones: observaciones,
      activo: true,
    );
    _lotes.add(nuevo);
    return nuevo;
  }

  @override
  Future<Lote> editarLote({
    required int idLote,
    int? idEstadoLoteActual,
    double? cantidadKg,
    String? observaciones,
  }) async {
    final index = _lotes.indexWhere((l) => l.id == idLote);
    if (index < 0) throw Exception('Lote no encontrado');
    final lote = _lotes[index];
    final actualizado = Lote(
      id: lote.id,
      idFinca: lote.idFinca,
      nombreFinca: lote.nombreFinca,
      idVariedad: lote.idVariedad,
      nombreVariedad: lote.nombreVariedad,
      idEstadoLoteActual: idEstadoLoteActual ?? lote.idEstadoLoteActual,
      nombreEstado: idEstadoLoteActual != null ? _getEstadoName(idEstadoLoteActual) : lote.nombreEstado,
      codigoLote: lote.codigoLote,
      fechaRegistro: lote.fechaRegistro,
      cantidadKg: cantidadKg ?? lote.cantidadKg,
      observaciones: observaciones ?? lote.observaciones,
      activo: lote.activo,
    );
    _lotes[index] = actualizado;
    return actualizado;
  }
}

class MockRegistroRepository implements RegistroRepository {
  final List<RegistroPostcosecha> _registros = [
    RegistroPostcosecha(
      id: 1,
      idLote: 1,
      idUsuario: 1,
      idTipoActividad: 1,
      idEstadoLote: 1,
      fechaHora: DateTime.now().subtract(const Duration(days: 10)),
      observacion: 'Registro de prueba',
      ubicacionRegistro: null,
      creadoEn: DateTime.now(),
      variables: [
        const VariableDetalle(
          id: 1,
          idRegistro: 1,
          idVariable: 1,
          valor: 65.5,
          comentario: null,
          nombreVariable: 'Humedad',
          unidadSimbolo: '%',
        ),
      ],
      nombreUsuario: 'Admin Test',
      nombreActividad: 'Siembra',
      nombreEstado: 'En Crecimiento',
    ),
  ];
  int _nextRegistroId = 2;

  @override
  Future<List<RegistroPostcosecha>> listarRegistros(int idLote) async {
    return _registros.where((r) => r.idLote == idLote).toList();
  }

  @override
  Future<RegistroPostcosecha> crearRegistro({
    required int idLote,
    required int idUsuario,
    required int idTipoActividad,
    required int idEstadoLote,
    required DateTime fechaHora,
    String? observacion,
    String? ubicacionRegistro,
    required List<({int idVariable, double valor, String? comentario})> variables,
  }) async {
    final nuevo = RegistroPostcosecha(
      id: _nextRegistroId++,
      idLote: idLote,
      idUsuario: idUsuario,
      idTipoActividad: idTipoActividad,
      idEstadoLote: idEstadoLote,
      fechaHora: fechaHora,
      observacion: observacion,
      ubicacionRegistro: ubicacionRegistro,
      creadoEn: DateTime.now(),
      variables: variables
          .map((v) => VariableDetalle(
                id: _nextRegistroId + v.idVariable,
                idRegistro: _nextRegistroId,
                idVariable: v.idVariable,
                valor: v.valor,
                comentario: v.comentario,
                nombreVariable: null,
                unidadSimbolo: null,
              ))
          .toList(),
      nombreUsuario: 'Usuario Mock',
      nombreActividad: 'Actividad Mock',
      nombreEstado: 'Estado Mock',
    );
    _registros.add(nuevo);
    return nuevo;
  }

  @override
  Future<RegistroPostcosecha> editarRegistro({
    required int idRegistro,
    String? observacion,
    List<({int idVariable, double valor, String? comentario})>? variables,
  }) async {
    final index = _registros.indexWhere((r) => r.id == idRegistro);
    if (index < 0) throw Exception('Registro no encontrado');
    final registro = _registros[index];
    final actualizado = RegistroPostcosecha(
      id: registro.id,
      idLote: registro.idLote,
      idUsuario: registro.idUsuario,
      idTipoActividad: registro.idTipoActividad,
      idEstadoLote: registro.idEstadoLote,
      fechaHora: registro.fechaHora,
      observacion: observacion ?? registro.observacion,
      ubicacionRegistro: registro.ubicacionRegistro,
      creadoEn: registro.creadoEn,
      variables: variables
          ?.map((v) => VariableDetalle(
                id: registro.id + v.idVariable,
                idRegistro: registro.id,
                idVariable: v.idVariable,
                valor: v.valor,
                comentario: v.comentario,
                nombreVariable: null,
                unidadSimbolo: null,
              ))
          .toList() ?? registro.variables,
      nombreUsuario: registro.nombreUsuario,
      nombreActividad: registro.nombreActividad,
      nombreEstado: registro.nombreEstado,
    );
    _registros[index] = actualizado;
    return actualizado;
  }

  @override
  Future<void> eliminarRegistro(int idRegistro) async {
    _registros.removeWhere((r) => r.id == idRegistro);
  }

  @override
  Future<ReporteLote> obtenerReporte(int idLote) async {
    final registros = _registros.where((r) => r.idLote == idLote).toList();
    final lote = Lote(
      id: idLote,
      idFinca: 1,
      nombreFinca: 'Finca ejemplo',
      idVariedad: 1,
      nombreVariedad: 'Caturra',
      idEstadoLoteActual: 2,
      nombreEstado: 'Listo para Cosecha',
      codigoLote: 'LOTE00$idLote',
      fechaRegistro: DateTime.now().subtract(const Duration(days: 35)),
      cantidadKg: 600.0,
      observaciones: 'Reporte de lote mock',
      activo: true,
    );
    return ReporteLote(
      lote: lote,
      registros: registros,
      rendimientoFinal: 4.8,
      resumen: 'Reporte mock generado sin backend',
    );
  }
}

class MockCatalogoRepository implements CatalogoRepository {
  @override
  Future<List<Catalogo>> listarVariedades() async {
    return [
      Catalogo(id: 1, nombre: 'Caturra'),
      Catalogo(id: 2, nombre: 'Bourbon'),
      Catalogo(id: 3, nombre: 'Typica'),
    ];
  }

  @override
  Future<List<Catalogo>> listarEstadosLote() async {
    return [
      Catalogo(id: 1, nombre: 'En Crecimiento'),
      Catalogo(id: 2, nombre: 'Listo para Cosecha'),
      Catalogo(id: 3, nombre: 'Cosechado'),
    ];
  }

  @override
  Future<List<Catalogo>> listarTiposActividad() async {
    return [
      Catalogo(id: 1, nombre: 'Siembra'),
      Catalogo(id: 2, nombre: 'Fertilización'),
      Catalogo(id: 3, nombre: 'Riego'),
      Catalogo(id: 4, nombre: 'Cosecha'),
    ];
  }

  @override
  Future<List<VariableMonitoreo>> listarVariablesMonitoreo() async {
    return [
      VariableMonitoreo(
        id: 1,
        nombre: 'Humedad del Suelo',
        idUnidadMedida: 1,
        requiereAlerta: true,
        simboloUnidad: '%',
      ),
      VariableMonitoreo(
        id: 2,
        nombre: 'Temperatura',
        idUnidadMedida: 2,
        requiereAlerta: false,
        simboloUnidad: '°C',
      ),
    ];
  }

  @override
  Future<List<Catalogo>> listarDepartamentos() async {
    return [
      Catalogo(id: 1, nombre: 'Guatemala'),
      Catalogo(id: 2, nombre: 'Alta Verapaz'),
    ];
  }

  @override
  Future<List<Catalogo>> listarMunicipios(int idDepartamento) async {
    return [
      Catalogo(id: 1, nombre: 'Municipio Test'),
      Catalogo(id: 2, nombre: 'Otro Municipio'),
    ];
  }
}
