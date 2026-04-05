import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../infrastructure/repositories/repositories_impl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORIOS — Inyección de dependencias
// Para usar un mock en tests, hacer: ProviderScope(overrides: [authRepoProvider.overrideWith(...)])
// ═══════════════════════════════════════════════════════════════════════════

final authRepoProvider = Provider<AuthRepository>((ref) {
  return AppConstants.useMockRepositories ? MockAuthRepository() : AuthRepositoryImpl();
});
final usuarioRepoProvider = Provider<UsuarioRepository>((ref) {
  return AppConstants.useMockRepositories ? MockUsuarioRepository() : UsuarioRepositoryImpl();
});
final fincaRepoProvider = Provider<FincaRepository>((ref) {
  return AppConstants.useMockRepositories ? MockFincaRepository() : FincaRepositoryImpl();
});
final loteRepoProvider = Provider<LoteRepository>((ref) {
  return AppConstants.useMockRepositories ? MockLoteRepository() : LoteRepositoryImpl();
});
final registroRepoProvider = Provider<RegistroRepository>((ref) {
  return AppConstants.useMockRepositories ? MockRegistroRepository() : RegistroRepositoryImpl();
});
final catalogoRepoProvider = Provider<CatalogoRepository>((ref) {
  return AppConstants.useMockRepositories ? MockCatalogoRepository() : CatalogoRepositoryImpl();
});

// ═══════════════════════════════════════════════════════════════════════════
// AUTH — Estado de sesión global
// ═══════════════════════════════════════════════════════════════════════════

class AuthNotifier extends AsyncNotifier<Sesion?> {
  @override
  Future<Sesion?> build() async {
    return ref.read(authRepoProvider).getSesionActual();
  }

  Future<void> login({required String correo, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepoProvider).login(correo: correo, password: password),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepoProvider).logout();
    state = const AsyncData(null);
  }

  Usuario? get usuario => state.maybeWhen(data: (sesion) => sesion?.usuario, orElse: () => null);
  bool get isAuthenticated => state.maybeWhen(data: (sesion) => sesion != null, orElse: () => false);
  bool get esAdmin => usuario?.esAdmin ?? false;
}

final authProvider = AsyncNotifierProvider<AuthNotifier, Sesion?>(AuthNotifier.new);

// Shortcuts cómodos
final usuarioActualProvider = Provider<Usuario?>((ref) {
  return ref.watch(authProvider).maybeWhen(data: (sesion) => sesion?.usuario, orElse: () => null);
});

// ═══════════════════════════════════════════════════════════════════════════
// LOTES
// ═══════════════════════════════════════════════════════════════════════════

class LotesNotifier extends AsyncNotifier<List<Lote>> {
  @override
  Future<List<Lote>> build() async {
    return ref.read(loteRepoProvider).listarLotes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(loteRepoProvider).listarLotes());
  }

  Future<void> crearLote({
    required int idFinca,
    required int idVariedad,
    required int idEstadoLoteActual,
    required String codigoLote,
    required DateTime fechaRegistro,
    double? cantidadKg,
    String? observaciones,
  }) async {
    final nuevo = await ref.read(loteRepoProvider).crearLote(
      idFinca: idFinca,
      idVariedad: idVariedad,
      idEstadoLoteActual: idEstadoLoteActual,
      codigoLote: codigoLote,
      fechaRegistro: fechaRegistro,
      cantidadKg: cantidadKg,
      observaciones: observaciones,
    );
    state = AsyncData([...state.maybeWhen(data: (data) => data, orElse: () => <Lote>[]) ?? [], nuevo]);
  }

  Future<void> editarLote({
    required int idLote,
    int? idEstadoLoteActual,
    double? cantidadKg,
    String? observaciones,
  }) async {
    final actualizado = await ref.read(loteRepoProvider).editarLote(
      idLote: idLote,
      idEstadoLoteActual: idEstadoLoteActual,
      cantidadKg: cantidadKg,
      observaciones: observaciones,
    );
    final lotes = state.maybeWhen(data: (data) => data, orElse: () => <Lote>[]);
    state = AsyncData(lotes.map((l) => l.id == idLote ? actualizado : l).toList());
  }
}

final lotesProvider = AsyncNotifierProvider<LotesNotifier, List<Lote>>(LotesNotifier.new);

// Lote individual por ID
final loteDetalleProvider = FutureProvider.family<Lote, int>((ref, idLote) {
  return ref.read(loteRepoProvider).obtenerLote(idLote);
});

// ═══════════════════════════════════════════════════════════════════════════
// REGISTROS
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// REGISTROS
// ═══════════════════════════════════════════════════════════════════════════

final registrosProvider = FutureProvider.family<List<RegistroPostcosecha>, int>((ref, idLote) {
  return ref.read(registroRepoProvider).listarRegistros(idLote);
});

class CrearRegistroParams {
  final int idLote;
  final int idUsuario;
  final int idTipoActividad;
  final int idEstadoLote;
  final DateTime fechaHora;
  final String? observacion;
  final String? ubicacionRegistro;
  final List<({int idVariable, double valor, String? comentario})> variables;

  CrearRegistroParams({
    required this.idLote,
    required this.idUsuario,
    required this.idTipoActividad,
    required this.idEstadoLote,
    required this.fechaHora,
    this.observacion,
    this.ubicacionRegistro,
    required this.variables,
  });
}

final crearRegistroProvider = FutureProvider.family<void, CrearRegistroParams>((ref, params) async {
  await ref.read(registroRepoProvider).crearRegistro(
    idLote: params.idLote,
    idUsuario: params.idUsuario,
    idTipoActividad: params.idTipoActividad,
    idEstadoLote: params.idEstadoLote,
    fechaHora: params.fechaHora,
    observacion: params.observacion,
    ubicacionRegistro: params.ubicacionRegistro,
    variables: params.variables,
  );
  ref.invalidate(registrosProvider(params.idLote));
});

final eliminarRegistroProvider = FutureProvider.family<void, ({int idLote, int idRegistro})>((ref, params) async {
  await ref.read(registroRepoProvider).eliminarRegistro(params.idRegistro);
  ref.invalidate(registrosProvider(params.idLote));
});

// Reporte
final reporteProvider = FutureProvider.family<ReporteLote, int>((ref, idLote) {
  return ref.read(registroRepoProvider).obtenerReporte(idLote);
});

// ═══════════════════════════════════════════════════════════════════════════
// FINCAS
// ═══════════════════════════════════════════════════════════════════════════

final fincasProvider = FutureProvider<List<Finca>>((ref) {
  return ref.read(fincaRepoProvider).listarFincas();
});

// ═══════════════════════════════════════════════════════════════════════════
// CATÁLOGOS — Se cargan una vez y se cachean
// ═══════════════════════════════════════════════════════════════════════════

final variedadesProvider = FutureProvider<List<Catalogo>>((ref) {
  return ref.read(catalogoRepoProvider).listarVariedades();
});

final estadosLoteProvider = FutureProvider<List<Catalogo>>((ref) {
  return ref.read(catalogoRepoProvider).listarEstadosLote();
});

final tiposActividadProvider = FutureProvider<List<Catalogo>>((ref) {
  return ref.read(catalogoRepoProvider).listarTiposActividad();
});

final variablesMonitoreoProvider = FutureProvider<List<VariableMonitoreo>>((ref) {
  return ref.read(catalogoRepoProvider).listarVariablesMonitoreo();
});

final departamentosProvider = FutureProvider<List<Catalogo>>((ref) {
  return ref.read(catalogoRepoProvider).listarDepartamentos();
});

final municipiosProvider = FutureProvider.family<List<Catalogo>, int>((ref, idDep) {
  return ref.read(catalogoRepoProvider).listarMunicipios(idDep);
});

// ═══════════════════════════════════════════════════════════════════════════
// USUARIOS (Admin)
// ═══════════════════════════════════════════════════════════════════════════

class UsuariosNotifier extends AsyncNotifier<List<Usuario>> {
  @override
  Future<List<Usuario>> build() async {
    return ref.read(usuarioRepoProvider).listarUsuarios();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(usuarioRepoProvider).listarUsuarios());
  }

  Future<void> crearUsuario({
    required int idRol,
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    String? telefono,
  }) async {
    final nuevo = await ref.read(usuarioRepoProvider).crearUsuario(
      idRol: idRol,
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      password: password,
      telefono: telefono,
    );
    state = AsyncData([...state.maybeWhen(data: (data) => data, orElse: () => <Usuario>[]) ?? [], nuevo]);
  }

  Future<void> cambiarEstado({required int idUsuario, required bool activo}) async {
    final actualizado = await ref.read(usuarioRepoProvider)
        .actualizarEstado(idUsuario: idUsuario, activo: activo);
    final lista = state.maybeWhen(data: (data) => data, orElse: () => <Usuario>[]);
    state = AsyncData(lista.map((u) => u.id == idUsuario ? actualizado : u).toList());
  }
}

final usuariosProvider = AsyncNotifierProvider<UsuariosNotifier, List<Usuario>>(UsuariosNotifier.new);

// ═══════════════════════════════════════════════════════════════════════════
// FILTROS UI — Estado local de búsqueda/filtrado de lotes
// ═══════════════════════════════════════════════════════════════════════════

class FiltroNotifier extends Notifier<String> {
  @override
  String build() => 'todos';
}

class BusquedaNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final loteFiltroProvider = NotifierProvider<FiltroNotifier, String>(FiltroNotifier.new);
final loteBusquedaProvider = NotifierProvider<BusquedaNotifier, String>(BusquedaNotifier.new);

final lotesFiltradosProvider = Provider<List<Lote>>((ref) {
  final lotes = ref.watch(lotesProvider).maybeWhen(data: (data) => data, orElse: () => <Lote>[]);
  final filtro = ref.watch(loteFiltroProvider);
  final busqueda = ref.watch(loteBusquedaProvider).toLowerCase();

  return lotes.where((lote) {
    final matchBusqueda = busqueda.isEmpty ||
        lote.codigoLote.toLowerCase().contains(busqueda) ||
        (lote.nombreFinca?.toLowerCase().contains(busqueda) ?? false) ||
        (lote.nombreVariedad?.toLowerCase().contains(busqueda) ?? false);

    final matchFiltro = switch (filtro) {
      'activos' => lote.activo,
      'inactivos' => !lote.activo,
      _ => true,
    };

    return matchBusqueda && matchFiltro;
  }).toList();
});
