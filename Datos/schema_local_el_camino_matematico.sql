-- =============================================================================
-- ESQUEMA COMPLETO Y DATOS PARA POSTGRESQL LOCAL - EL CAMINO MATEMÁTICO
-- =============================================================================
-- Puedes ejecutar este archivo completo en pgAdmin 4 (Query Tool)
-- en la base de datos 'el_camino_matematico'

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. TABLA: usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    usuario VARCHAR(50) UNIQUE NOT NULL,
    clave VARCHAR(50) NOT NULL,
    rol VARCHAR(20) DEFAULT 'estudiante',
    user_uuid VARCHAR(100) DEFAULT gen_random_uuid()::text,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. TABLA: preguntas
CREATE TABLE IF NOT EXISTS preguntas (
    id INT PRIMARY KEY,
    operacion TEXT NOT NULL,
    respuesta_correcta TEXT NOT NULL,
    opcion_falsa1 TEXT NOT NULL,
    opcion_falsa2 TEXT NOT NULL,
    opcion_falsa3 TEXT NOT NULL,
    dificultad INT DEFAULT 1,
    categoria VARCHAR(50) DEFAULT 'matematicas',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TABLA: progreso
CREATE TABLE IF NOT EXISTS progreso (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id) ON DELETE CASCADE,
    casilla_actual INT DEFAULT 0,
    tablero_actual VARCHAR(50) DEFAULT 'Tablero_1',
    pregunta_pendiente BOOLEAN DEFAULT FALSE,
    dificultad INT DEFAULT 1,
    monedas INT DEFAULT 0,
    en_examen_final BOOLEAN DEFAULT FALSE,
    examen_correctas INT DEFAULT 0,
    examen_preguntas_respondidas INT DEFAULT 0,
    tomo_camino_corto BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. TABLA: historial_respuestas (Utilizada por el Panel del Maestro)
CREATE TABLE IF NOT EXISTS historial_respuestas (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id) ON DELETE CASCADE,
    categoria VARCHAR(50) NOT NULL,
    es_correcta BOOLEAN NOT NULL,
    tiempo_tardado NUMERIC(8,3) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. TABLA: progreso_album
CREATE TABLE IF NOT EXISTS progreso_album (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL,
    laminas_poseidas INT[] DEFAULT '{}',
    logros_poseidos INT[] DEFAULT '{}',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. TABLA: puntuaciones
CREATE TABLE IF NOT EXISTS puntuaciones (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(100),
    nombre VARCHAR(50),
    casilla INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- USUARIOS INICIALES (DOCENTE Y ESTUDIANTE DEMO)
-- -----------------------------------------------------------------------------
INSERT INTO usuarios (id, usuario, clave, rol, user_uuid)
VALUES 
    (1, 'maestro', '12345', 'maestro', 'a1111111-1111-1111-1111-111111111111'),
    (2, 'rafa', '12345', 'estudiante', 'b9132f37-ba93-4365-82b2-ba2163e49924')
ON CONFLICT (id) DO UPDATE SET 
    usuario = EXCLUDED.usuario, 
    clave = EXCLUDED.clave, 
    rol = EXCLUDED.rol;

SELECT setval(pg_get_serial_sequence('usuarios', 'id'), COALESCE(MAX(id), 1)) FROM usuarios;

INSERT INTO progreso (usuario_id, casilla_actual, dificultad, monedas)
VALUES 
    (1, 0, 1, 0),
    (2, 7, 1, 30)
ON CONFLICT DO NOTHING;

INSERT INTO progreso_album (user_id, laminas_poseidas, logros_poseidos)
VALUES 
    ('b9132f37-ba93-4365-82b2-ba2163e49924', ARRAY[1, 2, 3], ARRAY[2, 3])
ON CONFLICT DO NOTHING;

-- -----------------------------------------------------------------------------
-- CARGA DE LAS 49 PREGUNTAS OFICIALES
-- -----------------------------------------------------------------------------
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (17, '45 dividido en 9', '5', '4', '6', '7', 2, 'division')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (19, '81 dividido en 9', '9', '8', '6', '10', 2, 'division')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (16, '36 dividido en 6', '6', '5', '7', '8', 2, 'division')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (6, '4 por 7', '28', '24', '32', '26', 1, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (20, '9 más 6', '15', '14', '16', '13', 0, 'suma')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (21, '15 menos 8', '7', '6', '8', '9', 0, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (22, '7 por 4', '28', '24', '32', '21', 0, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (23, '18 menos 9', '9', '8', '10', '7', 0, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (24, '8 más 7', '15', '14', '16', '13', 0, 'suma')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (25, '5 por 5', '25', '20', '30', '15', 0, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (26, '14 menos 6', '8', '7', '9', '6', 0, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (27, '6 más 9', '15', '13', '16', '14', 0, 'suma')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (28, '3 por 8', '24', '21', '27', '18', 0, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (29, '20 menos 7', '13', '12', '14', '11', 0, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (30, '45 más 28', '73', '63', '83', '71', 1, 'suma')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (31, '90 menos 34', '56', '46', '66', '54', 1, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (32, '8 por 7', '56', '48', '64', '52', 1, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (33, '64 menos 29', '35', '33', '45', '25', 1, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (34, '12 por 6', '72', '62', '82', '68', 1, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (35, '53 más 39', '92', '82', '102', '94', 1, 'suma')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (36, '75 menos 28', '47', '57', '37', '49', 1, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (37, '9 por 8', '72', '64', '81', '70', 1, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (38, '120 menos 45', '75', '65', '85', '73', 1, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (39, '67 más 45', '112', '102', '122', '110', 1, 'suma')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (40, '72 dividido en 8', '9', '8', '7', '6', 2, 'division')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (41, '15 por 11', '165', '155', '175', '145', 2, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (42, '144 dividido en 6', '24', '22', '26', '20', 2, 'division')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (43, '250 menos 85', '165', '155', '175', '160', 2, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (44, '13 por 9', '117', '107', '127', '119', 2, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (45, '96 dividido en 4', '24', '22', '28', '18', 2, 'division')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (46, '180 más 95', '275', '265', '285', '270', 2, 'suma')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (2, '12 menos 7', '5', '4', '6', '3', 0, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (3, '6 por 3', '18', '12', '16', '20', 0, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (47, '108 dividido en 9', '12', '11', '13', '10', 2, 'division')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (48, '16 por 8', '128', '118', '138', '124', 2, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (4, '15 más 8', '23', '21', '25', '22', 0, 'suma')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (1, '5 más 4', '9', '8', '7', '10', 0, 'suma')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (7, '35 más 14', '49', '48', '50', '45', 1, 'suma')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (12, '14 más 27', '41', '39', '43', '51', 1, 'suma')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (15, '80 más 45', '125', '115', '135', '120', 1, 'suma')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (5, '20 menos 11', '9', '8', '10', '11', 0, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (8, '50 menos 15', '35', '25', '45', '30', 1, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (10, '100 menos 37', '63', '73', '53', '67', 1, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (13, '63 menos 18', '45', '47', '35', '55', 1, 'resta')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (9, '9 por 5', '45', '40', '54', '35', 1, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (11, '8 por 8', '64', '56', '72', '60', 1, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (14, '7 por 6', '42', '48', '36', '44', 1, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (18, '12 por 12', '144', '124', '154', '116', 2, 'multiplicacion')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;
INSERT INTO preguntas (id, operacion, respuesta_correcta, opcion_falsa1, opcion_falsa2, opcion_falsa3, dificultad, categoria)
VALUES (49, '125 dividido en 5', '25', '15', '35', '20', 2, 'division')
ON CONFLICT (id) DO UPDATE SET 
    operacion = EXCLUDED.operacion,
    respuesta_correcta = EXCLUDED.respuesta_correcta,
    opcion_falsa1 = EXCLUDED.opcion_falsa1,
    opcion_falsa2 = EXCLUDED.opcion_falsa2,
    opcion_falsa3 = EXCLUDED.opcion_falsa3,
    dificultad = EXCLUDED.dificultad,
    categoria = EXCLUDED.categoria;

-- -----------------------------------------------------------------------------
-- HISTORIAL DE RESPUESTAS DEMO (Para que el Panel del Maestro muestre gráficos)
-- -----------------------------------------------------------------------------
INSERT INTO historial_respuestas (usuario_id, categoria, es_correcta, tiempo_tardado)
VALUES
    (2, 'suma', true, 4.250),
    (2, 'suma', true, 3.800),
    (2, 'resta', true, 5.120),
    (2, 'resta', false, 7.450),
    (2, 'multiplicacion', true, 6.300),
    (2, 'multiplicacion', true, 5.900),
    (2, 'division', false, 9.100),
    (2, 'division', true, 8.400),
    (2, 'regla_de_tres', true, 11.200)
ON CONFLICT DO NOTHING;

-- Asegurar permisos completos para PostgREST
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres;
