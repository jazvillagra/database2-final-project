--creamos un procedimiento que recibe como parámetro el criterio a ser evaluado
--(ID, CEDULA o APELLIDO); y el valor a ser buscado
CREATE OR REPLACE PROCEDURE P_CONSULTA_SOCIO (P_CRITERIO IN VARCHAR2,P_SOCIO 
IN VARCHAR2)
IS
--creamos un ref cursor
TYPE T_CUR IS REF CURSOR;
--definimos una variable del tipo T_CUR
V_CUR T_CUR;
--creamos un registro con los datos personales del socio
TYPE RESUMEN_SOCIO IS RECORD(
ID_SOCIO SOCIO.ID_SOCIO%TYPE,
CEDULA SOCIO.CEDULA%TYPE,
NOMBRE_APELLIDO VARCHAR2(100));
--definimos una variable del tipo registro RESUMEN_SOCIO
R_SOCIO RESUMEN_SOCIO;

V_SENT_SOCIO VARCHAR2(1000);--sentencia dinámica
V_DEUDA NUMBER;--deuda total del socio
V_SALDO NUMBER;--saldo actual del socio
V_APORTES NUMBER;--aportes totales del socio
V_AUX NUMBER := 0;--auxiliar
E_PARAMETRO EXCEPTION;--parámetro inválido
BEGIN 
--sentencia que se ejecutará en cualquiera de los casos
V_SENT_SOCIO := q'[SELECT ID_SOCIO, CEDULA, NOMBRE||' '||APELLIDO 
NOMBRE_APELLIDO
FROM SOCIO]';
--si el criterio es ID, se busca el socio por id 
IF UPPER(P_CRITERIO) = 'ID' THEN
V_SENT_SOCIO := V_SENT_SOCIO||' WHERE ID_SOCIO = :PSOCIO';
--si el criterio es CEDULA, se busca el socio por cédula
ELSIF UPPER(P_CRITERIO) = 'CEDULA' THEN
V_SENT_SOCIO := V_SENT_SOCIO||' WHERE CEDULA = :PSOCIO';
--si el criterio es APELLIDO, se busca el/los socio/s por apellido 
ELSIF UPPER(P_CRITERIO) = 'APELLIDO' THEN
V_SENT_SOCIO := V_SENT_SOCIO||q'[ WHERE APELLIDO LIKE :PSOCIO]';
--si no es ninguno de los parámetros anteriores, se lanza una excepción
ELSE
RAISE E_PARAMETRO;
END IF;
--se abre el cursor y se busca el socio de acuerdo al parámetro ingresado
OPEN V_CUR FOR V_SENT_SOCIO USING P_SOCIO;
LOOP

FETCH V_CUR INTO R_SOCIO;
EXIT WHEN V_CUR%NOTFOUND;
--sumamos la variable auxiliar para confirma de que se encontró el socio
V_AUX := V_AUX+1;

--calculamos el saldo del socio en cuentas tipo A
SELECT NVL(SUM(CREDITOS),0) - NVL(SUM(DEBITOS),0) INTO V_SALDO
FROM CUENTAS
WHERE ID_SOCIO = R_SOCIO.ID_SOCIO AND TIPO_CUENTA = 'A';
--calculamos si tiene deuda por un préstamo activo
SELECT NVL(SUM(C.MONTO_CUOTA),0) INTO V_DEUDA
FROM PRESTAMOS P
INNER JOIN CUOTAS C
ON C.NRO_PRESTAMO = P.NRO_PRESTAMO
WHERE P.ID_SOCIO = R_SOCIO.ID_SOCIO AND
P.FECHA_CANCEL IS NULL AND
C.FECHA_PAGO IS NULL;
--sumamos el aporte total del socio
SELECT NVL(SUM(MONTO_APORTE),0) INTO V_APORTES
FROM APORTES
WHERE ID_SOCIO = R_SOCIO.ID_SOCIO;
--imprimimos los resultados encontrados 
DBMS_OUTPUT.PUT_LINE('|'||R_SOCIO.ID_SOCIO||'| '||'|'||R_SOCIO.CEDULA||
'| '||'|'||R_SOCIO.NOMBRE_APELLIDO||'| '
||'|'||V_SALDO||'| '
||'|'||V_DEUDA||'| '
||'|'||V_APORTES||'| ');
END LOOP;
--cerramos el cursor
CLOSE V_CUR;
--si la variable auxiliar es 0, entonces no se encontró socio, se lanza
--una excepción
IF V_AUX = 0 THEN
RAISE NO_DATA_FOUND;
END IF;

EXCEPTION
--si el parámetro ingresado no es válido
WHEN E_PARAMETRO THEN
RAISE_APPLICATION_ERROR(-20031,'Parámetro inválido');
--si no se encuentra el socio
WHEN NO_DATA_FOUND THEN
RAISE_APPLICATION_ERROR(-20032,'El socio no existe');
WHEN OTHERS THEN
RAISE_APPLICATION_ERROR(-20010,'Ha ocurrido un error, verifique el'|| 
' mensaje de error: 
'||'Código de error '||SQLERRM);
END;
/