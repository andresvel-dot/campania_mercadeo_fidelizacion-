-- ============================================================================
--  BASE DE DATOS: APP DE TRANSPORTE «COLOMBIA»
--  Esquema relacional normalizado hasta 3FN · MySQL 8.0.16+
--  Coherente con la presentación (12 diapositivas):
--    Slide 04 → 19 tablas en 3 capas (11 catálogos · 5 maestros · 3 transaccionales)
--    Slide 03 → Restricciones del negocio como decisiones de diseño
--    Slide 05 → 8 empleados, cuenta propia, WhatsApp propio, acceso total
--    Slide 06 → Cliente multi-idioma, solo Instagram
--    Slide 07 → Cobertura mundial + tarifa estrictamente por distancia (km)
--    Slide 08 → solicitud_servicio (personas vs cosas, estados como rastreo)
--    Slide 09 → pago (sin pasarela) · interaccion (sin chatbot)
--    Slide 11 → CHECKs, UNIQUEs y verificación 1FN/2FN/3FN
-- ============================================================================

DROP DATABASE IF EXISTS transporte_colombia;
CREATE DATABASE transporte_colombia
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE transporte_colombia;

-- ============================================================================
-- CAPA 1 · CATÁLOGOS (11 tablas) — Slide 04
-- ============================================================================

-- ─── Geografía (Slide 07: cobertura "cualquier lugar del mundo") ───
CREATE TABLE pais (
  id_pais     BIGINT UNSIGNED AUTO_INCREMENT,
  codigo_iso  CHAR(2)     NOT NULL,                 -- ISO 3166-1 alfa-2
  nombre      VARCHAR(80) NOT NULL,
  CONSTRAINT pk_pais        PRIMARY KEY (id_pais),
  CONSTRAINT uq_pais_codigo UNIQUE (codigo_iso)
) ENGINE=InnoDB;

CREATE TABLE ciudad (
  id_ciudad BIGINT UNSIGNED AUTO_INCREMENT,
  fk_pais   BIGINT UNSIGNED NOT NULL,
  nombre    VARCHAR(80) NOT NULL,
  CONSTRAINT pk_ciudad       PRIMARY KEY (id_ciudad),
  CONSTRAINT uq_ciudad       UNIQUE (fk_pais, nombre),  -- 3FN: el país vive solo en pais
  CONSTRAINT fk_ciudad_pais  FOREIGN KEY (fk_pais) REFERENCES pais (id_pais)
) ENGINE=InnoDB;

CREATE TABLE sede (
  id_sede      BIGINT UNSIGNED AUTO_INCREMENT,
  fk_ciudad    BIGINT UNSIGNED NOT NULL,
  nombre       VARCHAR(100) NOT NULL,
  direccion    VARCHAR(160) NOT NULL,
  es_principal BOOLEAN NOT NULL DEFAULT FALSE,  -- casa matriz: Colombia
  CONSTRAINT pk_sede       PRIMARY KEY (id_sede),
  CONSTRAINT fk_sede_ciudad FOREIGN KEY (fk_ciudad) REFERENCES ciudad (id_ciudad)
) ENGINE=InnoDB;

-- ─── Seguridad y permisos (Slide 05: "todos hacen de todo") ───
CREATE TABLE rol (
  id_rol       BIGINT UNSIGNED AUTO_INCREMENT,
  codigo       VARCHAR(30) NOT NULL,
  nombre       VARCHAR(60) NOT NULL,
  acceso_total BOOLEAN NOT NULL DEFAULT TRUE,   -- todos tienen acceso a toda la información
  CONSTRAINT pk_rol        PRIMARY KEY (id_rol),
  CONSTRAINT uq_rol_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

-- ─── Idiomas (Slide 06: "todos los idiomas") ───
CREATE TABLE idioma (
  id_idioma       BIGINT UNSIGNED AUTO_INCREMENT,
  codigo_iso639_1 CHAR(2)     NOT NULL,
  nombre          VARCHAR(50) NOT NULL,
  CONSTRAINT pk_idioma        PRIMARY KEY (id_idioma),
  CONSTRAINT uq_idioma_codigo UNIQUE (codigo_iso639_1)
) ENGINE=InnoDB;

-- ─── Monedas (cobertura mundial → multi-moneda ISO 4217) ───
CREATE TABLE moneda (
  id_moneda      BIGINT UNSIGNED AUTO_INCREMENT,
  codigo_iso4217 CHAR(3)     NOT NULL,
  nombre         VARCHAR(50) NOT NULL,
  simbolo        VARCHAR(8)  NOT NULL,
  CONSTRAINT pk_moneda        PRIMARY KEY (id_moneda),
  CONSTRAINT uq_moneda_codigo UNIQUE (codigo_iso4217)
) ENGINE=InnoDB;

-- ─── Servicios (Slide 03 + 08: EXACTAMENTE 2: personas y cosas) ───
CREATE TABLE tipo_servicio (
  id_tipo_servicio BIGINT UNSIGNED AUTO_INCREMENT,
  codigo VARCHAR(30) NOT NULL,        -- TRANS_PERSONAS | TRANS_COSAS
  nombre VARCHAR(80) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_tipo_servicio      PRIMARY KEY (id_tipo_servicio),
  CONSTRAINT uq_tipo_servicio      UNIQUE (codigo),
  CONSTRAINT chk_solo_dos_servicios CHECK (id_tipo_servicio IN (1, 2))  -- regla del negocio
) ENGINE=InnoDB;

-- ─── Estados de solicitud (Slide 08: "rastreo" sin guías) ───
CREATE TABLE estado_solicitud (
  id_estado BIGINT UNSIGNED AUTO_INCREMENT,
  codigo VARCHAR(30) NOT NULL,
  nombre VARCHAR(60) NOT NULL,
  orden  TINYINT UNSIGNED NOT NULL,
  CONSTRAINT pk_estado       PRIMARY KEY (id_estado),
  CONSTRAINT uq_estado_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

-- ─── Métodos de pago (Slide 03: SIN pasarela → solo métodos manuales) ───
CREATE TABLE metodo_pago (
  id_metodo_pago BIGINT UNSIGNED AUTO_INCREMENT,
  codigo VARCHAR(30) NOT NULL,
  nombre VARCHAR(60) NOT NULL,
  CONSTRAINT pk_metodo_pago       PRIMARY KEY (id_metodo_pago),
  CONSTRAINT uq_metodo_pago_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

-- ─── Canales de contacto (Slide 03: Instagram es la ÚNICA red social) ───
CREATE TABLE canal_contacto (
  id_canal      BIGINT UNSIGNED AUTO_INCREMENT,
  codigo        VARCHAR(30) NOT NULL,
  nombre        VARCHAR(60) NOT NULL,
  es_red_social BOOLEAN NOT NULL DEFAULT FALSE,  -- solo INSTAGRAM = TRUE
  CONSTRAINT pk_canal        PRIMARY KEY (id_canal),
  CONSTRAINT uq_canal_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

-- ─── Políticas del negocio (Slide 03: las restricciones viven como DATO) ───
CREATE TABLE politica_negocio (
  id_politica BIGINT UNSIGNED AUTO_INCREMENT,
  codigo      VARCHAR(40)  NOT NULL,
  categoria   VARCHAR(40)  NOT NULL,   -- RESTRICCION | DISPONIBILIDAD | COBERTURA | TARIFICACION | COMUNICACION
  descripcion VARCHAR(255) NOT NULL,
  activa      BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_politica       PRIMARY KEY (id_politica),
  CONSTRAINT uq_politica_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

-- ============================================================================
-- CAPA 2 · MAESTROS (5 tablas) — Slides 05, 06, 07
-- ============================================================================

-- ─── Empleados (Slide 05: exactamente 8, cada uno con SU WhatsApp) ───
CREATE TABLE empleado (
  id_empleado       BIGINT UNSIGNED AUTO_INCREMENT,
  documento         VARCHAR(20)  NOT NULL,
  nombres           VARCHAR(80)  NOT NULL,
  apellidos         VARCHAR(80)  NOT NULL,
  correo            VARCHAR(120) NOT NULL,
  telefono_whatsapp VARCHAR(20)  NOT NULL,   -- línea de WhatsApp empresarial propia
  fk_rol            BIGINT UNSIGNED NOT NULL,
  fecha_ingreso     DATE NOT NULL,
  activo            BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_empleado           PRIMARY KEY (id_empleado),
  CONSTRAINT uq_empleado_documento UNIQUE (documento),
  CONSTRAINT uq_empleado_correo    UNIQUE (correo),
  CONSTRAINT uq_empleado_whatsapp  UNIQUE (telefono_whatsapp),
  CONSTRAINT fk_empleado_rol       FOREIGN KEY (fk_rol) REFERENCES rol (id_rol)
) ENGINE=InnoDB;

-- ─── Usuarios (Slide 05: relación 1:1 → cuenta propia por empleado) ───
CREATE TABLE usuario (
  id_usuario    BIGINT UNSIGNED AUTO_INCREMENT,
  fk_empleado   BIGINT UNSIGNED NOT NULL,
  username      VARCHAR(50)  NOT NULL,
  password_hash VARCHAR(255) NOT NULL,   -- hash bcrypt/argon2, NUNCA texto plano
  activo        BOOLEAN NOT NULL DEFAULT TRUE,
  ultimo_acceso DATETIME NULL,
  creado_en     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_usuario           PRIMARY KEY (id_usuario),
  CONSTRAINT uq_usuario_empleado  UNIQUE (fk_empleado),  -- 1:1 (3FN: no duplica datos del empleado)
  CONSTRAINT uq_usuario_username  UNIQUE (username),
  CONSTRAINT fk_usuario_empleado  FOREIGN KEY (fk_empleado) REFERENCES empleado (id_empleado)
) ENGINE=InnoDB;

-- ─── Clientes (Slide 06: multi-idioma · Instagram opcional · residencia) ───
CREATE TABLE cliente (
  id_cliente           BIGINT UNSIGNED AUTO_INCREMENT,
  documento            VARCHAR(20) NULL,
  nombres              VARCHAR(80) NOT NULL,
  apellidos            VARCHAR(80) NULL,
  telefono             VARCHAR(20)  NOT NULL,
  correo               VARCHAR(120) NULL,
  fk_idioma_preferido  BIGINT UNSIGNED NOT NULL,
  instagram_usuario    VARCHAR(60) NULL,           -- única red social del negocio
  fk_ciudad_residencia BIGINT UNSIGNED NULL,
  fecha_registro       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activo               BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_cliente            PRIMARY KEY (id_cliente),
  CONSTRAINT uq_cliente_documento  UNIQUE (documento),
  CONSTRAINT fk_cliente_idioma     FOREIGN KEY (fk_idioma_preferido)   REFERENCES idioma (id_idioma),
  CONSTRAINT fk_cliente_ciudad     FOREIGN KEY (fk_ciudad_residencia) REFERENCES ciudad (id_ciudad)
) ENGINE=InnoDB;

-- ─── Ubicaciones (Slide 07: origen y destino de cada servicio) ───
CREATE TABLE ubicacion (
  id_ubicacion BIGINT UNSIGNED AUTO_INCREMENT,
  fk_pais      BIGINT UNSIGNED NOT NULL,
  fk_ciudad    BIGINT UNSIGNED NULL,      -- NULL si el punto solo tiene coordenadas
  direccion    VARCHAR(200) NOT NULL,
  latitud      DECIMAL(9,6) NULL,
  longitud     DECIMAL(9,6) NULL,
  referencia   VARCHAR(200) NULL,
  CONSTRAINT pk_ubicacion       PRIMARY KEY (id_ubicacion),
  CONSTRAINT fk_ubicacion_pais  FOREIGN KEY (fk_pais)   REFERENCES pais (id_pais),
  CONSTRAINT fk_ubicacion_ciudad FOREIGN KEY (fk_ciudad) REFERENCES ciudad (id_ciudad),
  CONSTRAINT chk_ubicacion_punto CHECK (fk_ciudad IS NOT NULL
                                        OR (latitud IS NOT NULL AND longitud IS NOT NULL))
) ENGINE=InnoDB;

-- ─── Tarifas (Slide 07: el precio depende ESTRICTAMENTE de la distancia) ───
CREATE TABLE tarifa (
  id_tarifa        BIGINT UNSIGNED AUTO_INCREMENT,
  fk_tipo_servicio BIGINT UNSIGNED NOT NULL,
  km_desde         DECIMAL(8,2)  NOT NULL DEFAULT 0,
  km_hasta         DECIMAL(8,2)  NOT NULL,           -- 999999.00 = tramo abierto
  valor            DECIMAL(12,2) NOT NULL,
  fk_moneda        BIGINT UNSIGNED NOT NULL,
  vigente_desde    DATE NOT NULL,
  vigente_hasta    DATE NULL,
  activa           BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_tarifa       PRIMARY KEY (id_tarifa),
  CONSTRAINT fk_tarifa_tipo  FOREIGN KEY (fk_tipo_servicio) REFERENCES tipo_servicio (id_tipo_servicio),
  CONSTRAINT fk_tarifa_moneda FOREIGN KEY (fk_moneda)       REFERENCES moneda (id_moneda),
  CONSTRAINT chk_tarifa_tramo CHECK (km_hasta > km_desde),
  CONSTRAINT chk_tarifa_valor CHECK (valor >= 0)
) ENGINE=InnoDB;
-- 3FN (Slide 08): la solicitud NUNCA guarda el valor; solo REFERENCIA la tarifa.

-- ============================================================================
-- CAPA 3 · TRANSACCIONALES (3 tablas) — Slides 08 y 09
-- ============================================================================

-- ─── Solicitud de servicio (núcleo operativo) ───
CREATE TABLE solicitud_servicio (
  id_solicitud         BIGINT UNSIGNED AUTO_INCREMENT,
  fk_cliente           BIGINT UNSIGNED NOT NULL,
  fk_tipo_servicio     BIGINT UNSIGNED NOT NULL,
  fk_ubicacion_origen  BIGINT UNSIGNED NOT NULL,
  fk_ubicacion_destino BIGINT UNSIGNED NOT NULL,
  distancia_km         DECIMAL(8,2) NOT NULL,     -- determina la tarifa aplicada
  fk_tarifa            BIGINT UNSIGNED NOT NULL,
  fk_estado            BIGINT UNSIGNED NOT NULL,
  fk_empleado_asignado BIGINT UNSIGNED NOT NULL,  -- asesor responsable
  fecha_hora_solicitud DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_hora_servicio  DATETIME NULL,             -- 24/7: sin restricción de horario
  cantidad_pasajeros   TINYINT UNSIGNED NULL,     -- SOLO transporte de personas
  descripcion_carga    VARCHAR(255) NULL,         -- SOLO transporte de cosas
  peso_kg              DECIMAL(8,2) NULL,         -- SOLO transporte de cosas
  notas                VARCHAR(500) NULL,
  CONSTRAINT pk_solicitud       PRIMARY KEY (id_solicitud),
  CONSTRAINT fk_sol_cliente     FOREIGN KEY (fk_cliente)           REFERENCES cliente (id_cliente),
  CONSTRAINT fk_sol_tipo        FOREIGN KEY (fk_tipo_servicio)     REFERENCES tipo_servicio (id_tipo_servicio),
  CONSTRAINT fk_sol_origen      FOREIGN KEY (fk_ubicacion_origen)  REFERENCES ubicacion (id_ubicacion),
  CONSTRAINT fk_sol_destino     FOREIGN KEY (fk_ubicacion_destino) REFERENCES ubicacion (id_ubicacion),
  CONSTRAINT fk_sol_tarifa      FOREIGN KEY (fk_tarifa)            REFERENCES tarifa (id_tarifa),
  CONSTRAINT fk_sol_estado      FOREIGN KEY (fk_estado)            REFERENCES estado_solicitud (id_estado),
  CONSTRAINT fk_sol_empleado    FOREIGN KEY (fk_empleado_asignado) REFERENCES empleado (id_empleado),
  CONSTRAINT chk_sol_rutas      CHECK (fk_ubicacion_origen <> fk_ubicacion_destino),
  CONSTRAINT chk_sol_distancia  CHECK (distancia_km > 0)
) ENGINE=InnoDB;

-- ─── Pago (Slide 09: SIN pasarela → el asesor recibe y registra) ───
CREATE TABLE pago (
  id_pago             BIGINT UNSIGNED AUTO_INCREMENT,
  fk_solicitud        BIGINT UNSIGNED NOT NULL,
  monto               DECIMAL(12,2) NOT NULL,
  fk_moneda           BIGINT UNSIGNED NOT NULL,
  fk_metodo_pago      BIGINT UNSIGNED NOT NULL,
  fecha_hora_pago     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fk_empleado_recibio BIGINT UNSIGNED NOT NULL,   -- quién cobró (trazabilidad)
  referencia_externa  VARCHAR(80) NULL,           -- nro. de transferencia, si aplica
  CONSTRAINT pk_pago          PRIMARY KEY (id_pago),
  CONSTRAINT fk_pago_solicitud FOREIGN KEY (fk_solicitud)       REFERENCES solicitud_servicio (id_solicitud),
  CONSTRAINT fk_pago_moneda    FOREIGN KEY (fk_moneda)          REFERENCES moneda (id_moneda),
  CONSTRAINT fk_pago_metodo    FOREIGN KEY (fk_metodo_pago)     REFERENCES metodo_pago (id_metodo_pago),
  CONSTRAINT fk_pago_empleado  FOREIGN KEY (fk_empleado_recibio) REFERENCES empleado (id_empleado),
  CONSTRAINT chk_pago_monto    CHECK (monto >= 0)
) ENGINE=InnoDB;

-- ─── Interacción (Slide 09: SIN chatbot → contacto humano directo) ───
CREATE TABLE interaccion (
  id_interaccion BIGINT UNSIGNED AUTO_INCREMENT,
  fk_cliente   BIGINT UNSIGNED NOT NULL,
  fk_empleado  BIGINT UNSIGNED NOT NULL,
  fk_canal     BIGINT UNSIGNED NOT NULL,
  fk_idioma    BIGINT UNSIGNED NOT NULL,
  fk_solicitud BIGINT UNSIGNED NULL,       -- opcional: asociada a un servicio
  fecha_hora   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resumen      VARCHAR(500) NOT NULL,
  CONSTRAINT pk_interaccion     PRIMARY KEY (id_interaccion),
  CONSTRAINT fk_int_cliente     FOREIGN KEY (fk_cliente)   REFERENCES cliente (id_cliente),
  CONSTRAINT fk_int_empleado    FOREIGN KEY (fk_empleado)  REFERENCES empleado (id_empleado),
  CONSTRAINT fk_int_canal       FOREIGN KEY (fk_canal)     REFERENCES canal_contacto (id_canal),
  CONSTRAINT fk_int_idioma      FOREIGN KEY (fk_idioma)    REFERENCES idioma (id_idioma),
  CONSTRAINT fk_int_solicitud   FOREIGN KEY (fk_solicitud) REFERENCES solicitud_servicio (id_solicitud)
) ENGINE=InnoDB;

-- ============================================================================
-- ÍNDICES DE CONSULTA (Slide 04 · rendimiento operativo)
-- ============================================================================
CREATE INDEX idx_sol_cliente  ON solicitud_servicio (fk_cliente);
CREATE INDEX idx_sol_estado   ON solicitud_servicio (fk_estado);
CREATE INDEX idx_sol_fecha    ON solicitud_servicio (fecha_hora_solicitud);
CREATE INDEX idx_sol_empleado ON solicitud_servicio (fk_empleado_asignado);
CREATE INDEX idx_pago_sol     ON pago (fk_solicitud);
CREATE INDEX idx_int_cliente  ON interaccion (fk_cliente);
CREATE INDEX idx_tarifa_busq  ON tarifa (fk_tipo_servicio, km_desde, km_hasta);

-- ============================================================================
-- TRIGGERS DE REGLAS DEL NEGOCIO (Slide 08: validación por tipo de servicio)
-- ============================================================================

-- Personas → exige pasajeros y prohíbe campos de carga
DELIMITER $$ CREATE TRIGGER trg_sol_tipo_personas
BEFORE INSERT ON solicitud_servicio
FOR EACH ROW
BEGIN
  DECLARE v_codigo VARCHAR(30);
  SELECT codigo INTO v_codigo FROM tipo_servicio
    WHERE id_tipo_servicio = NEW.fk_tipo_servicio;

  IF v_codigo = 'TRANS_PERSONAS' THEN
    IF NEW.cantidad_pasajeros IS NULL OR NEW.cantidad_pasajeros < 1 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transporte de personas: cantidad_pasajeros es obligatorio (>=1)';
    END IF;
    IF NEW.descripcion_carga IS NOT NULL OR NEW.peso_kg IS NOT NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transporte de personas: no se permiten descripcion_carga ni peso_kg';
    END IF;
  END IF;

  IF v_codigo = 'TRANS_COSAS' THEN
    IF NEW.descripcion_carga IS NULL OR CHAR_LENGTH(NEW.descripcion_carga) = 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transporte de cosas: descripcion_carga es obligatoria';
    END IF;
    IF NEW.cantidad_pasajeros IS NOT NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transporte de cosas: no se permite cantidad_pasajeros';
    END IF;
  END IF;
END$$ 
-- La distancia de la solicitud debe caer dentro del tramo de la tarifa referenciada
CREATE TRIGGER trg_sol_tarifa_valida
BEFORE INSERT ON solicitud_servicio
FOR EACH ROW
BEGIN
  DECLARE v_ok TINYINT DEFAULT 0;
  SELECT COUNT(*) INTO v_ok FROM tarifa
   WHERE id_tarifa = NEW.fk_tarifa
     AND NEW.distancia_km >= km_desde
     AND NEW.distancia_km <  km_hasta
     AND activa = TRUE;
  IF v_ok = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La distancia_km no corresponde al tramo de la tarifa referenciada';
  END IF;
END$$ DELIMITER ;

-- ============================================================================
-- DATOS SEMILLA — Slides 01, 02, 05, 07
-- ============================================================================

-- Geografía (cobertura mundial; Colombia como casa matriz)
INSERT INTO pais (codigo_iso, nombre) VALUES
  ('CO','Colombia'), ('US','Estados Unidos'), ('ES','España'), ('MX','México');

INSERT INTO ciudad (fk_pais, nombre) VALUES
  (1,'Medellín'), (1,'Bogotá'), (1,'Cartagena'), (2,'Miami'), (3,'Madrid'), (4,'Cancún');

INSERT INTO sede (fk_ciudad, nombre, direccion, es_principal) VALUES
  (1, 'Casa Matriz — Colombia', 'Calle principal, Medellín', TRUE);

INSERT INTO rol (codigo, nombre) VALUES
  ('ASESOR_INTEGRAL', 'Asesor integral: acceso total a toda la información');

-- Todos los idiomas (base ISO 639-1 ampliable)
INSERT INTO idioma (codigo_iso639_1, nombre) VALUES
  ('es','Español'), ('en','English'), ('pt','Português'), ('fr','Français'),
  ('de','Deutsch'), ('it','Italiano'), ('zh','中文'), ('ar','العربية'),
  ('ja','日本語'), ('ko','한국어'), ('ru','Русский'), ('ht','Kreyòl');

INSERT INTO moneda (codigo_iso4217, nombre, simbolo) VALUES
  ('COP','Peso colombiano','$'), ('USD','Dólar estadounidense','US$'),
  ('EUR','Euro','€'), ('MXN','Peso mexicano','MX$');

-- Los 2 servicios EXACTOS (Slide 08: catálogo cerrado)
INSERT INTO tipo_servicio (id_tipo_servicio, codigo, nombre) VALUES
  (1,'TRANS_PERSONAS','Transporte de personas'),
  (2,'TRANS_COSAS','Transporte de cosas');

INSERT INTO estado_solicitud (codigo, nombre, orden) VALUES
  ('SOLICITADA','Solicitada',1), ('CONFIRMADA','Confirmada por asesor',2),
  ('EN_CURSO','En curso',3), ('COMPLETADA','Completada',4), ('CANCELADA','Cancelada',0);

-- Métodos manuales (Slide 03: sin pasarela)
INSERT INTO metodo_pago (codigo, nombre) VALUES
  ('EFECTIVO','Efectivo'), ('TRANSFERENCIA','Transferencia bancaria'),
  ('NEQUI','Nequi'), ('DAVIPLATA','Daviplata'), ('OTRO','Otro');

-- Canales (Slide 03: WhatsApp del asesor + Instagram como ÚNICA red social)
INSERT INTO canal_contacto (codigo, nombre, es_red_social) VALUES
  ('WHATSAPP','WhatsApp (línea del asesor)',FALSE),
  ('INSTAGRAM','Instagram (única red social)',TRUE),
  ('LLAMADA','Llamada telefónica',FALSE),
  ('PRESENCIAL','Atención presencial',FALSE);

-- Restricciones del negocio documentadas como dato (Slide 03)
INSERT INTO politica_negocio (codigo, categoria, descripcion) VALUES
  ('CERO_MASCOTAS','RESTRICCION','Cero mascotas: no se transportan animales bajo ninguna circunstancia.'),
  ('SIN_GUIAS','RESTRICCION','Sin guías ni números de rastreo: el seguimiento lo hace el asesor.'),
  ('SIN_PASARELA','RESTRICCION','Sin pasarela de pago: el pago se realiza directamente con el asesor.'),
  ('SIN_PROMOCIONES','RESTRICCION','Sin promociones ni descuentos: el precio es la tarifa vigente.'),
  ('SIN_CHATBOT','RESTRICCION','Sin chatbot: la comunicación es directa con un asesor humano.'),
  ('ATENCION_24_7','DISPONIBILIDAD','Servicio disponible 24 horas, 7 días a la semana.'),
  ('COBERTURA_MUNDIAL','COBERTURA','Cualquier lugar del mundo; casa matriz en Colombia.'),
  ('TARIFA_POR_DISTANCIA','TARIFICACION','Las tarifas dependen estrictamente de la distancia (km) del trayecto.'),
  ('SOLO_INSTAGRAM','COMUNICACION','Instagram es la única red social oficial de la empresa.'),
  ('OCHO_EMPLEADOS','OPERACION','La aplicación es gestionada exactamente por 8 empleados con acceso total.');

-- Tarifas por tramo de distancia (Slide 07: mismo ejemplo de la presentación)
INSERT INTO tarifa (fk_tipo_servicio, km_desde, km_hasta, valor, fk_moneda, vigente_desde) VALUES
  (1,   0.00,    15.00,  12000.00, 1, '2025-01-01'),
  (1,  15.00,    50.00,  30000.00, 1, '2025-01-01'),
  (1,  50.00,   200.00,  80000.00, 1, '2025-01-01'),
  (1, 200.00, 999999.00, 250000.00, 1, '2025-01-01'),
  (2,   0.00,    15.00,  15000.00, 1, '2025-01-01'),
  (2,  15.00,    50.00,  40000.00, 1, '2025-01-01'),
  (2,  50.00,   200.00, 120000.00, 1, '2025-01-01'),
  (2, 200.00, 999999.00, 400000.00, 1, '2025-01-01');

-- Los 8 empleados (Slide 05): cuenta propia + WhatsApp propio
INSERT INTO empleado (documento, nombres, apellidos, correo, telefono_whatsapp, fk_rol, fecha_ingreso) VALUES
  ('CC-1001','Ana María','Restrepo Gómez','ana.restrepo@colombiatransporte.com','+57 300 000 0001',1,'2024-01-15'),
  ('CC-1002','Carlos Andrés','Muñoz Pérez','carlos.munoz@colombiatransporte.com','+57 300 000 0002',1,'2024-01-15'),
  ('CC-1003','Luisa Fernanda','Ospina Ruiz','luisa.ospina@colombiatransporte.com','+57 300 000 0003',1,'2024-02-01'),
  ('CC-1004','Jhon Fredy','Betancur Salas','jhon.betancur@colombiatransporte.com','+57 300 000 0004',1,'2024-02-01'),
  ('CC-1005','Sara Lucía','Cárdenas Mejía','sara.cardenas@colombiatransporte.com','+57 300 000 0005',1,'2024-03-10'),
  ('CC-1006','Daniel Esteban','Vélez Arango','daniel.velez@colombiatransporte.com','+57 300 000 0006',1,'2024-03-10'),
  ('CC-1007','Valentina','Duque Marín','valentina.duque@colombiatransporte.com','+57 300 000 0007',1,'2024-04-05'),
  ('CC-1008','Sebastián','Flórez Hoyos','sebastian.florez@colombiatransporte.com','+57 300 000 0008',1,'2024-04-05');

INSERT INTO usuario (fk_empleado, username, password_hash) VALUES
  (1,'ana.restrepo','$2y$10$REEMPLAZAR_POR_HASH_REAL_01'),
  (2,'carlos.munoz','$2y$10$REEMPLAZAR_POR_HASH_REAL_02'),
  (3,'luisa.ospina','$2y$10$REEMPLAZAR_POR_HASH_REAL_03'),
  (4,'jhon.betancur','$2y$10$REEMPLAZAR_POR_HASH_REAL_04'),
  (5,'sara.cardenas','$2y$10$REEMPLAZAR_POR_HASH_REAL_05'),
  (6,'daniel.velez','$2y$10$REEMPLAZAR_POR_HASH_REAL_06'),
  (7,'valentina.duque','$2y$10$REEMPLAZAR_POR_HASH_REAL_07'),
  (8,'sebastian.florez','$2y$10$REEMPLAZAR_POR_HASH_REAL_08');

-- Cliente de ejemplo (Slide 06: idioma EN + Instagram)
INSERT INTO cliente (documento, nombres, apellidos, telefono, correo, fk_idioma_preferido, instagram_usuario, fk_ciudad_residencia)
VALUES ('P-8001','John','Smith','+1 305 555 0102','john@email.com',2,'@johnsmith',4);

-- Ubicaciones de ejemplo (origen y destino)
INSERT INTO ubicacion (fk_pais, fk_ciudad, direccion, latitud, longitud, referencia) VALUES
  (1, 1, 'Cra. 70 #45-202, Medellín', 6.244200, -75.581200, 'Frente al parque principal'),
  (1, 2, 'Calle 100 #15-20, Bogotá',  4.676800, -74.047600, 'Torre norte');

-- Servicio de personas: 413.5 km → tramo 200+ → tarifa $250.000
INSERT INTO solicitud_servicio
  (fk_cliente, fk_tipo_servicio, fk_ubicacion_origen, fk_ubicacion_destino,
   distancia_km, fk_tarifa, fk_estado, fk_empleado_asignado, fecha_hora_solicitud, cantidad_pasajeros)
VALUES
  (1, 1, 1, 2, 413.50, 4, 2, 3, NOW(), 2);

-- Pago directo con el asesor (Slide 09: sin pasarela)
INSERT INTO pago (fk_solicitud, monto, fk_moneda, fk_metodo_pago, fk_empleado_recibio)
VALUES (1, 250000.00, 1, 1, 3);

-- Interacción humana (Slide 09: sin chatbot)
INSERT INTO interaccion (fk_cliente, fk_empleado, fk_canal, fk_idioma, fk_solicitud, resumen)
VALUES (1, 3, 1, 1, 1, 'Cliente contactó por WhatsApp para cotizar viaje Medellín–Bogotá. Asesor confirmó tarifa por distancia.');

-- ============================================================================
-- VISTAS ÚTILES (consultas de la operación)
-- ============================================================================

-- Detalle completo de cada servicio con su precio calculado desde tarifa (3FN)
CREATE OR REPLACE VIEW vw_servicios_detalle AS
SELECT
  s.id_solicitud,
  CONCAT(c.nombres, ' ', IFNULL(c.apellidos,''))          AS cliente,
  ts.nombre                                               AS tipo_servicio,
 uo.direccion                                             AS origen,
  ud.direccion                                            AS destino,
  s.distancia_km,
  t.valor                                                 AS tarifa_aplicada,
  m.simbolo                                               AS moneda,
  e.nombre                                                AS estado,
  CONCAT(a.nombres, ' ', a.apellidos)                     AS asesor_asignado,
  s.fecha_hora_solicitud,
  s.cantidad_pasajeros,
  s.descripcion_carga,
  s.peso_kg
FROM solicitud_servicio s
JOIN cliente           c  ON c.id_cliente           = s.fk_cliente
JOIN tipo_servicio     ts ON ts.id_tipo_servicio    = s.fk_tipo_servicio
JOIN ubicacion         uo ON uo.id_ubicacion        = s.fk_ubicacion_origen
JOIN ubicacion         ud ON ud.id_ubicacion        = s.fk_ubicacion_destino
JOIN tarifa            t  ON t.id_tarifa            = s.fk_tarifa
JOIN moneda            m  ON m.id_moneda            = t.fk_moneda
JOIN estado_solicitud  e  ON e.id_estado            = s.fk_estado
JOIN empleado          a  ON a.id_empleado          = s.fk_empleado_asignado;

-- Resumen de pagos por asesor (trazabilidad del cobro directo)
CREATE OR REPLACE VIEW vw_pagos_por_asesor AS
SELECT
  CONCAT(e.nombres,' ',e.apellidos)   AS asesor,
  COUNT(p.id_pago)                    AS pagos_registrados,
  SUM(p.monto)                        AS total_recaudado,
  mo.simbolo                          AS moneda
FROM pago p
JOIN empleado e ON e.id_empleado = p.fk_empleado_recibio
JOIN moneda   mo ON mo.id_moneda  = p.fk_moneda
GROUP BY e.id_empleado, mo.id_moneda;

-- ============================================================================
-- CONSULTAS DE VERIFICACIÓN (Slide 11 · calidad del diseño)
-- ============================================================================

-- ¿Cuántos empleados activos hay? → debe ser exactamente 8
SELECT COUNT(*) AS empleados_activos FROM empleado WHERE activo = TRUE;

-- ¿El catálogo de servicios tiene exactamente 2 filas?
SELECT COUNT(*) AS total_servicios FROM tipo_servicio;   -- 2

-- ¿Instagram es la única red social?
SELECT codigo FROM canal_contacto WHERE es_red_social = TRUE;  -- INSTAGRAM

-- ¿Qué restricciones del negocio están activas?
SELECT categoria, codigo, descripcion FROM politica_negocio WHERE activa ORDER BY categoria;

-- Tarifas vigentes por servicio (tramos sin solape)
SELECT ts.codigo AS servicio, t.km_desde, t.km_hasta, t.valor
FROM tarifa t JOIN tipo_servicio ts ON ts.id_tipo_servicio = t.fk_tipo_servicio
WHERE t.activa = TRUE
ORDER BY ts.codigo, t.km_desde;