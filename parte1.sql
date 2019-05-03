
CREATE OR REPLACE PACKAGE PCK_PRESTAMO AS
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
    FUNCTION F_PROXIMA_CUOTA(
        nro_prestamo number
    ) RETURN number;
    PROCEDURE P_REGISTRAR_PAGO(
        nro_prestamo number,
        mensaje_out varchar2
    );
END;