import '../../domain/entities/entities.dart';

/// Modelos de infraestructura: mapean JSON del backend a entidades del dominio.
/// Si Jorge cambia el nombre de un campo, solo se modifica aquí.

// ── Auth ─────────────────────────────────────────────────────────────────────
class LoginResponseModel {
  final String accessToken;
  final String tokenType;

  LoginResponseModel.fromJson(Map<String, dynamic> json)
      : accessToken = json['access_token'] as String,
        tokenType = json['token_type'] as String? ?? 'bearer';
}

// ── Usuario ──────────────────────────────────────────────────────────────────
class UsuarioModel {
  final int id;
  final int idRol;
  final String nombre;
  final String apellido;
  final String correo;
  final String? telefono;
  final bool activo;
  final String fechaCreacion;

  UsuarioModel.fromJson(Map<String, dynamic> json)
      : id = json['id_usuario'] as int,
        idRol = json['id_rol'] as int,
        nombre = json['nombre'] as String,
        apellido = json['apellido'] as String,
        correo = json['correo'] as String,
        telefono = json['telefono'] as String?,
        activo = json['activo'] as bool? ?? true,
        fechaCreacion = json['fecha_creacion'] as String? ?? '';

  Usuario toDomain() => Usuario(
        id: id,
        idRol: idRol,
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        telefono: telefono,
        activo: activo,
        fechaCreacion: DateTime.tryParse(fechaCreacion) ?? DateTime.now(),
      );
}

// ── Finca ────────────────────────────────────────────────────────────────────
class FincaModel {
  final int id;
  final int idMunicipio;
  final String nombre;
  final String propietario;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final double? areaHectareas;
  final String? descripcion;
  final String fechaCreacion;

  FincaModel.fromJson(Map<String, dynamic> json)
      : id = json['id_finca'] as int,
        idMunicipio = json['id_municipio'] as int,
        nombre = json['nombre'] as String,
        propietario = json['propietario'] as String,
        direccion = json['direccion'] as String?,
        latitud = (json['latitud'] as num?)?.toDouble(),
        longitud = (json['longitud'] as num?)?.toDouble(),
        areaHectareas = (json['area_hectareas'] as num?)?.toDouble(),
        descripcion = json['descripcion'] as String?,
        fechaCreacion = json['fecha_creacion'] as String? ?? '';

  Finca toDomain() => Finca(
        id: id,
        idMunicipio: idMunicipio,
        nombre: nombre,
        propietario: propietario,
        direccion: direccion,
        latitud: latitud,
        longitud: longitud,
        areaHectareas: areaHectareas,
        descripcion: descripcion,
        fechaCreacion: DateTime.tryParse(fechaCreacion) ?? DateTime.now(),
      );
}

// ── Lote ─────────────────────────────────────────────────────────────────────
class LoteModel {
  final int id;
  final int idFinca;
  final int idVariedad;
  final int idEstadoLoteActual;
  final String codigoLote;
  final String fechaRegistro;
  final double? cantidadKg;
  final String? observaciones;
  final bool activo;
  final String? nombreFinca;
  final String? nombreVariedad;
  final String? nombreEstado;

  LoteModel.fromJson(Map<String, dynamic> json)
      : id = json['id_lote'] as int,
        idFinca = json['id_finca'] as int,
        idVariedad = json['id_variedad'] as int,
        idEstadoLoteActual = json['id_estado_lote_actual'] as int,
        codigoLote = json['codigo_lote'] as String,
        fechaRegistro = json['fecha_registro'] as String,
        cantidadKg = (json['cantidad_kg'] as num?)?.toDouble(),
        observaciones = json['observaciones'] as String?,
        activo = json['activo'] as bool? ?? true,
        nombreFinca = json['nombre_finca'] as String?,
        nombreVariedad = json['nombre_variedad'] as String?,
        nombreEstado = json['nombre_estado'] as String?;

  Lote toDomain() => Lote(
        id: id,
        idFinca: idFinca,
        idVariedad: idVariedad,
        idEstadoLoteActual: idEstadoLoteActual,
        codigoLote: codigoLote,
        fechaRegistro: DateTime.tryParse(fechaRegistro) ?? DateTime.now(),
        cantidadKg: cantidadKg,
        observaciones: observaciones,
        activo: activo,
        nombreFinca: nombreFinca,
        nombreVariedad: nombreVariedad,
        nombreEstado: nombreEstado,
      );
}

// ── VariableDetalle ───────────────────────────────────────────────────────────
class VariableDetalleModel {
  final int id;
  final int idRegistro;
  final int idVariable;
  final double valor;
  final String? comentario;
  final String? nombreVariable;
  final String? unidadSimbolo;

  VariableDetalleModel.fromJson(Map<String, dynamic> json)
      : id = json['id_detalle'] as int,
        idRegistro = json['id_registro'] as int,
        idVariable = json['id_variable'] as int,
        valor = (json['valor'] as num).toDouble(),
        comentario = json['comentario'] as String?,
        nombreVariable = json['nombre_variable'] as String?,
        unidadSimbolo = json['unidad_simbolo'] as String?;

  VariableDetalle toDomain() => VariableDetalle(
        id: id,
        idRegistro: idRegistro,
        idVariable: idVariable,
        valor: valor,
        comentario: comentario,
        nombreVariable: nombreVariable,
        unidadSimbolo: unidadSimbolo,
      );
}

// ── RegistroPostcosecha ───────────────────────────────────────────────────────
class RegistroPostcosechaModel {
  final int id;
  final int idLote;
  final int idUsuario;
  final int idTipoActividad;
  final int idEstadoLote;
  final String fechaHora;
  final String? observacion;
  final String? ubicacionRegistro;
  final String creadoEn;
  final List<VariableDetalleModel> variables;
  final String? nombreActividad;
  final String? nombreEstado;
  final String? nombreUsuario;

  RegistroPostcosechaModel.fromJson(Map<String, dynamic> json)
      : id = json['id_registro'] as int,
        idLote = json['id_lote'] as int,
        idUsuario = json['id_usuario'] as int,
        idTipoActividad = json['id_tipo_actividad'] as int,
        idEstadoLote = json['id_estado_lote'] as int,
        fechaHora = json['fecha_hora'] as String,
        observacion = json['observacion'] as String?,
        ubicacionRegistro = json['ubicacion_registro'] as String?,
        creadoEn = json['creado_en'] as String? ?? '',
        variables = ((json['variables'] as List?) ?? [])
            .map((v) => VariableDetalleModel.fromJson(v as Map<String, dynamic>))
            .toList(),
        nombreActividad = json['nombre_actividad'] as String?,
        nombreEstado = json['nombre_estado'] as String?,
        nombreUsuario = json['nombre_usuario'] as String?;

  RegistroPostcosecha toDomain() => RegistroPostcosecha(
        id: id,
        idLote: idLote,
        idUsuario: idUsuario,
        idTipoActividad: idTipoActividad,
        idEstadoLote: idEstadoLote,
        fechaHora: DateTime.tryParse(fechaHora) ?? DateTime.now(),
        observacion: observacion,
        ubicacionRegistro: ubicacionRegistro,
        creadoEn: DateTime.tryParse(creadoEn) ?? DateTime.now(),
        variables: variables.map((v) => v.toDomain()).toList(),
        nombreActividad: nombreActividad,
        nombreEstado: nombreEstado,
        nombreUsuario: nombreUsuario,
      );
}

// ── Catálogo ──────────────────────────────────────────────────────────────────
class CatalogoModel {
  final int id;
  final String nombre;
  final String? descripcion;

  CatalogoModel.fromJson(Map<String, dynamic> json, String idKey)
      : id = json[idKey] as int,
        nombre = json['nombre'] as String,
        descripcion = json['descripcion'] as String?;

  Catalogo toDomain() => Catalogo(id: id, nombre: nombre, descripcion: descripcion);
}

class VariableMonitoreoModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final int idUnidadMedida;
  final double? valorMinimo;
  final double? valorMaximo;
  final bool requiereAlerta;
  final String? simboloUnidad;

  VariableMonitoreoModel.fromJson(Map<String, dynamic> json)
      : id = json['id_variable'] as int,
        nombre = json['nombre'] as String,
        descripcion = json['descripcion'] as String?,
        idUnidadMedida = json['id_unidad_medida'] as int,
        valorMinimo = (json['valor_minimo'] as num?)?.toDouble(),
        valorMaximo = (json['valor_maximo'] as num?)?.toDouble(),
        requiereAlerta = json['requiere_alerta'] as bool? ?? false,
        simboloUnidad = json['simbolo_unidad'] as String?;

  VariableMonitoreo toDomain() => VariableMonitoreo(
        id: id,
        nombre: nombre,
        descripcion: descripcion,
        idUnidadMedida: idUnidadMedida,
        valorMinimo: valorMinimo,
        valorMaximo: valorMaximo,
        requiereAlerta: requiereAlerta,
        simboloUnidad: simboloUnidad,
      );
}
