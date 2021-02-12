select * from prescriber limit 20;
select * from prescription limit 20;
select * from drug limit 20;
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
	, p2.nppes_provider_zip4
	, p2.specialty_description
	-- , f.county
	from drug d
	join prescription p1 on d.drug_name = p1.drug_name
	join prescriber p2 on p1.npi = p2.npi
	-- join zip_fips z on p2.nppes_provider_zip5 = z.zip
	-- join fips_county f on f.fipscounty = z.fipscounty
where opioid_drug_flag = 'Y';

select * from zip_fips where zip = '37187'

select * from (
	select zip, fipscounty, tot_ratio, rank() over(partition by zip order by tot_ratio desc) from zip_fips
	where fipscounty like '47%'
) as zips where rank = 1
select zip, count(*) from zip_fips
where fipscounty like '47%'
group by zip
having count(*) > 2

select * from tn_regions