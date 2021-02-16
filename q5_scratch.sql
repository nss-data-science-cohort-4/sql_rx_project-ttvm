--* Is there any association between a particular type of opioid and number of overdose deaths?
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
	, d.generic_name
	, d.long_acting_opioid_drug_flag
	, SUM(p2.total_claim_count) AS tot_scripts
	, ROUND(SUM(p2.total_claim_count) / p3.population * 10000, 6) AS scripts_per_10k
	
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

GROUP BY 1,2,3,4,5,6
ORDER BY 4 DESC
;

SELECT
	fc.fipscounty
	, od.overdose_deaths AS num_ods_2017
	, ROUND((od.overdose_deaths / p3.population * 10000), 6) AS od_rate_per_10K_2017

FROM overdose_deaths AS od

JOIN fips_county AS fc
	ON fc.fipscounty = od.fipscounty

JOIN population AS p3
	ON p3.fipscounty = od.fipscounty

WHERE od.year = 2017
AND fc.state = 'TN'