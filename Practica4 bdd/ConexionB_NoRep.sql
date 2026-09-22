/********************************************************************
     PROBLEMA 2 - NONREPEATABLE READ
              LECTURA NO REPETIBLE

                    CONEXION B
********************************************************************/

USE AdventureWorks2019;
GO


/********************************************************************
 PASO 3 - MODIFICAR EL DATO

 Antes de ejecutar:

 A debe haber hecho su primera lectura
 y debe mantener abierta su transaccion.
********************************************************************/


UPDATE dbo.Demo_NonRepeatableRead
SET ListPrice = ListPrice + 10;
GO


/* Ver el nuevo precio */

SELECT
    ProductID,
    Name,
    ListPrice AS PrecioModificadoPorB
FROM dbo.Demo_NonRepeatableRead;
GO


/********************************************************************
 Ahora regresar a CONEXION A.

 A hará una segunda lectura y verá
 el nuevo precio.
*********************************************************************/



/********************************************************************
 RESTAURAR EL PRECIO

 Ejecutar después de terminar
 la primera demostracion.
********************************************************************/

UPDATE dbo.Demo_NonRepeatableRead
SET ListPrice = PrecioOriginal;
GO


SELECT
    ProductID,
    Name,
    ListPrice AS PrecioRestaurado
FROM dbo.Demo_NonRepeatableRead;
GO



/********************************************************************
 SOLUCION CON REPEATABLE READ

 Antes de ejecutar esto:

 CONEXION A debe:

 1. Usar REPEATABLE READ
 2. Iniciar una transaccion
 3. Hacer su primera lectura
 4. Dejar abierta la transaccion
********************************************************************/


UPDATE dbo.Demo_NonRepeatableRead
SET ListPrice = ListPrice + 10;
GO


/********************************************************************
 ESTE UPDATE SE DEBE QUEDAR ESPERANDO.

 Eso significa que REPEATABLE READ
 está protegiendo el registro leído por A.

 Mientras B está esperando:

 IR A CONEXION A.

 A hará su segunda lectura y después COMMIT.

 Cuando A haga COMMIT,
 este UPDATE podrá terminar.
*********************************************************************/



/********************************************************************
 LIMPIEZA FINAL

 Ejecutar cuando el UPDATE anterior
 ya haya terminado.
********************************************************************/

UPDATE dbo.Demo_NonRepeatableRead
SET ListPrice = PrecioOriginal;
GO


SELECT
    ProductID,
    Name,
    ListPrice AS PrecioFinal
FROM dbo.Demo_NonRepeatableRead;
GO