-- Q4: Is there an association between rates of opioid prescriptions and overdose deaths by county?

-- Get opioid prescriptions per 10k residents per county
-- There are 374 zips accounted for in the query below
-- This is due to the join with provider zip codes
WITH zip_to_county AS (
	SELECT
		zf.fipscounty
		, fc.county
		, fc.state
		, zip
		, tot_ratio
		, RANK() OVER(PARTITION BY zip ORDER BY tot_ratio DESC) AS rnk
	FROM zip_fips AS zf
	JOIN fips_county AS fc
		ON fc.fipscounty = zf.fipscounty
	WHERE fc.state = 'TN'
)

SELECT zc.fipscounty
	, zc.county
	, zc.state
	, p3.population
	--, d.generic_name
	--, d.long_acting_opioid_drug_flag
	--, COUNT(DISTINCT zc.zip) AS num_zips
	, SUM(p2.total_claim_count) AS tot_opioid_scripts
	, ROUND(SUM(p2.total_claim_count) / SUM(p3.population) * 10000, 6) AS scripts_per_10k
	
FROM zip_to_county AS zc

JOIN prescriber AS p1
	ON p1.nppes_provider_zip5 = zc.zip

JOIN prescription AS p2
	ON p2.npi = p1.npi

JOIN drug AS d
	ON d.drug_name = p2.drug_name

JOIN population AS p3
	ON zc.fipscounty = p3.fipscounty

WHERE
	zc.rnk = 1
	AND d.opioid_drug_flag = 'Y'

GROUP BY 1,2,3,4
ORDER BY 4 DESC
;
-- get ODs per 10K
SELECT
	fc.fipscounty
	, CASE WHEN cbsa.fipscounty IS NOT NULL THEN 'urban' ELSE 'rural' END AS county_type
	, od.overdose_deaths AS num_ods_2017
	, ROUND((od.overdose_deaths / p3.population * 10000), 6) AS od_rate_per_10K_2017

FROM overdose_deaths AS od

JOIN fips_county AS fc
	ON fc.fipscounty = od.fipscounty

JOIN population AS p3
	ON p3.fipscounty = od.fipscounty

LEFT JOIN cbsa
	ON cbsa.fipscounty = fc.fipscounty
	
WHERE od.year = 2017
AND fc.state = 'TN'
;
-- Curiosity checks below
-- 760 zip codes in TN
SELECT COUNT(DISTINCT(zip))
FROM zip_fips
JOIN fips_county AS fc
	ON fc.fipscounty = zip_fips.fipscounty
WHERE fc.state = 'TN'
;
-- 2017 overdose deaths per county draft
SELECT
	fc.county
	, fc.state
	, od.overdose_deaths AS num_ods
	, p3.population
	, ROUND((od.overdose_deaths / p3.population * 100), 4) AS od_rate_per_cap_2017

FROM overdose_deaths AS od

JOIN fips_county AS fc
	ON fc.fipscounty = od.fipscounty

JOIN population AS p3
	ON p3.fipscounty = od.fipscounty

WHERE od.year = 2017

ORDER BY 5 DESC
;
-- Why are there 96 counties in TN...?
-- The county of STATEWIDE is included :screaming:
SELECT DISTINCT county
FROM fips_county
WHERE state = 'TN'
ORDER BY 1
;

-- how many zip codes are in TN?
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
-- opioid prescriptions per capita per zip
-- WIP
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