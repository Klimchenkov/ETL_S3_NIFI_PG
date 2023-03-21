-- Creation of client profile table
CREATE TYPE public.gen AS ENUM (
	'f',
	'm');

CREATE TABLE public.c (
	client_id int4 NOT NULL,
	gender public.gen NOT NULL,
	age int2 NOT NULL,
	CONSTRAINT c_pkey PRIMARY KEY (client_id)
);

-- Creation of merchants table
CREATE TABLE public.m (
	merchant_id int4 NOT NULL,
	latitude float4 NOT NULL,
	longtitude float4 NOT NULL,
	mcc_cd int2 NOT NULL,
	CONSTRAINT m_pkey PRIMARY KEY (merchant_id)
);

-- Creation of transactions table
CREATE TABLE public.t (
	merchant_id int4 NOT NULL,
	client_id int4 NOT NULL,
	transaction_dttm timestamp NOT NULL,
	transaction_amt float4 NOT NULL,
	CONSTRAINT t_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.c(client_id),
	CONSTRAINT t_merchant_id_fkey FOREIGN KEY (merchant_id) REFERENCES public.m(merchant_id)
);