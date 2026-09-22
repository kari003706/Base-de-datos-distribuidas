/*========================================================
  PRÁCTICA 3 – PARTICIONAMIENTO POR AÑO (COVID)
  Objetivo: Restaurar BD, crear filegroups por año,
  definir función/esquema de partición y validar consultas.
========================================================*/

/*========================================================
0) RESTAURAR BASE DE DATOS DESDE BACKUP
========================================================*/
RESTORE FILELISTONLY
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Backup\covidHistorico2.bak';

RESTORE DATABASE CovidHistorico2
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Backup\covidHistorico2.bak'
WITH 
MOVE 'covidHistorico' 
TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\CovidHistorico2.mdf',
MOVE 'covidHistorico_log' 
TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\CovidHistorico2_log.ldf',
REPLACE, RECOVERY;
GO

USE CovidHistorico2;
GO

/*========================================================
1) VERIFICAR DISTRIBUCIÓN DE AÑOS EN LA TABLA STAGING
   (datoscovid)
========================================================*/
SELECT YEAR(FECHA_INGRESO) AS Anio, COUNT(*) AS Registros
FROM datoscovid
GROUP BY YEAR(FECHA_INGRESO)
ORDER BY Anio;
GO

/*========================================================
2) CREAR FILEGROUPS POR AÑO
========================================================*/
ALTER DATABASE CovidHistorico2 ADD FILEGROUP FG_ANTES_2020;
ALTER DATABASE CovidHistorico2 ADD FILEGROUP FG_2020;
ALTER DATABASE CovidHistorico2 ADD FILEGROUP FG_2021;
ALTER DATABASE CovidHistorico2 ADD FILEGROUP FG_2022_MAS;
GO

/*========================================================
3) CREAR ARCHIVOS FÍSICOS (.ndf) PARA CADA FILEGROUP
========================================================*/
ALTER DATABASE CovidHistorico2 
ADD FILE (NAME='FG_ANTES_2020_dat', 
FILENAME='C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\FG_ANTES_2020.ndf') 
TO FILEGROUP FG_ANTES_2020;
GO

ALTER DATABASE CovidHistorico2 
ADD FILE (NAME='FG_2020_dat', 
FILENAME='C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\FG_2020.ndf') 
TO FILEGROUP FG_2020;
GO

ALTER DATABASE CovidHistorico2 
ADD FILE (NAME='FG_2021_dat', 
FILENAME='C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\FG_2021.ndf') 
TO FILEGROUP FG_2021;
GO

ALTER DATABASE CovidHistorico2 
ADD FILE (NAME='FG_2022_dat', 
FILENAME='C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\FG_2022.ndf') 
TO FILEGROUP FG_2022_MAS;
GO

/*========================================================
4) CREAR FUNCIÓN DE PARTICIÓN POR RANGO DE FECHAS
   Particiones:
   P1 < 2020
   P2 = 2020
   P3 = 2021
   P4 >= 2022
========================================================*/
CREATE PARTITION FUNCTION pf_anio (DATE)
AS RANGE RIGHT FOR VALUES 
('2020-01-01','2021-01-01','2022-01-01');
GO

/*========================================================
5) CREAR ESQUEMA DE PARTICIÓN ASOCIADO A FILEGROUPS
========================================================*/
CREATE PARTITION SCHEME ps_anio
AS PARTITION pf_anio
TO (
    FG_ANTES_2020,
    FG_2020,
    FG_2021,
    FG_2022_MAS
);
GO

/*========================================================
6) CREAR TABLA PARTICIONADA
   La PK incluye la columna de partición (FECHA_INGRESO)
========================================================*/
CREATE TABLE covid_particionado (
    Id INT IDENTITY(1,1),
    FECHA_INGRESO DATE NOT NULL,
    ENTIDAD_RES VARCHAR(50),
    EDAD INT,
    CONSTRAINT PK_covid_particionado
        PRIMARY KEY CLUSTERED (FECHA_INGRESO, Id)
)
ON ps_anio(FECHA_INGRESO);
GO

/*========================================================
7) INSERTAR MUESTRAS DE DATOS POR AÑO
   (TOP 200000 registros por cada rango)
========================================================*/
-- Antes de 2020
INSERT INTO covid_particionado (FECHA_INGRESO, ENTIDAD_RES, EDAD)
SELECT TOP (200000)
    TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO,'"','')),
    REPLACE(ENTIDAD_RES,'"',''),
    TRY_CONVERT(INT, REPLACE(EDAD,'"',''))
FROM datoscovid
WHERE TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO,'"','')) < '2020-01-01';

-- Año 2020
INSERT INTO covid_particionado (FECHA_INGRESO, ENTIDAD_RES, EDAD)
SELECT TOP (200000) ...
WHERE TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO,'"','')) 
BETWEEN '2020-01-01' AND '2020-12-31';

-- Año 2021
INSERT INTO covid_particionado (FECHA_INGRESO, ENTIDAD_RES, EDAD)
SELECT TOP (200000) ...
WHERE TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO,'"','')) 
BETWEEN '2021-01-01' AND '2021-12-31';

-- Año 2022 en adelante
INSERT INTO covid_particionado (FECHA_INGRESO, ENTIDAD_RES, EDAD)
SELECT TOP (200000) ...
WHERE TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO,'"','')) >= '2022-01-01';
GO

/*========================================================
PRUEBAS Y VALIDACIONES
========================================================*/

/*========================================================
PRUEBA 1 – Ver número de filas por partición
Ambas consultas muestran filas por partición, 
pero la segunda es más exacta porque se limita al índice clustered. 
La primera es útil para ver todo el panorama, 
mientras que la segunda es la validación oficial de que los datos 
están distribuidos en las particiones correctas.
========================================================*/
SELECT p.partition_number AS Particion, p.rows AS Filas
FROM sys.partitions p
JOIN sys.tables t ON p.object_id = t.object_id
WHERE t.name = 'covid_particionado';
GO

/*========================================================
PRUEBA 2 – Validar filas por partición (índices clustered y heap)
Ambas consulta	s muestran filas por partición, 
pero la segunda es más exacta porque se limita al índice clustered. 
La primera es útil para ver todo el panorama, 
mientras que la segunda es la validación oficial de que los datos 
están distribuidos en las particiones correctas.
========================================================*/
SELECT p.partition_number, p.rows
FROM sys.partitions p
WHERE p.object_id = OBJECT_ID('covid_particionado')
AND p.index_id IN (0,1);
GO


-- PRUEBA 3: Ver en qué FILEGROUP está cada partición
SELECT p.partition_number AS Particion, fg.name AS Filegroup
FROM sys.destination_data_spaces dds
JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
JOIN sys.partition_schemes ps ON dds.partition_scheme_id = ps.data_space_id
JOIN sys.partitions p ON p.partition_number = dds.destination_id
WHERE ps.name = 'ps_anio';
GO

-- PRUEBA 4: Consulta filtrada solo por 2020
SET STATISTICS IO ON;
SELECT *
FROM covid_particionado
WHERE FECHA_INGRESO BETWEEN '2020-01-01' AND '2020-12-31';
GO

-- PRUEBA 5: Consulta filtrada solo por 2021
SELECT *
FROM covid_particionado
WHERE FECHA_INGRESO BETWEEN '2021-01-01' AND '2021-12-31';
GO
 