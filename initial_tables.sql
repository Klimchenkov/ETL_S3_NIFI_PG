-- Creation of client profile table
CREATE TABLE public.c (
	client_id int4 NOT NULL,
	gender varchar(1) NOT NULL,
	age int2 NOT NULL,
	CONSTRAINT c_pkey PRIMARY KEY (client_id)
);


-- Creation of merchants table
CREATE TABLE public.m (
	merchant_id int4 NOT NULL,
	latitude float4 NOT NULL,
	longitude float4 NOT NULL,
	mcc_id int2 NOT NULL,
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

-- Creation of test table to populate from csv
CREATE TABLE public.test (
	client_id int4 NOT NULL,
	gender varchar(1) NOT NULL,
	age int2 NOT NULL,
	merchant_id int4 NOT NULL,
	latitude float4 NOT NULL,
	longitude float4 NOT NULL,
	mcc_id int2 NOT NULL,
	transaction_dttm timestamp NOT NULL,
	transaction_amt float4 NOT NULL
);

-- Creation of stored procedure to populate tables
create or replace PROCEDURE fill_tables(n_rows integer) AS $$
begin
	insert into public.c select client_id, gender, age from public.test limit n_rows on conflict do nothing;
	insert into public.m select merchant_id, latitude, longitude, mcc_id from public.test limit n_rows on conflict do nothing;
	insert into public.t select merchant_id, client_id, transaction_dttm, transaction_amt from public.test limit n_rows;
	delete from public.test where ctid in (select ctid from public.test limit n_rows);
END;
$$ LANGUAGE plpgsql;

-- Creation of type for aggregation columns
CREATE TYPE public.agg_column AS ENUM (
	'gender',
	'mcc_id',
	'age',
	'month',
	'year',
	'amount');

-- Creation of type for gender 
CREATE TYPE public.gen AS ENUM (
	'f',
	'm',
	'b');

-- Creation of stored procedure to get aggregates
create or replace PROCEDURE get_aggregates(tablename varchar(50) default 'aggregates', agg_column agg_column default 'gender', date_start varchar(20) default '1970-01-01', date_end varchar(20) default '9999-01-01', age_start integer default 1, age_end integer default 200, gender gen default 'b', start_sum integer default 1, end_sum integer default 1000000000, mcc_id integer default 0) AS $$
declare 
	gen_v varchar(20) ='';
	mcc_v varchar(20) ='';
begin	
	if gender <> 'b' then 
		gen_v = format('and gender=''%s''',gender);
	end if;	
	if mcc_id <> 0 then
		mcc_v = format('and mcc_id=''%s''', mcc_id);
	end if;
	if agg_column='gender' or agg_column='mcc_id' then
		execute format('create table %s as select %s, count(*), avg(transaction_amt), min(transaction_amt), max(transaction_amt) from public.t as tr
		join public.m as mer on tr.merchant_id=mer.merchant_id 
		join public.c as cl on tr.client_id =cl.client_id
		where age between %s and %s and transaction_dttm between ''%s'' and ''%s'' and transaction_amt between ''%s'' and ''%s'' %s %s
		group by %s;', tablename, agg_column, age_start, age_end, date_start, date_end, start_sum, end_sum, gen_v, mcc_v, agg_column);
	elseif agg_column='month' or agg_column='year' then
		execute format('create table %s as select date_trunc(''%s'', transaction_dttm) as date_group, count(*), sum(transaction_amt), avg(transaction_amt), min(transaction_amt), max(transaction_amt) from public.t as tr
		join public.m as mer on tr.merchant_id=mer.merchant_id 
		join public.c as cl on tr.client_id =cl.client_id
		where age between %s and %s and transaction_dttm between ''%s'' and ''%s'' and transaction_amt between ''%s'' and ''%s'' %s %s
		group by date_group order by date_group;', tablename, agg_column, age_start, age_end, date_start, date_end, start_sum, end_sum, mcc_v, gen_v);
	elseif agg_column='age' then
		execute format('create table %s as select case when age < 18 then ''Меньше 18''
            when age between 19 and 31 then ''От 19 до 31''
            when age between 31 and 45 then ''От 31 до 45''
            when age between 45 and 60 then ''От 45 до 60''
            else ''Старше 60''
       		end buckets, count(distinct cl.client_id) as num_clients, count(transaction_amt) as num_transactions, sum(transaction_amt) as tr_amount, avg(transaction_amt) as avg_tr_sum, min(transaction_amt) as min_tr_sum, max(transaction_amt) as max_tr_sum from public.t as tr
			join public.m as mer on tr.merchant_id=mer.merchant_id 
			join public.c as cl on tr.client_id =cl.client_id 
			where age between %s and %s and transaction_dttm between ''%s'' and ''%s'' and transaction_amt between ''%s'' and ''%s'' %s %s
			group by buckets;', tablename, age_start, age_end, date_start, date_end, start_sum, end_sum, gen_v, mcc_v);
	elseif agg_column='amount' then
		execute format('create table %s as select case when transaction_amt < 1000 then ''Меньше 1000''
            when transaction_amt between 1000 and 10000 then ''От 1000 до 10000''
            when transaction_amt between 10000 and 100000 then ''От 10000 до 100000''
            when transaction_amt between 100000 and 10000000 then ''От 100000 до 1000000''
            else ''Больше 1000000''
			       end buckets, count(distinct cl.client_id) as num_clients, count(transaction_amt) as num_transactions, sum(transaction_amt) as tr_amount, avg(transaction_amt) as avg_tr_sum, min(transaction_amt) as min_tr_sum, max(transaction_amt) as max_tr_sum from public.t as tr
			join public.m as mer on tr.merchant_id=mer.merchant_id 
			join public.c as cl on tr.client_id =cl.client_id 
			where age between %s and %s and transaction_dttm between ''%s'' and ''%s'' and transaction_amt between ''%s'' and ''%s'' %s %s
			group by buckets;', tablename, age_start, age_end, date_start, date_end, start_sum, end_sum, gen_v, mcc_v);
	
	end if;
END;
$$ LANGUAGE plpgsql;