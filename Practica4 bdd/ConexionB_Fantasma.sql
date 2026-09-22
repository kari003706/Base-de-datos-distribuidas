/********************************************************************
          PROBLEMA 3 - PHANTOM READ / LECTURA FANTASMA
                         CONEXION B
********************************************************************/

USE AdventureWorks2019;
GO



/********************************************************************
 PASO 3 - INSERTAR LA FILA FANTASMA

 Antes de ejecutar esto:

 CONEXION A debe:

 - usar REPEATABLE READ
 - iniciar la transaccion
 - hacer su primera consulta
 - dejar abierta la transaccion

 Ahora B agrega una fila que cumple con
 la misma condicion que A esta consultando.
********************************************************************/


INSERT INTO dbo.Demo_PhantomRead
(
    ProductID,
    Name,
    ListPrice
)
VALUES
(
    99999,
    'Producto Fantasma',
    35.00
);
GO


/* Ver que la nueva fila ya existe */

SELECT *
FROM dbo.Demo_PhantomRead
WHERE ListPrice BETWEEN 20 AND 50
ORDER BY ProductID;
GO


/********************************************************************
 AHORA REGRESAR A CONEXION A.

 A ejecutara exactamente la misma consulta.

 En la segunda lectura aparecera:

 Producto Fantasma

 Esa nueva fila demuestra el PHANTOM READ.
*********************************************************************/





/********************************************************************
                 SOLUCION CON SERIALIZABLE

 Antes de ejecutar esta parte:

 CONEXION A debe:

 - usar SERIALIZABLE
 - iniciar la transaccion
 - hacer la primera consulta
 - dejar la transaccion abierta
********************************************************************/


INSERT INTO dbo.Demo_PhantomRead
(
    ProductID,
    Name,
    ListPrice
)
VALUES
(
    99998,
    'Producto Bloqueado',
    40.00
);
GO


/********************************************************************
 ESTA CONSULTA DEBE QUEDARSE ESPERANDO.

 NO ESTA MAL.

 SERIALIZABLE esta protegiendo el rango
 de precios que A consulto.

 B quiere agregar un producto que tambien
 estaria entre 20 y 50, pero SQL Server
 no se lo permite mientras A siga
 dentro de su transaccion.

 MIENTRAS B ESTA ESPERANDO:

 REGRESAR A CONEXION A.

 A debe:
 1. hacer su segunda lectura
 2. comprobar que la cantidad no cambio
 3. ejecutar COMMIT

 En cuanto A haga COMMIT,
 este INSERT terminara.
*********************************************************************/



/********************************************************************
 LIMPIEZA FINAL

 Ejecutar esta parte cuando el INSERT anterior
 ya haya terminado.
********************************************************************/

DELETE FROM dbo.Demo_PhantomRead
WHERE ProductID IN (99998, 99999);
GO


/* Ver que quedaron solamente los datos originales */

SELECT *
FROM dbo.Demo_PhantomRead
ORDER BY ProductID;
GO