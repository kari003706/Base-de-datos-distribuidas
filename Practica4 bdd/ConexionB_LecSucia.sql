USE AdventureWorks2019;
GO

/* =========================================================
   CONEXION B

   READ UNCOMMITTED permite leer cambios
   que otra transaccion aun NO ha confirmado.

   Aqui provocamos la LECTURA SUCIA.
   ========================================================= */

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO


SELECT
    ProductID,
    Name,
    ListPrice AS PrecioLeidoPorB
FROM dbo.Demo_DirtyRead;
GO