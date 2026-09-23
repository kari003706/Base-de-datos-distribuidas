USE AdventureWorks2019;
GO

/********************************************************************
   PROBLEMA 1 - OPTIMIZACION DE CONSULTAS
********************************************************************/


/********************************************************************
   1. CREAR COPIA SIN INDICES
********************************************************************/

-- Si ya existe la tabla, la elimina
IF OBJECT_ID('Sales.SalesOrderDetail_NoIndex', 'U') IS NOT NULL
    DROP TABLE Sales.SalesOrderDetail_NoIndex;
GO

-- Crear copia de SalesOrderDetail sin indices
SELECT *
INTO Sales.SalesOrderDetail_NoIndex
FROM Sales.SalesOrderDetail;
GO


/********************************************************************
   2. ACTIVAR ESTADISTICAS
********************************************************************/

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO


/********************************************************************
   3. CONSULTA ANTES DE OPTIMIZAR
********************************************************************/

PRINT '===== ANTES DE OPTIMIZAR =====';

SELECT
    SalesOrderID,
    ProductID,
    LineTotal
FROM Sales.SalesOrderDetail_NoIndex
WHERE ProductID = 776;
GO

/*
   Revisar el plan de ejecucion.

   Como la tabla no tiene indices, se espera:

   TABLE SCAN

   SQL Server tiene que recorrer la tabla para encontrar
   los registros donde ProductID = 776.
*/


/********************************************************************
   4. CREAR INDICE PARA OPTIMIZAR LA CONSULTA
********************************************************************/

CREATE NONCLUSTERED INDEX IX_SalesOrderDetail_NoIndex_ProductID
ON Sales.SalesOrderDetail_NoIndex(ProductID)
INCLUDE (SalesOrderID, LineTotal);
GO


/********************************************************************
   5. CONSULTA DESPUES DE OPTIMIZAR
********************************************************************/

PRINT '===== DESPUES DE OPTIMIZAR =====';

SELECT
    SalesOrderID,
    ProductID,
    LineTotal
FROM Sales.SalesOrderDetail_NoIndex
WHERE ProductID = 776;
GO

/*
   Revisar nuevamente el plan de ejecucion.

   Ahora se espera:

   INDEX SEEK

   El indice permite localizar directamente ProductID = 776
   sin recorrer toda la tabla.
*/


/********************************************************************
   6. DESACTIVAR ESTADISTICAS
********************************************************************/

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


/********************************************************************
   COMPARACION FINAL

   ANTES:
   - Sin indice
   - Table Scan
   - Mas lecturas logicas
   - Mayor costo

   DESPUES:
   - Indice NONCLUSTERED
   - Index Seek
   - Menos lecturas logicas
   - Menor costo

********************************************************************/