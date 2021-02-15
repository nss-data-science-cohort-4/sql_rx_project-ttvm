CREATE TABLE if not exists opioid_scrips (
	id serial primary key,
	generic_name varchar(255),
	opioid varchar(5),
	long_acting varchar(5),
	total_claim_count numeric,
	total_drug_cost numeric,
	npi numeric,
	provider_lname varchar(100),
	provider_fname varchar(100),
	nppes_credentials varchar(20),
	provider_city varchar(50),
	provider_state varchar(4),
	provider_zip5 varchar(10),
	specialty_desc varchar(100),
	provider_county varchar(50),
	county_pop numeric
);
insert into opioid_scrips
(	generic_name,
	opioid,
	long_acting,
	total_claim_count,
	total_drug_cost,
	npi,
	provider_lname,
	provider_fname,
	nppes_credentials,
	provider_city,
	provider_state,
	provider_zip5,
	specialty_desc,
	provider_county,
	county_pop)
with zip_county as (
	select zip, county, population from(	
		select 
			z.zip
			, z.fipscounty
			, z.tot_ratio
			, fc.county
			, p.population
			, rank() over(partition by z.zip order by z.tot_ratio desc)
			from zip_fips z
			join fips_county fc on z.fipscounty = fc.fipscounty
			join population p on z.fipscounty = p.fipscounty
			where z.fipscounty like '47%'
		) as zips
		where rank = 1
	)
select d.generic_name
	, d.opioid_drug_flag
	, d.long_acting_opioid_drug_flag
	, p1.total_claim_count
	, p1.total_drug_cost
	, p2.npi
	, p2.nppes_provider_last_org_name
	, p2.nppes_provider_first_name
	, p2.nppes_credentials
	, p2.nppes_provider_city
	, p2.nppes_provider_state
	, p2.nppes_provider_zip5
	, p2.specialty_description
	, coalesce(zc.county, 'NA') as provider_county
	, coalesce(zc.population,0) as county_pop
	from drug d
	join prescription p1 on d.drug_name = p1.drug_name
	join prescriber p2 on p1.npi = p2.npi
	left join zip_county zc on p2.nppes_provider_zip5 = zc.zip
where opioid_drug_flag = 'Y';
select * from opioid_scrips limit 10;


CREATE TABLE if not exists provider_county (
	id serial primary key,
	npi numeric,
	provider_lname varchar(100),
	provider_fname varchar(100),
	nppes_credentials varchar(20),
	provider_city varchar(50),
	provider_state varchar(4),
	provider_zip5 varchar(10),
	specialty_desc varchar(100),
	provider_county varchar(50),
	county_pop numeric
);
insert into provider_county
(	npi,
	provider_lname,
	provider_fname,
	nppes_credentials,
	provider_city,
	provider_state,
	provider_zip5,
	specialty_desc,
	provider_county,
	county_pop)
with zip_county as (
	select zip, county, population from(	
		select 
			z.zip
			, z.fipscounty
			, z.tot_ratio
			, fc.county
			, p.population
			, rank() over(partition by z.zip order by z.tot_ratio desc)
			from zip_fips z
			join fips_county fc on z.fipscounty = fc.fipscounty
			join population p on z.fipscounty = p.fipscounty
			where z.fipscounty like '47%'
		) as zips
		where rank = 1
	)
select p.npi
	, p.nppes_provider_last_org_name
	, p.nppes_provider_first_name
	, p.nppes_credentials
	, p.nppes_provider_city
	, p.nppes_provider_state
	, p.nppes_provider_zip5
	, p.specialty_description
	, coalesce(zc.county, 'NA') as provider_county
	, coalesce(zc.population,0) as county_pop
	from prescriber p
	left join zip_county zc on p.nppes_provider_zip5 = zc.zip;

select * from provider_county

with spec_totals as (
	select provider_county, specialty_desc, county_pop, count(npi) as count_provider
		from provider_county
		where county_pop>0
		group by provider_county, specialty_desc, county_pop
	)
select provider_county
	, specialty_desc
	, county_pop
	, count_provider
	, round((count_provider * 1.0)/county_pop*10000, 2) as count_per10k
	from spec_totals
	order by provider_county asc, count_provider desc;

with prov_totals as (
	select provider_county, county_pop, count(npi) as count_provider,
		sum(county_pop) over() as state_pop,
		sum(count(npi)) over () as state_count
		from provider_county
		where county_pop>0
		group by provider_county, county_pop
	)
select provider_county
	, county_pop
	, count_provider
	, round((count_provider * 1.0)/county_pop*10000, 2) as count_per10k
	, state_pop
	, state_count
	, round((state_count * 1.0)/state_pop*10000, 2) as state_per10k
	from prov_totals
	order by count_provider desc;
	
with spec_claims as (
	select specialty_description, opioid_drug_flag as opioid_ctgry, sum(total_claim_count) as ttl_claims_spec
		from prescription p1
		join prescriber p2 using(npi)
		join drug d using (drug_name)
		group by specialty_description, opioid_drug_flag
),
spec_claims_ctgry as (
	select specialty_description, opioid_ctgry, ttl_claims_spec,	
		sum(ttl_claims_spec) over(partition by opioid_ctgry) as ttl_claims_ctgry
		from spec_claims
)
select specialty_description, 
	case when opioid_ctgry = 'Y' then 'Opioids' else 'Non-opioids' end as drug_ctgry, ttl_claims_spec, 
	ttl_claims_ctgry, round(ttl_claims_spec * 1.0 / ttl_claims_ctgry * 100, 2) as pct_ctgry
	from spec_claims_ctgry
	order by opioid_ctgry, pct_ctgry desc;
	
select * from opioid_scrips where county_pop = 0;