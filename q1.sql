WITH zip_county AS (
	SELECT zip, county
	FROM fips_county
	INNER JOIN zip_fips
	USING(fipscounty)
	WHERE state = 'TN'),
opioid_claims_zip AS (
	SELECT drug_name, generic_name, total_claim_count, 
	total_claim_count_ge65, nppes_provider_zip5
	FROM prescription
	LEFT JOIN drug 
	USING (drug_name)
	LEFT JOIN prescriber
	USING (npi)
	WHERE opioid_drug_flag = 'Y'
	OR long_acting_opioid_drug_flag = 'Y'),
county_and_claims AS (	
	SELECT county, SUM(total_claim_count) AS total_opioid_claims, 
		ROUND(SUM(total_claim_count_ge65), 0) AS total_opioid_claims_65_plus
	FROM opioid_claims_zip
	INNER JOIN zip_county
	ON opioid_claims_zip.nppes_provider_zip5 = zip_county.zip
	GROUP BY county),
county_pop AS (
	SELECT county, population
	FROM population
	INNER JOIN fips_county
	USING (fipscounty)
)
SELECT *
FROM county_and_claims
LEFT JOIN county_pop
USING(county)
;


