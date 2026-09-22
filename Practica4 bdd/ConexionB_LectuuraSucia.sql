/********************************************************************
           PROBLEMA 1 - DIRTY READ / LECTURA SUCIA
                         CONEXION B
********************************************************************/

USE AdventureWorks2019;
GO


/********************************************************************
 PASO 3 - PROVOCAR EL DIRTY READ

 Antes de ejecutar esto:

 CONEXION A debe tener abierta su transaccion
 y ya debe haber cambiado el precio.

 READ UNCOMMITTED permite leer cambios
 que todavía no han sido confirmados.
********************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO


SELECT
    ProductID,
    Name,
    ListPrice AS PrecioLeidoPorB
FROM dbo.Demo_DirtyRead;
GO


/********************************************************************
 RESULTADO:

 B puede ver el precio aumentado por A
 aunque A todavía no hizo COMMIT.

 AHORA REGRESAR A CONEXION A
 y ejecutar ROLLBACK.
*********************************************************************/



/********************************************************************
 SOLUCION DEL DIRTY READ

 Antes de ejecutar esta parte:

 A debe volver a tener una transaccion abierta
 con el precio modificado.
********************************************************************/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO


SELECT
    ProductID,
    Name,
    ListPrice AS PrecioLeidoPorB
FROM dbo.Demo_DirtyRead;
GO


/********************************************************************
 ESTA CONSULTA DEBE QUEDARSE ESPERANDO.

 Esto sucede porque READ COMMITTED no permite
 leer cambios que todavía no han sido confirmados.

 Mientras esta esperando:

 REGRESAR A CONEXION A
 y ejecutar ROLLBACK.

 Después esta consulta podrá continuar.
********************************************************************/