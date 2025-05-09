
SELECT customerID, gender, tenure, MonthlyCharges, Churn
FROM `trusty-pipe-459303-i3.customer_churn_data.telco_churn`
LIMIT 10;

SELECT 
  COUNTIF(TRIM(TotalCharges) = '') AS total_missing_totalcharges,
  COUNTIF(TotalCharges IS NULL) AS total_null_totalcharges
FROM `trusty-pipe-459303-i3.customer_churn_data.telco_churn`;

SELECT 
  customerID,
  SAFE_CAST(NULLIF(TRIM(TotalCharges), '') AS FLOAT64) AS total_charges_fixed
FROM `trusty-pipe-459303-i3.customer_churn_data.telco_churn`
WHERE SAFE_CAST(NULLIF(TRIM(TotalCharges), '') AS FLOAT64) IS NULL;

CREATE OR REPLACE VIEW `trusty-pipe-459303-i3.customer_churn_data.churn_features` AS
SELECT
  customerID,
  gender,
  SeniorCitizen,
  Partner,
  tenure,
  Contract,
  MonthlyCharges,
  
  -- Clean TotalCharges (cast to float)
  SAFE_CAST(NULLIF(TRIM(TotalCharges), '') AS FLOAT64) AS TotalCharges,
  
  -- Average monthly spend (avoid divide-by-zero)
  ROUND(
    SAFE_CAST(NULLIF(TRIM(TotalCharges), '') AS FLOAT64) / NULLIF(tenure, 0), 
    2
  ) AS avg_monthly_spend,
  
  -- Tenure buckets (with correct hyphen)
  CASE 
    WHEN tenure <= 12 THEN '0-1 year'
    WHEN tenure <= 24 THEN '1-2 years'
    WHEN tenure <= 48 THEN '2-4 years'
    WHEN tenure <= 60 THEN '4-5 years'
    ELSE '5+ years'
  END AS tenure_group,

  -- Flag for long-term contracts
  CASE 
    WHEN Contract IN ('One year', 'Two year') THEN 1
    ELSE 0
  END AS is_long_term_contract,

  -- Target variable
  Churn

FROM `trusty-pipe-459303-i3.customer_churn_data.telco_churn`

-- Exclude rows with non-numeric TotalCharges
WHERE SAFE_CAST(NULLIF(TRIM(TotalCharges), '') AS FLOAT64) IS NOT NULL;

SELECT * FROM `trusty-pipe-459303-i3.customer_churn_data.churn_features`;
