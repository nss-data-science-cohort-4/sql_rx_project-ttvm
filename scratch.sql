SELECT
	fc.county
	, fc.state
	, COUNT(DISTINCT(zf.zip)) AS num_fips
	
FROM zip_fips AS zf

JOIN fips_county AS fc
	ON zf.fipscounty = fc.fipscounty
	
WHERE fc.state = 'TN'

GROUP BY 1,2
;

-- 2017 overdose deaths per county
SELECT
	fc.county
	, fc.state
	, od.year
	, p3.population
	, od.overdose_deaths AS num_ods
	, ROUND((od.overdose_deaths / p3.population * 100), 4) AS ods_per_cap_2017

FROM overdose_deaths AS od

JOIN fips_county AS fc
	ON fc.fipscounty = od.fipscounty

JOIN population AS p3
	ON p3.fipscounty = od.fipscounty

WHERE od.year = 2017
;
-- opioid prescriptions per capita per zip
SELECT COUNT(DISTINCT(fipscounty)) FROM (
SELECT
	zf.zip
	, zf.tot_ratio
	, zf.fipscounty
	, fc.county
	, fc.state
	, d.generic_name
	, d.long_acting_opioid_drug_flag
	, SUM(p2.total_claim_count) AS tot_scripts
--	, ROUND((SUM(p2.total_claim_count) / p3.population * 100), 4) AS scripts_per_capita

FROM prescription AS p2

JOIN drug AS d
	ON d.drug_name = p2.drug_name

JOIN prescriber AS p1
	ON p1.npi = p2.npi

JOIN zip_fips AS zf
	ON zf.zip = p1.nppes_provider_zip5

JOIN fips_county AS fc
	ON fc.fipscounty = zf.fipscounty

JOIN population AS p3
	ON p3.fipscounty = fc.fipscounty

WHERE d.opioid_drug_flag = 'Y'

GROUP BY 1,2,3,4,5,6,7
) as f

;
WITH zip_to_county AS (
	SELECT
		zf.fipscounty
		, zip
		, tot_ratio
		, RANK() OVER(PARTITION BY zip ORDER BY tot_ratio DESC) AS rnk
	FROM zip_fips AS zf
	JOIN fips_county AS fc
		ON fc.fipscounty = zf.fipscounty
	WHERE fc.state = 'TN'
)

SELECT zc.fipscounty
	, zc.zip
	, d.generic_name
	, d.long_acting_opioid_drug_flag
	, SUM(p2.total_claim_count) AS tot_scripts
	
FROM zip_to_county AS zc

JOIN prescriber AS p1
	ON p1.nppes_provider_zip5 = zc.zip

JOIN prescription AS p2
	ON p2.npi = p1.npi

JOIN drug AS d
	ON d.drug_name = p2.drug_name

WHERE
	zc.rnk = 1
	AND d.opioid_drug_flag = 'Y'

GROUP BY 1,2,3,4
ORDER BY 2 DESC
;
-- why are there 96 counties in TN...?
SELECT DISTINCT county
FROM fips_county
WHERE state = 'TN'
ORDER BY 1
;
SELECT DISTINCT fipscounty
FROM overdose_deaths