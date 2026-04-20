-- Teniendo en cuenta el siguiente Script y la base de datos, Has un diccionario de datos y la explicacion del diagrada de entidad reacion que se crea pormmedio del mismo: todo en un documento World

DROP DATABASE IF EXISTS postcosecha_cafe;
CREATE DATABASE postcosecha_cafe CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;
USE postcosecha_cafe;

-- =========================================================
-- 1. TABLAS DE CATÁLOGO
-- =========================================================

CREATE TABLE rol (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NULL
) ENGINE=InnoDB;

CREATE TABLE departamento (
    id_departamento INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE municipio (
    id_municipio INT AUTO_INCREMENT PRIMARY KEY,
    id_departamento INT NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    CONSTRAINT fk_municipio_departamento
        FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT uq_municipio UNIQUE (id_departamento, nombre)
) ENGINE=InnoDB;

CREATE TABLE variedad_cafe (
    id_variedad INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NULL
) ENGINE=InnoDB;

CREATE TABLE estado_lote (
    id_estado_lote INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(40) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NULL
) ENGINE=InnoDB;

CREATE TABLE tipo_actividad (
    id_tipo_actividad INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NULL
) ENGINE=InnoDB;

CREATE TABLE unidad_medida (
    id_unidad_medida INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(40) NOT NULL,
    simbolo VARCHAR(15) NOT NULL,
    descripcion VARCHAR(100) NULL,
    CONSTRAINT uq_unidad_medida UNIQUE (nombre, simbolo)
) ENGINE=InnoDB;

CREATE TABLE variable_monitoreo (
    id_variable INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(150) NULL,
    id_unidad_medida INT NOT NULL,
    valor_minimo DECIMAL(10,2) NULL,
    valor_maximo DECIMAL(10,2) NULL,
    requiere_alerta BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_variable_unidad
        FOREIGN KEY (id_unidad_medida) REFERENCES unidad_medida(id_unidad_medida)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =========================================================
-- 2. TABLAS PRINCIPALES
-- =========================================================

CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    id_rol INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    correo VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    telefono VARCHAR(20) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario_rol
        FOREIGN KEY (id_rol) REFERENCES rol(id_rol)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE finca (
    id_finca INT AUTO_INCREMENT PRIMARY KEY,
    id_municipio INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    propietario VARCHAR(120) NOT NULL,
    direccion VARCHAR(150) NULL,
    latitud DECIMAL(10,7) NULL,
    longitud DECIMAL(10,7) NULL,
    area_hectareas DECIMAL(10,2) NULL,
    descripcion VARCHAR(200) NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_finca_municipio
        FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE lote (
    id_lote INT AUTO_INCREMENT PRIMARY KEY,
    id_finca INT NOT NULL,
    id_variedad INT NOT NULL,
    id_estado_lote_actual INT NOT NULL,
    codigo_lote VARCHAR(30) NOT NULL UNIQUE,
    fecha_registro DATE NOT NULL,
    cantidad_kg DECIMAL(10,2) NULL,
    observaciones VARCHAR(250) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_lote_finca
        FOREIGN KEY (id_finca) REFERENCES finca(id_finca)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_lote_variedad
        FOREIGN KEY (id_variedad) REFERENCES variedad_cafe(id_variedad)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_lote_estado_actual
        FOREIGN KEY (id_estado_lote_actual) REFERENCES estado_lote(id_estado_lote)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE registro_postcosecha (
    id_registro INT AUTO_INCREMENT PRIMARY KEY,
    id_lote INT NOT NULL,
    id_usuario INT NOT NULL,
    id_tipo_actividad INT NOT NULL,
    id_estado_lote INT NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacion VARCHAR(250) NULL,
    ubicacion_registro VARCHAR(120) NULL,
    creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_registro_lote
        FOREIGN KEY (id_lote) REFERENCES lote(id_lote)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_registro_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_registro_tipo_actividad
        FOREIGN KEY (id_tipo_actividad) REFERENCES tipo_actividad(id_tipo_actividad)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_registro_estado
        FOREIGN KEY (id_estado_lote) REFERENCES estado_lote(id_estado_lote)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE registro_variable_detalle (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_registro INT NOT NULL,
    id_variable INT NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    comentario VARCHAR(150) NULL,
    CONSTRAINT fk_detalle_registro
        FOREIGN KEY (id_registro) REFERENCES registro_postcosecha(id_registro)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_detalle_variable
        FOREIGN KEY (id_variable) REFERENCES variable_monitoreo(id_variable)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT uq_detalle_registro_variable UNIQUE (id_registro, id_variable)
) ENGINE=InnoDB;

CREATE TABLE evidencia_registro (
    id_evidencia INT AUTO_INCREMENT PRIMARY KEY,
    id_registro INT NOT NULL,
    nombre_archivo VARCHAR(120) NOT NULL,
    ruta_archivo VARCHAR(255) NOT NULL,
    tipo_archivo VARCHAR(30) NOT NULL,
    fecha_subida DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_evidencia_registro
        FOREIGN KEY (id_registro) REFERENCES registro_postcosecha(id_registro)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE alerta_lote (
    id_alerta INT AUTO_INCREMENT PRIMARY KEY,
    id_registro INT NOT NULL,
    id_variable INT NOT NULL,
    valor_detectado DECIMAL(10,2) NOT NULL,
    mensaje VARCHAR(200) NOT NULL,
    nivel VARCHAR(20) NOT NULL,
    atendida BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_alerta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_alerta_registro
        FOREIGN KEY (id_registro) REFERENCES registro_postcosecha(id_registro)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_alerta_variable
        FOREIGN KEY (id_variable) REFERENCES variable_monitoreo(id_variable)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =========================================================
-- 3. ÍNDICES
-- =========================================================

CREATE INDEX idx_usuario_correo ON usuario(correo);
CREATE INDEX idx_lote_codigo ON lote(codigo_lote);
CREATE INDEX idx_lote_finca ON lote(id_finca);
CREATE INDEX idx_registro_lote_fecha ON registro_postcosecha(id_lote, fecha_hora);
CREATE INDEX idx_registro_usuario ON registro_postcosecha(id_usuario);
CREATE INDEX idx_detalle_variable ON registro_variable_detalle(id_variable);
CREATE INDEX idx_alerta_atendida ON alerta_lote(atendida);

-- =========================================================
-- 4. DATOS DE CATÁLOGO
-- =========================================================

INSERT INTO rol (nombre, descripcion) VALUES
('Administrador', 'Gestiona usuarios, catálogos y configuración general'),
('Operario', 'Registra actividades y variables de postcosecha'),
('Supervisor', 'Consulta historial, alertas y reportes');

INSERT INTO departamento (nombre) VALUES
('Santander'),
('Norte de Santander'),
('Boyacá');

INSERT INTO municipio (id_departamento, nombre) VALUES
(1, 'Bucaramanga'),
(1, 'Floridablanca'),
(1, 'Girón'),
(2, 'Cúcuta'),
(3, 'Tunja');

INSERT INTO variedad_cafe (nombre, descripcion) VALUES
('Castillo', 'Variedad resistente y de alta presencia en Colombia'),
('Caturra', 'Variedad tradicional de buena calidad en taza'),
('Colombia', 'Variedad desarrollada para mejorar resistencia y productividad'),
('Bourbon', 'Variedad reconocida por su calidad'),
('Typica', 'Variedad tradicional de perfil clásico');

INSERT INTO estado_lote (nombre, descripcion) VALUES
('Recibido', 'Lote recién ingresado al proceso'),
('Despulpado', 'Lote después del despulpado'),
('En fermentación', 'Lote en proceso de fermentación'),
('Lavado', 'Lote lavado'),
('En secado', 'Lote en secado'),
('Almacenado', 'Lote almacenado'),
('Finalizado', 'Lote con postcosecha terminada'),
('Observado', 'Lote con novedad o inconsistencia');

INSERT INTO tipo_actividad (nombre, descripcion) VALUES
('Recepción', 'Ingreso inicial del lote'),
('Despulpado', 'Separación de pulpa del grano'),
('Fermentación', 'Proceso de fermentación controlada'),
('Lavado', 'Lavado del café'),
('Secado', 'Proceso de secado'),
('Almacenamiento', 'Resguardo del lote'),
('Inspección', 'Revisión del estado del lote'),
('Corrección', 'Ajuste o novedad registrada');

INSERT INTO unidad_medida (nombre, simbolo, descripcion) VALUES
('Grados Celsius', '°C', 'Temperatura'),
('Porcentaje', '%', 'Porcentaje relativo'),
('Horas', 'h', 'Tiempo en horas'),
('Kilogramos', 'kg', 'Peso del lote'),
('pH', 'pH', 'Nivel de acidez');

INSERT INTO variable_monitoreo (nombre, descripcion, id_unidad_medida, valor_minimo, valor_maximo, requiere_alerta) VALUES
('Temperatura', 'Temperatura del lote o del ambiente', 1, 0.00, 60.00, TRUE),
('Humedad', 'Humedad relativa asociada al proceso', 2, 0.00, 100.00, TRUE),
('Tiempo de fermentación', 'Duración del proceso de fermentación', 3, 0.00, 120.00, FALSE),
('Peso', 'Peso del lote en el momento del registro', 4, 0.00, 5000.00, FALSE),
('pH', 'Nivel de acidez del proceso', 5, 0.00, 14.00, TRUE);

-- =========================================================
-- 5. DATOS DE PRUEBA
-- =========================================================

INSERT INTO usuario (id_rol, nombre, apellido, correo, password_hash, telefono, activo) VALUES
(1, 'Michael', 'Hernandez', 'michael@upb.edu.co', 'hash_admin_123', '3001111111', TRUE),
(2, 'Jorge', 'Osorio', 'jorge@upb.edu.co', 'hash_operario_123', '3002222222', TRUE),
(3, 'Laura', 'Gomez', 'laura@upb.edu.co', 'hash_supervisor_123', '3003333333', TRUE);

INSERT INTO finca (id_municipio, nombre, propietario, direccion, latitud, longitud, area_hectareas, descripcion) VALUES
(2, 'Finca El Recuerdo', 'Pedro Rojas', 'Vereda La Esperanza', 7.1254780, -73.1198450, 3.50, 'Finca pequeña de producción cafetera'),
(3, 'Finca Monte Verde', 'Ana Suarez', 'Vereda El Cedro', 7.0674210, -73.1702580, 5.20, 'Finca con secado artesanal');

INSERT INTO lote (id_finca, id_variedad, id_estado_lote_actual, codigo_lote, fecha_registro, cantidad_kg, observaciones, activo) VALUES
(1, 1, 1, 'LOT-2026-001', '2026-03-01', 250.00, 'Lote inicial de prueba', TRUE),
(1, 2, 3, 'LOT-2026-002', '2026-03-02', 180.00, 'Lote en fermentación', TRUE),
(2, 3, 5, 'LOT-2026-003', '2026-03-03', 320.00, 'Lote en secado', TRUE);

INSERT INTO registro_postcosecha (id_lote, id_usuario, id_tipo_actividad, id_estado_lote, fecha_hora, observacion, ubicacion_registro) VALUES
(1, 2, 1, 1, '2026-03-01 08:00:00', 'Recepción del lote en condiciones normales', 'Zona de recibo'),
(1, 2, 2, 2, '2026-03-01 11:00:00', 'Se realizó despulpado sin novedades', 'Área de despulpado'),
(2, 2, 3, 3, '2026-03-02 09:30:00', 'Inicio de fermentación controlada', 'Tanque 1'),
(3, 2, 5, 5, '2026-03-03 10:15:00', 'Secado en marquesina', 'Patio de secado'),
(3, 3, 7, 8, '2026-03-03 16:00:00', 'Se detectó humedad alta', 'Patio de secado');

INSERT INTO registro_variable_detalle (id_registro, id_variable, valor, comentario) VALUES
(1, 1, 23.50, 'Temperatura ambiente al recibir'),
(1, 2, 68.00, 'Humedad inicial del entorno'),
(1, 4, 250.00, 'Peso recibido'),
(2, 1, 26.20, 'Temperatura durante despulpado'),
(2, 2, 70.00, 'Humedad medida en proceso'),
(3, 1, 28.50, 'Temperatura de fermentación'),
(3, 2, 75.00, 'Humedad de fermentación'),
(3, 3, 18.00, 'Horas estimadas iniciales'),
(3, 5, 4.80, 'Medición de pH'),
(4, 1, 31.00, 'Temperatura en secado'),
(4, 2, 54.00, 'Humedad en secado'),
(5, 2, 82.00, 'Humedad demasiado alta');

INSERT INTO evidencia_registro (id_registro, nombre_archivo, ruta_archivo, tipo_archivo) VALUES
(1, 'recepcion_lote1.jpg', '/uploads/recepcion_lote1.jpg', 'imagen/jpeg'),
(3, 'fermentacion_lote2.jpg', '/uploads/fermentacion_lote2.jpg', 'imagen/jpeg'),
(5, 'alerta_humedad_lote3.jpg', '/uploads/alerta_humedad_lote3.jpg', 'imagen/jpeg');

INSERT INTO alerta_lote (id_registro, id_variable, valor_detectado, mensaje, nivel, atendida) VALUES
(5, 2, 82.00, 'La humedad supera el umbral esperado para la etapa de secado', 'Alta', FALSE);

-- =========================================================
-- 6. CONSULTAS ÚTILES PARA PROBAR EL MODELO
-- =========================================================

-- Ver usuarios con su rol
SELECT 
    u.id_usuario,
    CONCAT(u.nombre, ' ', u.apellido) AS usuario,
    u.correo,
    r.nombre AS rol
FROM usuario u
INNER JOIN rol r ON u.id_rol = r.id_rol;

-- Ver fincas con su municipio y departamento
SELECT
    f.id_finca,
    f.nombre AS finca,
    f.propietario,
    m.nombre AS municipio,
    d.nombre AS departamento
FROM finca f
INNER JOIN municipio m ON f.id_municipio = m.id_municipio
INNER JOIN departamento d ON m.id_departamento = d.id_departamento;

-- Ver lotes con su finca, variedad y estado actual
SELECT
    l.codigo_lote,
    f.nombre AS finca,
    vc.nombre AS variedad,
    el.nombre AS estado_actual,
    l.fecha_registro,
    l.cantidad_kg
FROM lote l
INNER JOIN finca f ON l.id_finca = f.id_finca
INNER JOIN variedad_cafe vc ON l.id_variedad = vc.id_variedad
INNER JOIN estado_lote el ON l.id_estado_lote_actual = el.id_estado_lote;

-- Historial completo de un lote
SELECT
    l.codigo_lote,
    rp.id_registro,
    rp.fecha_hora,
    ta.nombre AS actividad,
    el.nombre AS estado_registrado,
    CONCAT(u.nombre, ' ', u.apellido) AS registrado_por,
    rp.observacion
FROM registro_postcosecha rp
INNER JOIN lote l ON rp.id_lote = l.id_lote
INNER JOIN tipo_actividad ta ON rp.id_tipo_actividad = ta.id_tipo_actividad
INNER JOIN estado_lote el ON rp.id_estado_lote = el.id_estado_lote
INNER JOIN usuario u ON rp.id_usuario = u.id_usuario
WHERE l.codigo_lote = 'LOT-2026-003'
ORDER BY rp.fecha_hora;

-- Variables medidas por registro
SELECT
    rp.id_registro,
    l.codigo_lote,
    vm.nombre AS variable,
    rvd.valor,
    um.simbolo AS unidad,
    rvd.comentario
FROM registro_variable_detalle rvd
INNER JOIN registro_postcosecha rp ON rvd.id_registro = rp.id_registro
INNER JOIN lote l ON rp.id_lote = l.id_lote
INNER JOIN variable_monitoreo vm ON rvd.id_variable = vm.id_variable
INNER JOIN unidad_medida um ON vm.id_unidad_medida = um.id_unidad_medida
ORDER BY rp.id_registro, vm.nombre;

-- Alertas activas
SELECT
    a.id_alerta,
    l.codigo_lote,
    vm.nombre AS variable,
    a.valor_detectado,
    a.mensaje,
    a.nivel,
    a.atendida,
    a.fecha_alerta
FROM alerta_lote a
INNER JOIN registro_postcosecha rp ON a.id_registro = rp.id_registro
INNER JOIN lote l ON rp.id_lote = l.id_lote
INNER JOIN variable_monitoreo vm ON a.id_variable = vm.id_variable
WHERE a.atendida = FALSE;