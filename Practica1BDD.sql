USE AdventureWorks2022;
GO
--EJEMPLO DEL PROFESOR
select name, cant
from Production.product p
join (select top 10 productid, sum(orderqty) cant
              from sales.SalesOrderDetail sod
			  group by productid
              order by cant desc) as T
on p.ProductID = t.ProductID
 
select soh.SalesOrderID, sod.ProductID, sod.OrderQty, soh.CustomerID
from sales.SalesOrderHeader soh join sales.SalesOrderDetail sod
on soh.SalesOrderID = sod.SalesOrderID
where year(OrderDate) = '2014'

--consulta 1

SELECT TOP (10)
    p.Name AS NombreProducto,
    tp.CantidadTotalVendida,
    COALESCE(st.Name, CONCAT(pp.FirstName, ' ', pp.LastName)) AS NombreCliente,
    tp.AvgUnitPrice,
    p.ListPrice
FROM (
    SELECT
        sod.ProductID,
        SUM(sod.OrderQty) AS CantidadTotalVendida,
        AVG(sod.UnitPrice) AS AvgUnitPrice
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesOrderDetail AS sod
        ON sod.SalesOrderID = soh.SalesOrderID
    WHERE soh.OrderDate >= '20140101'
      AND soh.OrderDate <  '20150101'
    GROUP BY sod.ProductID
) AS tp
INNER JOIN Production.Product AS p
    ON p.ProductID = tp.ProductID
   AND p.ListPrice > 1000
CROSS APPLY (
    SELECT TOP (1)
        soh2.CustomerID
    FROM Sales.SalesOrderHeader AS soh2
    INNER JOIN Sales.SalesOrderDetail AS sod2
        ON sod2.SalesOrderID = soh2.SalesOrderID
    WHERE soh2.OrderDate >= '20140101'
      AND soh2.OrderDate <  '20150101'
      AND sod2.ProductID = tp.ProductID
    GROUP BY soh2.CustomerID
    ORDER BY SUM(sod2.OrderQty) DESC
) AS ctop
INNER JOIN Sales.Customer AS c
    ON c.CustomerID = ctop.CustomerID
LEFT JOIN Sales.Store AS st
    ON st.BusinessEntityID = c.StoreID
LEFT JOIN Person.Person AS pp
    ON pp.BusinessEntityID = c.PersonID
ORDER BY tp.CantidadTotalVendida DESC;



--consulta 2

WITH VentasPorEmpleado AS (
    SELECT
        soh.SalesPersonID,
        SUM(soh.SubTotal) AS TotalVentasTerritorio
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesTerritory AS st
        ON st.TerritoryID = soh.TerritoryID
    WHERE st.Name = 'Northwest'
      AND soh.SalesPersonID IS NOT NULL
    GROUP BY soh.SalesPersonID
),
PromedioTerritorio AS (
    SELECT AVG(TotalVentasTerritorio) AS PromedioVentasTerritorio
    FROM VentasPorEmpleado
)
SELECT
    v.SalesPersonID,
    CONCAT(p.FirstName, ' ', p.LastName) AS NombreEmpleado,
    v.TotalVentasTerritorio,
    pt.PromedioVentasTerritorio
FROM VentasPorEmpleado AS v
CROSS JOIN PromedioTerritorio AS pt
INNER JOIN Sales.SalesPerson AS sp
    ON sp.BusinessEntityID = v.SalesPersonID
INNER JOIN Person.Person AS p
    ON p.BusinessEntityID = sp.BusinessEntityID
WHERE v.TotalVentasTerritorio > pt.PromedioVentasTerritorio
ORDER BY v.TotalVentasTerritorio DESC;



--consulta 3

SELECT
    st.Name AS Territorio,
    YEAR(soh.OrderDate) AS Anio,
    COUNT(DISTINCT soh.SalesOrderID) AS NumOrdenes,
    SUM(soh.SubTotal) AS VentasTotales
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st
    ON st.TerritoryID = soh.TerritoryID
GROUP BY
    st.Name,
    YEAR(soh.OrderDate)
HAVING
    COUNT(DISTINCT soh.SalesOrderID) > 5
    AND SUM(soh.SubTotal) > 1000000
ORDER BY
    VentasTotales DESC;



--consulta 4

WITH ProductosCategoria AS (
    SELECT p.ProductID
    FROM Production.Product p
    INNER JOIN Production.ProductSubcategory ps
        ON ps.ProductSubcategoryID = p.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc
        ON pc.ProductCategoryID = ps.ProductCategoryID
    WHERE pc.Name = 'Bikes'
),
VentasCategoria AS (
    SELECT DISTINCT
        soh.SalesPersonID,
        sod.ProductID
    FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.SalesOrderDetail sod
        ON sod.SalesOrderID = soh.SalesOrderID
    INNER JOIN ProductosCategoria pc
        ON pc.ProductID = sod.ProductID
    WHERE soh.SalesPersonID IS NOT NULL
)
SELECT
    v.SalesPersonID,
    CONCAT(pp.FirstName, ' ', pp.LastName) AS NombreVendedor
FROM VentasCategoria v
INNER JOIN Person.Person pp
    ON pp.BusinessEntityID = v.SalesPersonID
GROUP BY
    v.SalesPersonID,
    pp.FirstName,
    pp.LastName
HAVING COUNT(*) = (SELECT COUNT(*) FROM ProductosCategoria)
ORDER BY NombreVendedor;



--consulta 5

WITH VentasPorProducto AS (
    SELECT 
        pc.Name AS Categoria,
        p.Name AS Producto,
        SUM(sod.OrderQty) AS TotalVendido
    FROM Sales.SalesOrderDetail sod
    INNER JOIN Production.Product p
        ON sod.ProductID = p.ProductID
    INNER JOIN Production.ProductSubcategory ps
        ON ps.ProductSubcategoryID = p.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc
        ON pc.ProductCategoryID = ps.ProductCategoryID
    GROUP BY pc.Name, p.Name
),
RankingCategoria AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY Categoria
               ORDER BY TotalVendido DESC
           ) AS rn
    FROM VentasPorProducto
)
SELECT
    Categoria,
    Producto,
    TotalVendido
FROM RankingCategoria
WHERE rn = 1
ORDER BY Categoria;