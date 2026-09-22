/********************************************************************
     PROBLEMA 2 - NONREPEATABLE READ
              LECTURA NO REPETIBLE

                    CONEXION A
********************************************************************/

USE AdventureWorks2019;
GO


/********************************************************************
 PASO 1 - PREPARACION

 Creamos otra tabla de prueba.
********************************************************************/

IF @@TRANCOUNT > 0
    ROLLBACK;
GO

DROP TABLE IF EXISTS dbo.Demo_NonRepeatableRead;
GO


SELECT TOP 1
    ProductID,
    Name,
    ListPrice,
    ListPrice AS PrecioOriginal
INTO dbo.Demo_NonRepeatableRead
FROM Production.Product
WHERE ListPrice > 0
ORDER BY ProductID;
GO


/* Ver precio inicial */

SELECT *
FROM dbo.Demo_NonRepeatableRead;
GO



/********************************************************************
 PASO 2 - PRIMERA LECTURA

 READ COMMITTED evita Dirty Read,
 pero todavía puede permitir una lectura no repetible.
********************************************************************/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO


BEGIN TRANSACTION;


/* PRIMERA LECTURA */

SELECT
    ProductID,
    Name,
    ListPrice AS PrimeraLectura
FROM dbo.Demo_NonRepeatableRead;


/********************************************************************
 DETENERSE AQUI.

 NO hacer COMMIT.

 IR A CONEXION B
 para que B modifique el precio.
*********************************************************************/



/********************************************************************
 PASO 4 - REGRESAR A CONEXION A

 Ejecutar DESPUES de que B haya cambiado el precio.
********************************************************************/


/* SEGUNDA LECTURA */

SELECT
    ProductID,
    Name,
    ListPrice AS SegundaLectura
FROM dbo.Demo_NonRepeatableRead;
GO


COMMIT TRANSACTION;
GO


/********************************************************************
 RESULTADO:

 A hizo dos consultas dentro de la misma transaccion.

 Primera lectura = precio original
 Segunda lectura = precio cambiado por B

 Por lo tanto las dos lecturas dieron valores diferentes.

 ESO ES UNA LECTURA NO REPETIBLE.
*********************************************************************/



/********************************************************************
 SOLUCION

 Ahora utilizamos REPEATABLE READ.

 Este nivel impide que B modifique el registro
 que A ya leyó hasta que A termine su transaccion.
********************************************************************/

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
GO


BEGIN TRANSACTION;


/* PRIMERA LECTURA */

SELECT
    ProductID,
    Name,
    ListPrice AS PrimeraLectura
FROM dbo.Demo_NonRepeatableRead;


/********************************************************************
 DETENERSE AQUI.

 NO hacer COMMIT.

 IR A CONEXION B.

 B intentará modificar el precio,
 pero se quedará esperando.
*********************************************************************/



/********************************************************************
 REGRESAR A A MIENTRAS B ESTA ESPERANDO
********************************************************************/


/* SEGUNDA LECTURA */

SELECT
    ProductID,
    Name,
    ListPrice AS SegundaLectura
FROM dbo.Demo_NonRepeatableRead;
GO


/*
 Las dos lecturas deben mostrar
 exactamente el mismo precio.
*/


COMMIT TRANSACTION;
GO


/********************************************************************
 Cuando A hace COMMIT,
 B ya puede realizar su UPDATE.

 REPEATABLE READ evitó que el valor cambiara
 entre las dos lecturas.
********************************************************************/