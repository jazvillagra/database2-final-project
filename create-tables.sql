
CREATE TABLE sol_eventos
(
	cod_evento number(2) not null,
	nombre_evento varchar2(40) not null,
	monto_cobertura number(10) not null,
	cant_max_dias number(4) not null,
	CONSTRAINT pk_id_evento PRIMARY KEY (cod_evento)
);
CREATE TABLE sol_solicitud_premios
(
	id number(10) not null,
	fecha_presentacion date not null,
	fecha_desde date not null,
	fecha_hasta date not null,
	concedido varchar2(1) not null,
	cod_evento number not null,
	id_socio number not null,
	CONSTRAINT pk_id_sol_prem PRIMARY KEY (id),
	CONSTRAINT eventos_solicitud_premios_fk FOREIGN KEY (cod_evento) REFERENCES sol_eventos (cod_evento),
	CONSTRAINT socio_solicitud_premios_fk FOREIGN KEY (id_socio) REFERENCES soc_socio (id_socio)
);

CREATE TABLE soc_motivos
(
	id_motivo number(5) not null,
	descripcion varchar2(30) not null,
	CONSTRAINT pk_id_motivo PRIMARY KEY (id_motivo)
);

CREATE TABLE soc_solicitud_renuncia
(
	id_sol_ren number(10) not null,
	fecha_presentacion date not null,
	aprobada varchar2(1) not null,
	observaciones varchar2(300),
	id_motivo number(5) not null,
	id_socio number not null,
	CONSTRAINT pk_id_sol_ren PRIMARY KEY (id_sol_ren),
	CONSTRAINT motivos_solicitud_renuncia_fk FOREIGN KEY (id_motivo) REFERENCES soc_motivos (id_motivo),
	CONSTRAINT socio_solicitud_renuncia_fk FOREIGN KEY (id_socio) REFERENCES soc_socio (id_socio)
);

CREATE TABLE soc_liquidacion_renuncia
(
	id_liquidacion number(10) not null,
	monto_debitos number(15) not null,
	monto_creditos number(15) not null,
	saldo_a_favor number(15) not null,
	nro_pagare number(8) not null,
	id_sol_ren number(10) not null,
	CONSTRAINT pk_id_liquid PRIMARY KEY (id_liquidacion),
	CONSTRAINT solicitud_renuncia_liquidac FOREIGN KEY (id_sol_ren) REFERENCES soc_solicitud_renuncia (id_sol_ren)
);

CREATE TABLE cre_pagos
(
	id_pago number(12) not null,
	fecha_pago date not null,
	capital_pagado number(12) not null,
	int_pagado number(12) not null,
	int_mora_pagado number(10) not null,
	seg_vida_pagado number(8) not null,
	total_pagado number(16) not null,
	nro_prestamo number not null,
	nro_cuota number(3) not null,
	CONSTRAINT pk_id_pago PRIMARY KEY (id_pago),
	CONSTRAINT cre_cuotas_cre_pagos_fk FOREIGN KEY (nro_prestamo, nro_cuota) REFERENCES cre_cuotas(nro_prestamo, nro_cuota)
);

CREATE TABLE gen_parametros
(
	aporte_mensual number(8) not null,
	solidaridad_mensual number(8) not null,
	antiguedad_minima number(2),
	ruc_cooperativa varchar2(15) not null,
	interes_moratorio_bcp number(3,1) not null,
	porc_seg_vida number(3,2) not null,
	dias_gracia number(2) not null,
	dias_exon_int number(2) not null
);