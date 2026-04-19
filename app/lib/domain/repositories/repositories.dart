import '../entities/entities.dart';

/// Contratos abstractos de repositorios.
/// La capa de aplicación depende de estas interfaces, no de implementaciones concretas.
/// Cambiar el backend = cambiar solo las implementaciones en infrastructure/.

abstract class AuthRepository {
  Future<Sesion> login({required String correo, required String password});
  Future<void> logout();
  Future<Sesion?> getSesionActual();
}

abstract class UsuarioRepository {
  Future<List<Usuario>> listarUsuarios();
  Future<Usuario> crearUsuario({
    required int idRol,
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    String? telefono,
  });
  Future<Usuario> actualizarEstado({required int idUsuario, required bool activo});
}

abstract class FincaRepository {
  Future<List<Finca>> listarFincas();
  Future<Finca> crearFinca({
    required int idMunicipio,
    required String nombre,
    required String propietario,
    String? direccion,
    double? latitud,
    double? longitud,
    double? areaHectareas,
    String? descripcion,
  });
}

abstract class LoteRepository {
  Future<List<Lote>> listarLotes();
  Future<Lote> obtenerLote(int idLote);
  Future<Lote> crearLote({
    required int idFinca,
    required int idVariedad,
    required int idEstadoLoteActual,
    required String codigoLote,
    required DateTime fechaRegistro,
    double? cantidadKg,
    String? observaciones,
  });
  Future<Lote> editarLote({
    required int idLote,
    int? idEstadoLoteActual,
    double? cantidadKg,
    String? observaciones,
  });
}

abstract class RegistroRepository {
  Future<List<RegistroPostcosecha>> listarRegistros(int idLote);
  Future<RegistroPostcosecha> crearRegistro({
    required int idLote,
    required int idUsuario,
    required int idTipoActividad,
    required int idEstadoLote,
    required DateTime fechaHora,
    String? observacion,
    String? ubicacionRegistro,
    required List<({int idVariable, double valor, String? comentario})> variables,
  });
  Future<RegistroPostcosecha> editarRegistro({
    required int idRegistro,
    String? observacion,
    List<({int idVariable, double valor, String? comentario})>? variables,
  });
  Future<void> eliminarRegistro(int idRegistro);
  Future<ReporteLote> obtenerReporte(int idLote);
}

abstract class CatalogoRepository {
  Future<List<Catalogo>> listarVariedades();
  Future<List<Catalogo>> listarEstadosLote();
  Future<List<Catalogo>> listarTiposActividad();
  Future<List<VariableMonitoreo>> listarVariablesMonitoreo();
  Future<List<Catalogo>> listarDepartamentos();
  Future<List<Catalogo>> listarMunicipios(int idDepartamento);
}
