/// Entidades del dominio.
/// Clases puras de Dart — sin dependencias de Dio, Flutter o JSON.
/// Si cambia el backend, solo cambian los modelos de infraestructura, no estas entidades.

// ── Usuario ──────────────────────────────────────────────────────────────────
class Usuario {
  final int id;
  final int idRol;
  final String nombre;
  final String apellido;
  final String correo;
  final String? telefono;
  final bool activo;
  final DateTime fechaCreacion;

  const Usuario({
    required this.id,
    required this.idRol,
    required this.nombre,
    required this.apellido,
    required this.correo,
    this.telefono,
    required this.activo,
    required this.fechaCreacion,
  });

  String get nombreCompleto => '$nombre $apellido';
  String get iniciales => '${nombre[0]}${apellido[0]}'.toUpperCase();
  bool get esAdmin => idRol == 1; // Rol 1 = Administrador según catálogo
}

// ── Finca ────────────────────────────────────────────────────────────────────
class Finca {
  final int id;
  final int idMunicipio;
  final String nombre;
  final String propietario;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final double? areaHectareas;
  final String? descripcion;
  final DateTime fechaCreacion;

  const Finca({
    required this.id,
    required this.idMunicipio,
    required this.nombre,
    required this.propietario,
    this.direccion,
    this.latitud,
    this.longitud,
    this.areaHectareas,
    this.descripcion,
    required this.fechaCreacion,
  });
}

// ── Lote ─────────────────────────────────────────────────────────────────────
class Lote {
  final int id;
  final int idFinca;
  final int idVariedad;
  final int idEstadoLoteActual;
  final String codigoLote;
  final DateTime fechaRegistro;
  final double? cantidadKg;
  final String? observaciones;
  final bool activo;

  // Datos desnormalizados opcionales que puede traer el backend
  final String? nombreFinca;
  final String? nombreVariedad;
  final String? nombreEstado;

  const Lote({
    required this.id,
    required this.idFinca,
    required this.idVariedad,
    required this.idEstadoLoteActual,
    required this.codigoLote,
    required this.fechaRegistro,
    this.cantidadKg,
    this.observaciones,
    required this.activo,
    this.nombreFinca,
    this.nombreVariedad,
    this.nombreEstado,
  });
}

// ── RegistroPostcosecha ───────────────────────────────────────────────────────
class RegistroPostcosecha {
  final int id;
  final int idLote;
  final int idUsuario;
  final int idTipoActividad;
  final int idEstadoLote;
  final DateTime fechaHora;
  final String? observacion;
  final String? ubicacionRegistro;
  final DateTime creadoEn;
  final List<VariableDetalle> variables;

  // Datos desnormalizados
  final String? nombreActividad;
  final String? nombreEstado;
  final String? nombreUsuario;

  const RegistroPostcosecha({
    required this.id,
    required this.idLote,
    required this.idUsuario,
    required this.idTipoActividad,
    required this.idEstadoLote,
    required this.fechaHora,
    this.observacion,
    this.ubicacionRegistro,
    required this.creadoEn,
    required this.variables,
    this.nombreActividad,
    this.nombreEstado,
    this.nombreUsuario,
  });
}

// ── VariableDetalle ───────────────────────────────────────────────────────────
class VariableDetalle {
  final int id;
  final int idRegistro;
  final int idVariable;
  final double valor;
  final String? comentario;

  // Datos desnormalizados
  final String? nombreVariable;
  final String? unidadSimbolo;

  const VariableDetalle({
    required this.id,
    required this.idRegistro,
    required this.idVariable,
    required this.valor,
    this.comentario,
    this.nombreVariable,
    this.unidadSimbolo,
  });
}

// ── Catálogos ─────────────────────────────────────────────────────────────────
class Catalogo {
  final int id;
  final String nombre;
  final String? descripcion;

  const Catalogo({required this.id, required this.nombre, this.descripcion});
}

class VariableMonitoreo {
  final int id;
  final String nombre;
  final String? descripcion;
  final int idUnidadMedida;
  final double? valorMinimo;
  final double? valorMaximo;
  final bool requiereAlerta;
  final String? simboloUnidad;

  const VariableMonitoreo({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.idUnidadMedida,
    this.valorMinimo,
    this.valorMaximo,
    required this.requiereAlerta,
    this.simboloUnidad,
  });
}

// ── ReporteLote ───────────────────────────────────────────────────────────────
class ReporteLote {
  final Lote lote;
  final List<RegistroPostcosecha> registros;
  final double? rendimientoFinal;
  final String? resumen;

  const ReporteLote({
    required this.lote,
    required this.registros,
    this.rendimientoFinal,
    this.resumen,
  });
}

// ── Sesión ────────────────────────────────────────────────────────────────────
class Sesion {
  final String token;
  final Usuario usuario;

  const Sesion({required this.token, required this.usuario});
}
