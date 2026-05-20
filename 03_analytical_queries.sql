-- ============================================================
-- PHARMACOVIGILANCE SYSTEM — ANALYTICAL SQL QUERIES
-- For Power BI Data Sources & Business Analysis
-- ============================================================
USE pharmacovigilance_db;

-- ============================================================
-- QUERY 1: Drug-wise Adverse Event Count & Severity Breakdown
-- Power BI Visual: Stacked Bar Chart
-- ============================================================
SELECT
    d.drug_name,
    d.drug_class,
    d.manufacturer,
    COUNT(ae.ae_id)                                             AS total_ae_reports,
    SUM(CASE WHEN ae.severity = 'Fatal'    THEN 1 ELSE 0 END)  AS fatal_count,
    SUM(CASE WHEN ae.severity = 'Severe'   THEN 1 ELSE 0 END)  AS severe_count,
    SUM(CASE WHEN ae.severity = 'Moderate' THEN 1 ELSE 0 END)  AS moderate_count,
    SUM(CASE WHEN ae.severity = 'Mild'     THEN 1 ELSE 0 END)  AS mild_count,
    ROUND(SUM(CASE WHEN ae.severity IN ('Severe','Fatal') THEN 1 ELSE 0 END)*100.0 / COUNT(*), 2)
                                                                AS serious_ae_pct
FROM drugs d
LEFT JOIN adverse_events ae ON d.drug_id = ae.drug_id
GROUP BY d.drug_id, d.drug_name, d.drug_class, d.manufacturer
ORDER BY total_ae_reports DESC;


-- ============================================================
-- QUERY 2: Monthly Adverse Event Trend (2019-2024)
-- Power BI Visual: Line Chart
-- ============================================================
SELECT
    DATE_FORMAT(ae.report_date, '%Y-%m')    AS report_month,
    YEAR(ae.report_date)                    AS report_year,
    MONTH(ae.report_date)                   AS month_num,
    COUNT(ae.ae_id)                         AS total_reports,
    SUM(CASE WHEN ae.seriousness = 'Serious' THEN 1 ELSE 0 END) AS serious_reports,
    SUM(CASE WHEN ae.hospitalization = 1     THEN 1 ELSE 0 END) AS hospitalizations
FROM adverse_events ae
GROUP BY DATE_FORMAT(ae.report_date, '%Y-%m'), YEAR(ae.report_date), MONTH(ae.report_date)
ORDER BY report_year, month_num;


-- ============================================================
-- QUERY 3: High-Risk Drug Signal Detection
-- Power BI Visual: KPI Cards + Heat Map
-- ============================================================
SELECT
    d.drug_name,
    d.drug_class,
    sd.ae_category,
    sd.ror_score,
    sd.prr_score,
    sd.total_reports,
    sd.signal_status,
    sd.priority,
    sd.detected_date,
    sd.action_taken,
    CASE
        WHEN sd.ror_score >= 7  THEN 'HIGH RISK'
        WHEN sd.ror_score >= 4  THEN 'MEDIUM RISK'
        ELSE                         'LOW RISK'
    END AS risk_classification
FROM signal_detection sd
JOIN drugs d ON sd.drug_id = d.drug_id
ORDER BY sd.ror_score DESC;


-- ============================================================
-- QUERY 4: Adverse Events by Patient Demographics
-- Power BI Visual: Donut Chart / Matrix
-- ============================================================
SELECT
    CASE
        WHEN p.age BETWEEN 18 AND 30 THEN '18-30'
        WHEN p.age BETWEEN 31 AND 45 THEN '31-45'
        WHEN p.age BETWEEN 46 AND 60 THEN '46-60'
        WHEN p.age BETWEEN 61 AND 75 THEN '61-75'
        ELSE '75+'
    END                            AS age_group,
    p.gender,
    ae.severity,
    COUNT(ae.ae_id)                AS ae_count,
    AVG(ae.onset_days)             AS avg_onset_days
FROM adverse_events ae
JOIN patients p ON ae.patient_id = p.patient_id
GROUP BY age_group, p.gender, ae.severity
ORDER BY age_group, p.gender;


-- ============================================================
-- QUERY 5: Country-wise Adverse Event Distribution
-- Power BI Visual: Filled Map
-- ============================================================
SELECT
    ae.source_country,
    p.region,
    COUNT(ae.ae_id)                                            AS total_reports,
    SUM(CASE WHEN ae.severity = 'Fatal'  THEN 1 ELSE 0 END)   AS fatal_reports,
    SUM(CASE WHEN ae.hospitalization = 1 THEN 1 ELSE 0 END)   AS hospitalizations,
    ROUND(AVG(ae.onset_days), 1)                              AS avg_onset_days
FROM adverse_events ae
JOIN patients p ON ae.patient_id = p.patient_id
GROUP BY ae.source_country, p.region
ORDER BY total_reports DESC;


-- ============================================================
-- QUERY 6: Causality Assessment Summary
-- Power BI Visual: Treemap
-- ============================================================
SELECT
    d.drug_name,
    ae.causality,
    ae.ae_category,
    COUNT(ae.ae_id)   AS report_count,
    ROUND(COUNT(ae.ae_id)*100.0 /
        SUM(COUNT(ae.ae_id)) OVER (PARTITION BY d.drug_name), 2) AS pct_of_drug_reports
FROM adverse_events ae
JOIN drugs d ON ae.drug_id = d.drug_id
WHERE ae.causality IN ('Certain','Probable')
GROUP BY d.drug_name, ae.causality, ae.ae_category
ORDER BY d.drug_name, report_count DESC;


-- ============================================================
-- QUERY 7: Reporter Type Analysis
-- Power BI Visual: Clustered Column Chart
-- ============================================================
SELECT
    ae.reporter_type,
    ae.severity,
    COUNT(ae.ae_id)  AS reports,
    ROUND(AVG(ae.onset_days), 1) AS avg_onset_days
FROM adverse_events ae
GROUP BY ae.reporter_type, ae.severity
ORDER BY ae.reporter_type, reports DESC;


-- ============================================================
-- QUERY 8: Outcome Tracking Dashboard
-- Power BI Visual: Funnel Chart
-- ============================================================
SELECT
    d.drug_name,
    ae.outcome,
    COUNT(ae.ae_id)   AS count,
    ROUND(COUNT(ae.ae_id)*100.0 /
        SUM(COUNT(ae.ae_id)) OVER (PARTITION BY d.drug_name), 2) AS outcome_pct
FROM adverse_events ae
JOIN drugs d ON ae.drug_id = d.drug_id
GROUP BY d.drug_name, ae.outcome
ORDER BY d.drug_name, count DESC;


-- ============================================================
-- QUERY 9: Prescription-to-AE Conversion Rate (Risk Index)
-- Power BI Visual: Scatter Plot
-- ============================================================
SELECT
    d.drug_name,
    d.drug_class,
    COUNT(DISTINCT pr.prescription_id)  AS total_prescriptions,
    COUNT(DISTINCT ae.ae_id)            AS total_ae_reports,
    ROUND(COUNT(DISTINCT ae.ae_id)*100.0 / NULLIF(COUNT(DISTINCT pr.prescription_id),0), 2)
                                         AS ae_rate_pct,
    ROUND(AVG(ae.onset_days), 1)        AS avg_onset_days
FROM drugs d
LEFT JOIN prescriptions pr ON d.drug_id = pr.drug_id
LEFT JOIN adverse_events ae ON d.drug_id = ae.drug_id
GROUP BY d.drug_id, d.drug_name, d.drug_class
ORDER BY ae_rate_pct DESC;


-- ============================================================
-- QUERY 10: Executive Summary KPI Query
-- Power BI Visual: Card Visuals / KPI Tiles
-- ============================================================
SELECT
    COUNT(DISTINCT ae.ae_id)                                                AS total_ae_reports,
    COUNT(DISTINCT ae.ae_id) FILTER (WHERE ae.severity = 'Fatal')          AS total_fatalities,
    COUNT(DISTINCT ae.ae_id) FILTER (WHERE ae.seriousness = 'Serious')     AS serious_aes,
    COUNT(DISTINCT ae.ae_id) FILTER (WHERE ae.hospitalization = 1)         AS hospitalizations,
    COUNT(DISTINCT sd.signal_id)                                            AS active_signals,
    COUNT(DISTINCT sd.signal_id) FILTER (WHERE sd.priority = 'High')       AS high_priority_signals,
    COUNT(DISTINCT d.drug_id)                                               AS drugs_monitored,
    ROUND(COUNT(DISTINCT ae.ae_id)*100.0/COUNT(DISTINCT pr.prescription_id), 2)
                                                                            AS overall_ae_rate_pct
FROM adverse_events ae
CROSS JOIN (SELECT COUNT(*) AS total FROM prescriptions) pr_total
LEFT JOIN signal_detection sd ON ae.drug_id = sd.drug_id
LEFT JOIN drugs d ON ae.drug_id = d.drug_id
LEFT JOIN prescriptions pr ON ae.drug_id = pr.drug_id;

