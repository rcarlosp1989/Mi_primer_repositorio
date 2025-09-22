-- Código completo de creación
-- ubicaciones.csv
-- id_ubicacion,nombre,direccion,tipo_zona,numero_viviendas
-- 1,Villa Los Pinos,Calle Principal 123,Residencial,45
CREATE DATABASE IF NOT EXISTS Residuos_Urbanizaciones ;
USE Residuos_Urbanizaciones ;

CREATE TABLE IF NOT EXISTS ubicaciones (
    id_ubicacion INT AUTO_INCREMENT,
    nombre VARCHAR(30) NOT NULL,
    direccion VARCHAR(30) NOT NULL,
    tipo_zona VARCHAR(15) NOT NULL,
    numero_viviendas INT NOT NULL,
    PRIMARY KEY (id_ubicacion)
);


CREATE TABLE IF NOT EXISTS tipos_residuo (
    id_tipo_residuo INT AUTO_INCREMENT,
    nombre VARCHAR(30) NOT NULL,
    categoria VARCHAR(20) NOT NULL,
    descripcion TEXT,
    PRIMARY KEY (id_tipo_residuo)
);

-- recolecciones.csv
-- id_recoleccion,id_ubicacion,fecha_recoleccion,dia_semana,hora_recoleccion,vehiculo_recolector
-- 1,1,2024-01-02,Martes,08:30:00,CAM-001
CREATE TABLE IF NOT EXISTS recolecciones (
    id_recoleccion INT AUTO_INCREMENT,
    id_ubicacion INT NOT NULL,
    fecha_recoleccion DATE NOT NULL,
    dia_semana VARCHAR(10) NOT NULL,
    hora_recoleccion TIME NOT NULL,
    vehiculo_recolector CHAR(7) NOT NULL,
    PRIMARY KEY (id_recoleccion),
    FOREIGN KEY (id_ubicacion)
        REFERENCES ubicaciones (id_ubicacion)
        ON DELETE CASCADE ON UPDATE CASCADE
);
-- residuos_recolectados.csv
-- Estructura de datos:
-- id_residuo_recolectado,id_recoleccion,id_tipo_residuo,volumen_kg,separado_correctamente
-- 1,1,1,45.5,1

CREATE TABLE IF NOT EXISTS residuos_recolectados (
    id_residuo_recolectado INT  AUTO_INCREMENT,
    id_recoleccion INT,
    id_tipo_residuo INT,
    volumen_kg DECIMAL(10 , 2 ),
    separado_correctamente BOOLEAN,
    PRIMARY KEY (id_residuo_recolectado),
    FOREIGN KEY (id_recoleccion)
        REFERENCES recolecciones (id_recoleccion)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_tipo_residuo)
        REFERENCES tipos_residuo (id_tipo_residuo)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Código completo de inserción
INSERT INTO ubicaciones (nombre, direccion, tipo_zona, numero_viviendas) VALUES
('Villa Los Pinos', 'Calle Principal 123', 'Residencial', 45),
('Conjunto San Carlos', 'Avenida Central 456', 'Residencial', 32),
('Plaza Comercial Norte', 'Boulevard Norte 789', 'Comercial', 8),
('Residencial Las Flores', 'Calle Flores 234', 'Residencial', 28),
('Centro Comercial Sur', 'Avenida Sur 567', 'Comercial', 12),
('Urbanización El Bosque', 'Calle Bosque 890', 'Mixta', 38),
('Complejo Los Cedros', 'Avenida Cedros 345', 'Residencial', 50),
('Plaza de Negocios', 'Boulevard Empresarial 678', 'Comercial', 15),
('Fraccionamiento Valle Verde', 'Calle Valle 901', 'Residencial', 42),
('Centro Mixto Alameda', 'Avenida Alameda 123', 'Mixta', 25);

SELECT * FROM residuos_recolectados;


-- Código completo de consultas varias de analis de datos
/* ========================================
   1. Volumen total de residuos por tipo
   ======================================== */
SELECT tr.nombre AS tipo_residuo,
       SUM(rr.volumen_kg) AS total_kg
FROM residuos_recolectados rr
JOIN tipos_residuo tr ON rr.id_tipo_residuo = tr.id_tipo_residuo
GROUP BY tr.nombre
ORDER BY total_kg DESC;


/* ========================================
   2. Residuos recolectados por ubicación
   ======================================== */
SELECT u.nombre AS ubicacion,
       SUM(rr.volumen_kg) AS total_kg
FROM residuos_recolectados rr
JOIN recolecciones r ON rr.id_recoleccion = r.id_recoleccion
JOIN ubicaciones u ON r.id_ubicacion = u.id_ubicacion
GROUP BY u.nombre
ORDER BY total_kg DESC;


/* ========================================
   3. Tendencia de residuos por día de la semana
   ======================================== */
SELECT r.dia_semana,
       tr.nombre AS tipo_residuo,
       SUM(rr.volumen_kg) AS total_kg
FROM residuos_recolectados rr
JOIN recolecciones r ON rr.id_recoleccion = r.id_recoleccion
JOIN tipos_residuo tr ON rr.id_tipo_residuo = tr.id_tipo_residuo
GROUP BY r.dia_semana, tr.nombre
ORDER BY r.dia_semana, total_kg DESC;


/* ========================================
   4. Porcentaje de residuos separados correctamente
   ======================================== */
SELECT 
    CONCAT(ROUND(
        (SUM(CASE WHEN rr.separado_correctamente = 1 THEN 1 ELSE 0 END) * 100.0) 
        / COUNT(*), 2
    ), '%') AS porcentaje_correcto
FROM residuos_recolectados rr;


/* ========================================
   5. Reporte de eficiencia por vehículo recolector
   ======================================== */
SELECT r.vehiculo_recolector,
       COUNT(DISTINCT r.id_recoleccion) AS numero_recolecciones,
       SUM(rr.volumen_kg) AS total_kg
FROM recolecciones r
JOIN residuos_recolectados rr ON r.id_recoleccion = rr.id_recoleccion
GROUP BY r.vehiculo_recolector
ORDER BY total_kg DESC;


/* ========================================
   6. Volumen promedio por vivienda en cada ubicación
   ======================================== */
SELECT u.nombre AS ubicacion,
       ROUND(SUM(rr.volumen_kg) / NULLIF(u.numero_viviendas, 0), 2) AS promedio_kg_por_vivienda
FROM residuos_recolectados rr
JOIN recolecciones r ON rr.id_recoleccion = r.id_recoleccion
JOIN ubicaciones u ON r.id_ubicacion = u.id_ubicacion
GROUP BY u.nombre, u.numero_viviendas
ORDER BY promedio_kg_por_vivienda DESC;


-- CÓDIGO DE CONSULTAS CON RESPECTO A LAS PREGUNTAS DE ANÁLISIS

#¿QUÉ TIPO DE RESIDUO SE GENERA CON MAYOR FRECUENCIA EN CADA UBICACIÓN?

WITH residuos_rank AS (
    SELECT 
        u.nombre AS ubicacion,
        tr.nombre AS tipo_residuo,
        SUM(rr.volumen_kg) AS total_kg,
        ROW_NUMBER() OVER (
            PARTITION BY u.nombre 
            ORDER BY SUM(rr.volumen_kg) DESC
        ) AS rn
    FROM residuos_recolectados rr
    JOIN recolecciones r ON rr.id_recoleccion = r.id_recoleccion
    JOIN ubicaciones u ON r.id_ubicacion = u.id_ubicacion
    JOIN tipos_residuo tr ON rr.id_tipo_residuo = tr.id_tipo_residuo
    GROUP BY u.nombre, tr.nombre
)
SELECT 
    ubicacion,
    tipo_residuo,
    total_kg
FROM residuos_rank
WHERE rn = 1
ORDER BY total_kg desc;
#COMPLEMENTO PARA LA PREGUNTA 1
-- LOS RESIDUOS DE COCINA SE ESTÁN SEPARANDO CORRECTAMENTE?

select separado_correctamente,categoria, nombre, count(*) as cantidad_residuos_recolectados
from residuos_recolectados re
join tipos_residuo tp on re.id_tipo_residuo = tp.id_tipo_residuo
where nombre = 'Residuos de cocina' 
group by separado_correctamente, categoria, nombre;


-- QUÉ DÍAS DE LA SEMANA TIENE MAYOR VOLUMEN DE RECOLECCIÓN


SELECT 
    r.dia_semana,
    SUM(rr.volumen_kg) AS total_kg
FROM residuos_recolectados rr
JOIN recolecciones r ON rr.id_recoleccion = r.id_recoleccion
GROUP BY r.dia_semana
ORDER BY total_kg DESC;


#¿QUÉ UBICACIONES TIENEN MAYOR EFICIENCIA EN LA SEPARACIÓN DE RESIDUOS RECICLABLES?
#(EFICIENCIA = % DE RESIDUOS SEPARADOS CORRECTAMENTE EN CADA UBICACIÓN)


SELECT 
    u.nombre AS ubicacion,
    CONCAT(
        ROUND(
            (SUM(CASE WHEN rr.separado_correctamente = 1 THEN 1 ELSE 0 END) * 100.0) 
            / COUNT(*),
        2), '%'
    ) AS porcentaje_correcto
FROM residuos_recolectados rr
JOIN recolecciones r ON rr.id_recoleccion = r.id_recoleccion
JOIN ubicaciones u ON r.id_ubicacion = u.id_ubicacion
JOIN tipos_residuo tr ON rr.id_tipo_residuo = tr.id_tipo_residuo
WHERE tr.categoria = 'Reciclable'
GROUP BY u.nombre
ORDER BY porcentaje_correcto DESC;


-- CÓDIGO DE CREACIÓN DE ÍNDICES
-- CREANDO INDICE 

-- Para acelerar JOINs y análisis por ubicación/tipo
CREATE INDEX idx_residuos_recolectados_recoleccion_tipo
ON residuos_recolectados (id_recoleccion, id_tipo_residuo);

-- Para consultas sobre residuos separados correctamente
CREATE INDEX idx_residuos_tipo_separado
ON residuos_recolectados (id_tipo_residuo, separado_correctamente);

-- Para análisis por día de la semana
CREATE INDEX idx_recolecciones_dia
ON recolecciones (dia_semana);

-- Para eficiencia por ubicación
CREATE INDEX idx_recolecciones_ubicacion
ON recolecciones (id_ubicacion);



-- CÓDIGO USO DE EXPLAIN
-- USANDO EXPLAIN

-- ¿Qué tipo de residuo se genera con mayor frecuencia en cada ubicación?

EXPLAIN
WITH residuos_rank AS (
    SELECT 
        u.nombre AS ubicacion,
        tr.nombre AS tipo_residuo,
        SUM(rr.volumen_kg) AS total_kg,
        ROW_NUMBER() OVER (
            PARTITION BY u.nombre 
            ORDER BY SUM(rr.volumen_kg) DESC
        ) AS rn
    FROM residuos_recolectados rr
    JOIN recolecciones r ON rr.id_recoleccion = r.id_recoleccion
    JOIN ubicaciones u ON r.id_ubicacion = u.id_ubicacion
    JOIN tipos_residuo tr ON rr.id_tipo_residuo = tr.id_tipo_residuo
    GROUP BY u.nombre, tr.nombre
)
SELECT 
    ubicacion,
    tipo_residuo,
    total_kg
FROM residuos_rank
WHERE rn = 1
ORDER BY total_kg DESC;

-- ¿Los residuos de cocina se están separando correctamente?

EXPLAIN
SELECT 
    separado_correctamente,
    categoria,
    nombre, 
    COUNT(*) AS cantidad_residuos_recolectados
FROM residuos_recolectados re
JOIN tipos_residuo tp 
    ON re.id_tipo_residuo = tp.id_tipo_residuo
WHERE nombre = 'Residuos de cocina' 
GROUP BY separado_correctamente, categoria, nombre;

-- ¿Qué días de la semana tienen mayor volumen de recolección?

EXPLAIN
SELECT 
    r.dia_semana,
    SUM(rr.volumen_kg) AS total_kg
FROM residuos_recolectados rr
JOIN recolecciones r ON rr.id_recoleccion = r.id_recoleccion
GROUP BY r.dia_semana
ORDER BY total_kg DESC;

-- ¿QUÉ UBICACIONES TIENEN MAYOR EFICIENCIA EN LA SEPARACIÓN DE RESIDUOS RECICLABLES?
EXPLAIN
SELECT 
    u.nombre AS ubicacion,
    CONCAT(
        ROUND(
            (SUM(CASE WHEN rr.separado_correctamente = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*),
        2), '%'
    ) AS porcentaje_correcto
FROM residuos_recolectados rr
JOIN recolecciones r ON rr.id_recoleccion = r.id_recoleccion
JOIN ubicaciones u ON r.id_ubicacion = u.id_ubicacion
GROUP BY u.nombre
ORDER BY porcentaje_correcto DESC;
