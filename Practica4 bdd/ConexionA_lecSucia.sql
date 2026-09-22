USE AdventureWorks2019;
GO

/* =========================================================
   CONEXION A

   Empezamos una transacción.
   Vamos a subir el precio 20%.

   IMPORTANTE:
   Todavía NO hacemos COMMIT.
   ========================================================= */

BEGIN TRANSACTION;


/* Ver precio original */

SELECT
    ProductID,
    Name,
    ListPrice AS PrecioAntes
FROM dbo.Demo_DirtyRead;


/* Aumentar el precio 20% */

UPDATE dbo.Demo_DirtyRead
SET ListPrice = ListPrice * 1.20;


/* Ver el precio modificado */

SELECT
    ProductID,
    Name,
    ListPrice AS PrecioTemporal
FROM dbo.Demo_DirtyRead;


/* =========================================================
   CONEXION A

   Cancelamos todos los cambios de la transaccion.
   ========================================================= */

ROLLBACK TRANSACTION;
GO


/* Revisamos el valor verdadero */

SELECT
    ProductID,
    Name,
    ListPrice AS PrecioDespuesRollback
FROM dbo.Demo_DirtyRead;
GO