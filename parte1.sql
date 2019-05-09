
CREATE OR REPLACE PACKAGE PCK_PRESTAMO IS
    e_num NUMBER;
    e_msg VARCHAR2;
    TYPE R_CUOTAS IS RECORD(
        saldo_capital number(12),
        amortizacion number(12),
        interes number(12),
        seguro_vida number(8),
        monto_cuota number(15),
        fecha_vencimiento date
    );
    TYPE T_CUOTAS IS TABLE OF R_CUOTAS
        INDEX BY BINARY_INTEGER;
    FUNCTION F_CALCULAR_CUOTAS(
        monto_prestamo number,
        tasa_interes_anual number,
        plazo_prestamo number,
        fecha_desembolso date
    ) RETURN T_CUOTAS;
    PROCEDURE P_GENERAR_PRESTAMO(
        id_solicitud_credito number,
        fecha_desembolso date
    );
    FUNCTION F_CALCULAR_INGRESOS(
        p_id_socio NUMBER;
    ) RETURN NUMBER;
    FUNCTION F_CALCULAR_PATRIMONIOS(
        p_id_socio NUMBER;
    ) RETURN NUMBER;
    FUNCTION F_PROXIMA_CUOTA(
        nro_prestamo number
    ) RETURN number;
    PROCEDURE P_REGISTRAR_PAGO(
        nro_prestamo number,
        mensaje_out varchar2
    );
END;
/
CREATE OR REPLACE PACKAGE BODY PCK_PRESTAMO IS
    FUNCTION F_CALCULAR_CUOTAS(
        p_monto NUMBER,
        p_tasa NUMBER,
		p_plazo NUMBER,
        p_fecha_des DATE) RETURN T_CUOTAS IS
            v_cuotas T_CUOTAS;
            v_amortizacion NUMBER;
            v_intereses NUMBER;
            v_vencimiento DATE;
            v_sub_interes NUMBER;
            v_cuota NUMBER;
            v_aux NUMBER;
            v_scapital NUMBER;
    BEGIN
        --Calculo del interes anual
        v_sub_interes:= (p_tasa/12)/100;
        --Auxiliar para el calculo de una potencia
        v_aux:= POWER(1+v_sub_interes, p_plazo);
        --Calculo de la cuota en base al metodo frances
        v_cuota:= p_capital * ((v_sub_interes*v_aux)/(v_aux-1));
        --Se asigna la fecha del sistema, asumiendo que el credito
        --se otorga en la fecha del calculo de las cuotas
        v_vencimiento:= SYSDATE;
        ==Se asigna el saldo capital inicial
        v_scapital:= p_capital;

        --Ciclo que insertara las cuotas en la tabla de tipo registro R_CUOTAS
        FOR i IN 1..p_plazo loop
            --Se asigna que el vencimiento sea cada un mes
            v_vencimiento:= ADD_MONTHS(v_vencimiento, 1);
            --Interes = saldo capital * i
            v_intereses:= v_scapital *v_sub_interes;
            --Amortizacion de capital = monto cuota - interes
            v_amortizacion:= v_cuota - v_intereses;

            --Se insertan los datos en la tabla indexada de tipo R_CUOTAS
            v_cuotas(i).fecha_vencimiento:= v_vencimiento;
            v_cuotas(i).intereses:= v_intereses;
            v_cuotas(i).amortizacion:= v_amortizacion;

            --Saldo capital inicia con el valor del capital inicial
            -- y luego va en decremento con la amortizacion de cada cuota
            v_scapital;= v_scapital - v_amortizacion;
        end loop
        RETURN v_cuotas;
    EXCEPTION
    WHEN OTHERS THEN
        e_msg:=SQLERRM;
        RAISE_APPLICATION_ERROR(-20010, 'Ha ocurrido un error, verifique el '||
            'mensaje de error: '||e_msg);
    END;

------------------------------------------------------------------------------------
    PROCEDURE P_GENERAR_PRESTAMO(
        p_capital NUMBER,
        p_tipo_prestamo NUMBER,
        p_plazo NUMBER,
        p_id_socio NUMBER
    ) IS
        --Se declaran las variables a utilizar
        v_fecha_baja DATE; --fecha de baja en caso de ser socio inactivo
        v_tasa NUMBER; --Tasa de interes anual
        v_tipo_prestamo NUMBER; --Codigo de tipo de prestamo
        v_nro_prestamo NUMBER; --Nro de prestamo a calcular a partir del ultimo
        v_cuotas T_CUOTAS; --Tabla indexada de tio T_CUOTAS
        v_nro_cuota NUMBER; --Va desde 1 hasta el nro de plazo
        v_amortizacion NUMBER; --Registro R_CUOTAS
        v_intereses NUMBER; --Registro R_CUOTAS
        v_cuota NUMBER; --registro R_CUOTAS
        E_INACTIVO EXCEPTION; --excepcion, se lanza cuando el socio esta inactivo
    BEGIN
        --Busca si el socio existe y si tiene fecha de baja
        SELECT fecha_baja
        INTO v_fecha_baja
        FROM socio
        WHERE id_socio = p_id_socio;
        --Si el socio existe y su fecha de baja es NULL, entonces esta activo
        IF v_fecha_baja IS NULL THEN
            BEGIN
                --una vez cumplidas las condiciones del socio, se busca si el tipo
                --de prestamo existe y cual es su tasa de interes
                SELECT codigo_tipo, tasa_interes_anual
                INTO v_tipo_prestamo, v_tasa
                FROM tipo_prestamo
                WHERE codigo_tipo = p_tipo_prestamo;
            EXCEPTION 
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20003, 'Tipo de prestamo invalido');
                WHEN OTHER THEN
                    e_msg:= SQLERRM;
                    RAISE_APPLICATION_ERROR(-20010, 'Ha ocurrido un error, verifique el '||
                        'mensaje de error: '||e_msg);
            END;

            --Al llegar aqui significa que los datos ingresados son correctos,
            --por lo tanto se busca el ultimo prestamo e incrementa 1 para el nuevo
            SELECT (NVL(MAX(nro_prestamo),0)+1)
            INTO v_nro_prestamo
            FROM prestamos;
            --Se insertan los datos en la tabla PRESTAMO, de acuerdo a las reglas citadas
            INSERT INTO prestamos(nro_prestamo, id_socio, codigo_tipo, fecha_prestamo,
                monto_prestamo, plazo_en_meses)
            VALUES (v_nro_prestamo, p_id_socio, v_tipo_prestamo, TO_DATE(SYSDATE, 'DD/MM/YYYY'),
                p_capital, p_plazo);
            BEGIN
                --Se instancia T_CUOTAS, cargando en ella los datos recogidos por la
                --funcion F_CALCULAR_CUOTAS
                v_cuotas:= F_CALCULAR_CUOTAS(p_capital, v_tasa, p_plazo);
            EXCEPTION 
                WHEN OTHER THEN
                    e_msg:= SQLERRM;
                    RAISE_APPLICATION_ERROR(-20010, 'Ha ocurrido un error, verifique el '||
                        'mensaje de error: '||e_msg);
            END;
            --Insertar las cuotas correspondientes en la tabla CUOTAS
            BEGIN
                v_nro_cuota:= 1;
                --Ciclo que recorre la tabla v_cuotas, el cual contiene los
                --datos a ser ingresados en CUOTAS
                FOR i IN v_cuotas.FIRST..v_cuotas.LAST LOOP
                    --Se asignan los registros a cada variable
                    v_amortizacion:= v_cuotas(i).amortizacion;
                    v_intereses:= v_cuotas(i).intereses;
                    v_cuota:= v_amortizacion + v_intereses;
                    --Se insertan los datos recavados en la tabla CUOTAS
                    --OBS: IVA no se especifica, se asume el valor 10 por defecto
                    INSERT INTO cuotas(nro_prestamo, nro_cuota, amortizacion, interes,
                        iva, monto_cuota, fecha_vencim)
                    VALUES (v_nro_prestamo, v_nro_cuota, v_amortizacion, v_intereses,
                        v_cuota/11, v_cuota, v_cuotas(i).fecha_vencimiento);
                    v_nro_cuota:= v_nro_cuota+1;
                END LOOP;
                --Si hay algun error al insertar las cuotas, el programa se detiene
            EXCEPTION 
                WHEN OTHERS THEN
                    e_msg:= SQLERRM;
                    raise_application_error(-20010, 'Ha ocurrido un error, verifique el '||
                        'mensaje de error: '||e_msg);
            END;
            --Si v_fecha_baja no es NULL, entonces se trata de un socio inactivo,
            --por lo tanto se detiene el programa ya que la condicion es que el socio
            --se encuentre activo para realizar un prestamo
        ELSE
            RAISE E_INACTIVO;
        END IF;
    EXCEPTION 
        --esta excepcion se lanzara en caso de no encontrar datos en el 1er select
        --es decir, si el socio ingresado no existe
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'El id del socio no es valido');
        --Si socio inactivo pretende hacer un prestamo
        WHEN E_INACTIVO THEN
            RAISE_APPLICATION_ERROR(-20003, 'EL socio se encuentra inactivo');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010,  'Ha ocurrido un error,verifique el '||
                'mensaje de error: '||e_msg);
    END;
-----------------------------------------------------------------------------------------------

