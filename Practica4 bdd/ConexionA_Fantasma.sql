/********************************************************************
          PROBLEMA 3 - PHANTOM READ / LECTURA FANTASMA
                         CONEXION A
********************************************************************/

USE AdventureWorks2019;
GO


/********************************************************************
 PASO 1 - PREPARACION

 Creamos una tabla de prueba con productos reales.
 La consulta del ejercicio usara el rango de precio 20 a 50.
********************************************************************/

IF @@TRANCOUNT > 0
    ROLLBACK;
GO

DROP TABLE IF EXISTS dbo.Demo_PhantomRead;
GO


SELECT TOP 3
    ProductID,
    Name,
    ListPrice
INTO dbo.Demo_PhantomRead
FROM Production.Product
WHERE ListPrice BETWEEN 20 AND 50
ORDER BY ProductID;
GO


/* Creamos un indice para el rango de precios */

CREATE INDEX IX_Demo_PhantomRead_ListPrice
ON dbo.Demo_PhantomRead(ListPrice);
GO


/* Limpiamos productos de prueba por si repetimos el ejercicio */

DELETE FROM dbo.Demo_PhantomRead
WHERE ProductID IN (99998, 99999);
GO


/* Ver datos iniciales */

SELECT *
FROM dbo.Demo_PhantomRead
ORDER BY ProductID;
GO



/********************************************************************
 PASO 2 - PROVOCAR PHANTOM READ

 REPEATABLE READ protege las filas que A ya leyo,
 pero NO evita que aparezcan nuevas filas que
 cumplan con la condicion.
********************************************************************/

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
GO

BEGIN TRANSACTION;


/* PRIMERA LECTURA */

SELECT
    ProductID,
    Name,
    ListPrice
FROM dbo.Demo_PhantomRead
WHERE ListPrice BETWEEN 20 AND 50
ORDER BY ProductID;


/* Contamos cuantas filas hay */

SELECT COUNT(*) AS PrimeraCantidad
FROM dbo.Demo_PhantomRead
WHERE ListPrice BETWEEN 20 AND 50;


/********************************************************************
                 DETENERSE AQUI

 NO HACER COMMIT.

 IR A CONEXION B
 y ejecutar el PASO 3.

 B insertara un nuevo producto
 dentro del mismo rango de precios.
*********************************************************************/



/********************************************************************
 PASO 4 - REGRESAR A CONEXION A

 Ejecutar DESPUES de que B haya insertado
 el Producto Fantasma.
********************************************************************/


/* SEGUNDA LECTURA */

SELECT
    ProductID,
    Name,
    ListPrice
FROM dbo.Demo_PhantomRead
WHERE ListPrice BETWEEN 20 AND 50
ORDER BY ProductID;


/* Volvemos a contar */

SELECT COUNT(*) AS SegundaCantidad
FROM dbo.Demo_PhantomRead
WHERE ListPrice BETWEEN 20 AND 50;


/* Terminamos la transaccion */

COMMIT TRANSACTION;
GO


/********************************************************************
 RESULTADO:

 La segunda consulta devuelve una fila adicional
 que NO aparecia en la primera lectura.

 Ejemplo:

 PrimeraCantidad = 3
 SegundaCantidad = 4

 La nueva fila es la FILA FANTASMA.
*********************************************************************/



/********************************************************************
 PREPARAR LA SOLUCION

 Quitamos los productos utilizados en la demostracion.
********************************************************************/

DELETE FROM dbo.Demo_PhantomRead
WHERE ProductID IN (99998, 99999);
GO



/********************************************************************
 SOLUCION - SERIALIZABLE

 SERIALIZABLE protege tambien el rango de la consulta.

 Esto significa que otra conexion no podra insertar
 una nueva fila dentro del rango mientras A tenga
 abierta la transaccion.
********************************************************************/

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
GO

BEGIN TRANSACTION;


/* PRIMERA LECTURA */

SELECT
    ProductID,
    Name,
    ListPrice
FROM dbo.Demo_PhantomRead
WHERE ListPrice BETWEEN 20 AND 50
ORDER BY ProductID;


/* Primera cantidad */

SELECT COUNT(*) AS PrimeraCantidad
FROM dbo.Demo_PhantomRead
WHERE ListPrice BETWEEN 20 AND 50;


/********************************************************************
                 DETENERSE AQUI

 DEJAR LA TRANSACCION ABIERTA.

 IR A CONEXION B
 y ejecutar la parte:

 SOLUCION CON SERIALIZABLE

 B intentara insertar otra fila,
 pero debe quedarse esperando.
*********************************************************************/



/********************************************************************
 REGRESAR A A MIENTRAS B ESTA ESPERANDO
********************************************************************/


/* SEGUNDA LECTURA */

SELECT
    ProductID,
    Name,
    ListPrice
FROM dbo.Demo_PhantomRead
WHERE ListPrice BETWEEN 20 AND 50
ORDER BY ProductID;


/* La cantidad debe ser la misma */

SELECT COUNT(*) AS SegundaCantidad
FROM dbo.Demo_PhantomRead
WHERE ListPrice BETWEEN 20 AND 50;


/* Terminamos la transaccion */

COMMIT TRANSACTION;
GO


/********************************************************************
 RESULTADO:

 PrimeraCantidad y SegundaCantidad deben ser iguales.

 Mientras A tenia abierta la transaccion,
 B NO pudo insertar la nueva fila.

 Cuando A hace COMMIT,
 B puede terminar su INSERT.

 SERIALIZABLE evita el PHANTOM READ.
********************************************************************/