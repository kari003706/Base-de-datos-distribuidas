/********************************************************************
           PROBLEMA 1 - DIRTY READ / LECTURA SUCIA
                         CONEXION A
********************************************************************/

USE AdventureWorks2019;
GO


/********************************************************************
 PASO 1 - PREPARACION

 Creamos una tabla de prueba usando un producto real.
 Así no modificamos directamente Production.Product.
********************************************************************/

IF @@TRANCOUNT > 0
    ROLLBACK;
GO

DROP TABLE IF EXISTS dbo.Demo_DirtyRead;
GO

SELECT TOP 1
    ProductID,
    Name,
    ListPrice
INTO dbo.Demo_DirtyRead
FROM Production.Product
WHERE ListPrice > 0
ORDER BY ProductID;
GO


/* Ver precio original */

SELECT
    ProductID,
    Name,
    ListPrice AS PrecioOriginal
FROM dbo.Demo_DirtyRead;
GO



/********************************************************************
 PASO 2 - PROVOCAR EL DIRTY READ

 A inicia una transaccion y modifica el precio.

 IMPORTANTE:
 No hacemos COMMIT porque queremos dejar
 el cambio temporal.
********************************************************************/

BEGIN TRANSACTION;


/* Precio antes del cambio */

SELECT
    ProductID,
    Name,
    ListPrice AS PrecioAntes
FROM dbo.Demo_DirtyRead;


/* Aumentamos el precio 20% */

UPDATE dbo.Demo_DirtyRead
SET ListPrice = ListPrice * 1.20;


/* Precio temporal */

SELECT
    ProductID,
    Name,
    ListPrice AS PrecioTemporal
FROM dbo.Demo_DirtyRead;


/********************************************************************
 DETENERSE AQUI.

 NO ejecutar todavía el ROLLBACK.

 AHORA IR A CONEXION B
 y ejecutar la primera parte.
*********************************************************************/



/********************************************************************
 PASO 4 - REGRESAR A CONEXION A

 Ejecutar esto DESPUES de que B haya leído
 el precio temporal.
********************************************************************/

ROLLBACK TRANSACTION;
GO


/* El precio vuelve a ser el original */

SELECT
    ProductID,
    Name,
    ListPrice AS PrecioDespuesRollback
FROM dbo.Demo_DirtyRead;
GO



/********************************************************************
 RESULTADO:

 B leyó un precio que A todavía no había confirmado.

 Después A hizo ROLLBACK.

 Por lo tanto B leyó un dato que realmente
 nunca quedó guardado.

 ESO ES UN DIRTY READ.
*********************************************************************/



/********************************************************************
 SOLUCION DEL DIRTY READ

 Ahora volvemos a hacer el cambio,
 pero B utilizará READ COMMITTED.
********************************************************************/

BEGIN TRANSACTION;


UPDATE dbo.Demo_DirtyRead
SET ListPrice = ListPrice * 1.20;


/* Precio temporal */

SELECT
    ProductID,
    Name,
    ListPrice AS PrecioTemporal
FROM dbo.Demo_DirtyRead;


/********************************************************************
 DETENERSE AQUI.

 DEJAR LA TRANSACCION ABIERTA.

 IR A CONEXION B
 y ejecutar la parte de READ COMMITTED.

 B se debe quedar esperando.
*********************************************************************/



/********************************************************************
 REGRESAR A A MIENTRAS B ESTA ESPERANDO
********************************************************************/

ROLLBACK TRANSACTION;
GO


SELECT
    ProductID,
    Name,
    ListPrice AS PrecioFinal
FROM dbo.Demo_DirtyRead;
GO


/********************************************************************
 Con READ COMMITTED, B no pudo leer el dato sin confirmar.

 Cuando A hizo ROLLBACK, B pudo continuar.
********************************************************************/