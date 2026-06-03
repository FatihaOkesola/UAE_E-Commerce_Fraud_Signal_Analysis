-- =============================================
-- CREDIT CARD FRAUD DETECTION
-- SQL Fraud Analysis
-- =============================================
-- CONTEXT:
-- This analysis is written from the perspective of a fraud analytics 
-- analyst at a UAE e-commerce payments company.
-- The goal is to identify which transaction signals best predict fraud
-- so the risk team can build smarter detection rules, request additional
-- authentication where necessary, and reduce fraud losses without 
-- blocking legitimate customers.
--
-- Dataset: 100,000 UAE e-commerce transactions
-- Fraud rate: 8.21% (8,211 fraudulent transactions)
-- Tables: Users, Transactions, Fraud_Flags
-- =============================================


-- =============================================
-- SECTION A: CATEGORICAL FRAUD ANALYSIS
-- Testing whether fraud is concentrated in
-- specific categories, devices, or payment methods.
-- If fraud clusters in specific categories, the risk team
-- can apply stricter rules to those segments.
-- =============================================

-- Which merchant category has the highest fraud rate?
SELECT t.merchant_category, 
    COUNT(*) AS total_transactions,
    ROUND(SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_pct
FROM transactions AS t
GROUP BY t.merchant_category
ORDER BY fraud_pct DESC;

-- Which device type has the highest fraud rate?
SELECT t.device_type,
    COUNT(*) AS total_transactions,
    ROUND(SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_pct
FROM transactions AS t
GROUP BY t.device_type
ORDER BY fraud_pct DESC;

-- Which payment method has the highest fraud rate?
SELECT t.payment_method,
    COUNT(*) AS total_transactions,
    ROUND(SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_pct
FROM transactions AS t
GROUP BY t.payment_method
ORDER BY fraud_pct DESC;

-- INSIGHT:
-- Fraud rate was tested across three categorical variables:
-- merchant category (7.70% - 8.73%), device type (7.88% - 8.24%),
-- and payment method (8.03% - 8.69%).
-- In all three cases the spread is less than 1%, meaning fraud is
-- distributed almost evenly across all categories, devices, and 
-- payment methods.
-- RECOMMENDATION FOR RISK TEAM:
-- Do not build fraud rules based on merchant category, device type,
-- or payment method alone. Applying stricter rules to Toys or 
-- bank transfers would flag nearly as many legitimate transactions
-- as fraudulent ones, creating unnecessary friction for customers.
-- These variables should only be used in combination with stronger
-- signals identified in later sections.


-- =============================================
-- SECTION B: BEHAVIORAL AND NETWORK SIGNALS
-- Testing whether IP risk score and transaction
-- velocity are meaningful fraud predictors.
-- These signals are available at the point of transaction
-- and can be used for real-time fraud scoring.
-- =============================================

-- Do fraudulent transactions have higher IP risk scores than legitimate ones?
SELECT 
    t.is_fraud,
    COUNT(*) AS total_transactions,
    ROUND(AVG(ip_risk_score), 2) AS avg_ip_risk_score
FROM transactions AS t
GROUP BY t.is_fraud
ORDER BY avg_ip_risk_score;

-- INSIGHT:
-- Fraudulent transactions have a meaningfully higher average IP risk 
-- score (46.25) compared to legitimate ones (39.24), a gap of 7 points.
-- This is the first signal that clearly separates fraud from legitimate
-- transactions, unlike the categorical variables in Section A.
-- RECOMMENDATION FOR RISK TEAM:
-- IP risk score should be incorporated into the fraud scoring model.
-- Transactions above a defined threshold — to be determined during
-- model calibration in the ML phase — should trigger step-up 
-- authentication such as OTP or 3D Secure verification.
-- This signal is available in real time at the point of transaction,
-- making it immediately actionable.

-- Do fraudulent transactions show higher velocity than legitimate ones?
SELECT 
    t.is_fraud,
    COUNT(*) AS total_transactions,
    ROUND(AVG(transactions_last_1h), 2) AS avg_transactions_last_1h,
    ROUND(AVG(transactions_last_24h), 2) AS avg_transactions_last_24h
FROM transactions AS t
GROUP BY t.is_fraud
ORDER BY avg_transactions_last_1h;

-- INSIGHT:
-- Transaction velocity shows no meaningful difference between fraudulent
-- and legitimate transactions. Both groups average near-zero transactions
-- in the hour and 24 hours before a transaction.
-- This contradicts the common assumption that fraudsters make rapid
-- repeated transactions before committing fraud.
-- RECOMMENDATION FOR RISK TEAM:
-- Velocity-based rules alone are not reliable in this dataset.
-- Triggering friction based on transaction frequency would not
-- effectively catch fraud while potentially blocking legitimate
-- high-frequency customers. Velocity should not be a primary
-- detection signal but may add marginal value in combination
-- with stronger signals.


-- =============================================
-- SECTION C: GEOGRAPHIC MISMATCH SIGNALS
-- Testing whether mismatches between card country
-- and shipping or billing address are associated
-- with higher fraud rates.
-- Geographic inconsistency is a classic fraud indicator
-- and a low-cost signal to implement in real time.
-- =============================================

-- Do transactions with card country and shipping/billing mismatches 
-- have higher fraud rates?
SELECT 
    t.card_country_match, 
    t.shipping_billing_match,
    COUNT(*) AS total_transactions,
    ROUND(SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_pct
FROM transactions AS t
GROUP BY t.card_country_match, t.shipping_billing_match
ORDER BY fraud_pct DESC;

-- INSIGHT:
-- Geographic mismatch is the strongest signal found so far among
-- categorical and boolean variables.
-- Transactions where both card country and shipping/billing address
-- do not match have a fraud rate of 11.96% — nearly 5 percentage
-- points higher than transactions where both match (7.21%).
-- The effect compounds: each additional mismatch raises the fraud rate,
-- confirming that geographic inconsistency is a genuine fraud signal
-- rather than noise.
-- RECOMMENDATION FOR RISK TEAM:
-- Implement geographic mismatch checks as a real-time fraud rule.
-- Transactions with both mismatches present (card_country_match = FALSE
-- and shipping_billing_match = FALSE) should be automatically flagged
-- for review or step-up authentication. Single mismatches warrant
-- a moderate risk score increase rather than outright blocking,
-- to avoid excessive friction on legitimate cross-border purchases.


-- =============================================
-- SECTION D: USER PROFILE SIGNALS
-- Testing whether user-level risk attributes
-- predict fraudulent transactions.
-- User profile signals are known before a transaction
-- is made and can be used to pre-score risk at login
-- or account creation.
-- =============================================
-- Do high risk users have higher fraud rates?
SELECT 
    u.user_is_high_risk,
    COUNT(*) AS total_transactions,
    ROUND(SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_pct
FROM transactions AS t
JOIN users u ON u.user_id = t.user_id
GROUP BY u.user_is_high_risk
ORDER BY fraud_pct DESC;

-- INSIGHT:
-- The user_is_high_risk flag is the single strongest fraud signal
-- identified in this analysis. High risk users have a fraud rate of
-- 22.07% compared to 7.50% for non-high-risk users — a gap of nearly
-- 15 percentage points.
-- However, high risk users account for only 4,871 of 100,000 transactions.
-- This means the majority of fraud — approximately 7,135 transactions —
-- still comes from users not flagged as high risk.
-- RECOMMENDATION FOR RISK TEAM:
-- The high risk flag should trigger immediate step-up authentication
-- or manual review for all transactions from flagged users.
-- However, relying solely on this flag would miss over 85% of fraudulent
-- transactions. It must be combined with transaction-level signals
-- such as IP risk score and geographic mismatch to build a detection
-- system that catches fraud across the full user base.

-- Of all fraudulent transactions, what percentage came from
-- high risk users vs normal users?
SELECT u.user_is_high_risk,
    COUNT(*) AS total_fraud_transactions, 
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM transactions WHERE is_fraud = TRUE), 2) AS fraud_share_pct
FROM transactions t
JOIN users u ON u.user_id = t.user_id
WHERE t.is_fraud = TRUE
GROUP BY u.user_is_high_risk;

-- INSIGHT:
-- Although high risk users have a significantly higher fraud rate (22.07%),
-- they account for only 13.09% of all fraudulent transactions.
-- The remaining 86.91% of fraud comes from users not flagged as high risk.
-- This means relying on the high risk flag alone would miss almost 87% of
-- fraudulent transactions -- a critical gap for any fraud detection system.
-- RECOMMENDATION FOR RISK TEAM:
-- The high risk flag is a strong signal where present but cannot be the
-- foundation of the detection system. It must be combined with
-- transaction-level signals such as IP risk score and geographic mismatch
-- to build coverage across the full user base, not just the pre-flagged
-- high risk segment.

-- Do fraudulent transactions come from users with more previous 
-- chargebacks?
SELECT 
    t.is_fraud,
    COUNT(*) AS total_transactions,
    ROUND(AVG(u.user_prev_chargebacks), 2) AS avg_prev_chargebacks
FROM transactions AS t
JOIN users u ON u.user_id = t.user_id
GROUP BY t.is_fraud
ORDER BY avg_prev_chargebacks;

-- INSIGHT:
-- Fraudulent transactions come from users with a higher average
-- chargeback history (0.10) compared to legitimate ones (0.02).
-- While the relative difference is 5x, the absolute values are
-- too small for this to be a reliable standalone signal —
-- most fraudulent users have zero previous chargebacks.
-- RECOMMENDATION FOR RISK TEAM:
-- Previous chargebacks should not trigger fraud rules independently.
-- However, when a user has both a non-zero chargeback history and
-- other active signals such as high IP risk score or geographic
-- mismatch, the chargeback history should increase the overall
-- risk score. It is most useful as a tiebreaker in borderline cases
-- rather than a primary detection rule.

-- =============================================
-- SECTION E: TRANSACTION AMOUNT ANALYSIS
-- Testing whether transaction value differs between
-- fraudulent and legitimate transactions.
-- Amount is available in real time at the point of
-- transaction and could be used as a scoring input
-- if a meaningful pattern exists.
-- =============================================

-- Does transaction amount differ between fraudulent and legitimate transactions?
-- Hypothesis: Fraudulent transactions may skew toward higher values as fraudsters
-- attempt to maximise return, but may also mirror legitimate spending patterns
-- to avoid detection. The data will determine which pattern holds.

SELECT is_fraud,
    ROUND(AVG(amount_aed)::NUMERIC, 2) AS average_amount, 
    ROUND(MIN(amount_aed)::NUMERIC, 2) AS min_amount, 
    ROUND(MAX(amount_aed)::NUMERIC, 2) AS max_amount
FROM transactions t
GROUP BY is_fraud;

-- INSIGHT:
-- Fraudulent transactions have a higher average amount (198.31 AED) compared
-- to legitimate ones (159.69 AED) -- a difference of approximately 25%.
-- The minimum transaction amount is also higher for fraud (3.13 AED vs 1.26 AED),
-- suggesting fraudsters rarely make very small test transactions in this dataset.
-- The maximum amount is lower for fraud (20,929.35 AED vs 28,785.92 AED),
-- which may indicate fraudsters avoid extremely large transactions that are
-- more likely to trigger automatic blocks or manual review.
-- RECOMMENDATION FOR RISK TEAM:
-- Transaction amount alone is not a reliable fraud trigger -- flagging all
-- high-value transactions would generate excessive false positives and create
-- unnecessary friction for legitimate high-spending customers.
-- However, amount should be used as a contextual signal. When a transaction
-- amount is significantly above a user's historical average and other signals
-- such as IP risk score or geographic mismatch are also elevated, the
-- combination warrants step-up authentication rather than blocking outright.
-- Amount is a behavioral signal, not a threshold rule.

-- =============================================
-- SECTION F: TIME-BASED FRAUD ANALYSIS
-- Testing whether transactions made at odd hours
-- or specific times of day are more likely to be fraud.
-- Time is available in real time and is a zero-cost
-- signal to implement in a fraud detection rule.
-- =============================================

-- Do transactions made at odd hours have higher fraud rates?
-- Hypothesis: Transactions made during late night or early morning hours
-- are more likely to be fraudulent, as legitimate customers are less
-- likely to be shopping at unusual hours while fraudsters may operate
-- across time zones or deliberately target low-monitoring periods.

-- Is the fraud rate higher for odd hour transactions?
SELECT 
    t.odd_hour,
    COUNT(*) AS total_transactions,
    ROUND(SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_pct
FROM transactions t
GROUP BY t.odd_hour
ORDER BY fraud_pct DESC;

-- Which specific hours have the highest fraud concentration?
SELECT 
    t.local_hour,
    COUNT(*) AS total_transactions,
    ROUND(SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_pct
FROM transactions t
GROUP BY t.local_hour
ORDER BY fraud_pct DESC;

-- INSIGHT:
-- Odd hour transactions have a slightly higher fraud rate (9.65%) compared
-- to normal hour transactions (7.73%), a difference of less than 2%.
-- The hourly breakdown reveals a clearer pattern -- hours 0 through 5
-- (midnight to 5am UAE time) consistently show fraud rates above 9%,
-- peaking at 10.24% at 2am. Afternoon hours (13:00 to 20:00) show the
-- lowest fraud rates, clustering around 7%.
-- While the overall spread across all 24 hours is less than 4 percentage
-- points, the concentration of elevated fraud in early morning hours is
-- consistent and directionally meaningful.
-- RECOMMENDATION FOR RISK TEAM:
-- Time of day alone is too weak to trigger fraud rules independently.
-- However, transactions made between midnight and 5am should receive
-- a modest risk score increase when combined with other active signals
-- such as geographic mismatch or elevated IP risk score.
-- The odd_hour boolean flag captures this window reasonably well and
-- is the simpler variable to implement in a real-time scoring system.

-- =============================================
-- SECTION G: FRAUD FLAG ANALYSIS
-- Querying the Fraud_Flags table to identify which
-- fraud trigger types fire most frequently and which
-- combinations are most associated with confirmed fraud.
-- These flags are pre-computed risk signals designed
-- specifically for fraud detection and represent the
-- most direct indicators available in this dataset.
-- =============================================

-- How often does each flag fire across all transactions? 
SELECT 
    SUM(CASE WHEN fraud_flag_ip = TRUE THEN 1 ELSE 0 END) AS ip_flag_count,
    ROUND(SUM(CASE WHEN fraud_flag_ip = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ip_flag_pct,
    SUM(CASE WHEN fraud_flag_mismatch = TRUE THEN 1 ELSE 0 END) AS mismatch_flag_count,
    ROUND(SUM(CASE WHEN fraud_flag_mismatch = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS mismatch_flag_pct,
    SUM(CASE WHEN fraud_flag_velocity = TRUE THEN 1 ELSE 0 END) AS velocity_flag_count,
    ROUND(SUM(CASE WHEN fraud_flag_velocity = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS velocity_flag_pct,
    SUM(CASE WHEN fraud_flag_new_account = TRUE THEN 1 ELSE 0 END) AS new_account_flag_count,
    ROUND(SUM(CASE WHEN fraud_flag_new_account = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS new_account_flag_pct,
    SUM(CASE WHEN fraud_flag_prev_cb = TRUE THEN 1 ELSE 0 END) AS prev_cb_flag_count,
    ROUND(SUM(CASE WHEN fraud_flag_prev_cb = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS prev_cb_flag_pct,
    SUM(CASE WHEN fraud_flag_odd_hour = TRUE THEN 1 ELSE 0 END) AS odd_hour_flag_count,
    ROUND(SUM(CASE WHEN fraud_flag_odd_hour = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS odd_hour_flag_pct,
    COUNT(*) AS total_transactions
FROM fraud_flags;

-- INSIGHT:
-- The odd_hour flag fires most frequently (25.04% of transactions),
-- followed by new_account (18.02%). The remaining flags fire rarely --
-- ip_flag (3.55%), mismatch (3.16%), and prev_cb (2.98%).
-- The velocity flag never fires (0.00%), which explains why transaction
-- velocity showed no signal in Section B and raises a data quality concern
-- about whether this flag was correctly computed in the dataset.
-- Importantly, frequency of firing does not indicate reliability as a
-- fraud detector. A flag that fires on 25% of transactions may simply
-- reflect normal platform behavior -- odd hours are expected on an
-- international e-commerce platform serving customers across time zones.
-- Similarly, new account flags firing on 18% of transactions may reflect
-- genuine platform growth rather than fraud patterns.
-- To assess reliability, each flag must be tested against confirmed fraud
-- outcomes, not just firing frequency.
-- This distinction also highlights the natural limit of rule-based SQL
-- analysis -- determining whether a flag is truly anomalous for a specific
-- customer requires comparison to that customer's own history or similar
-- customers' behavior. That contextual comparison is what the ML phase
-- will address using similarity-based models such as KNN.

-- Which flags are most reliable when they fire?
SELECT 
    'ip_flag' AS flag_name,
    COUNT(*) AS times_fired,
    SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) AS confirmed_fraud,
    ROUND(SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM fraud_flags ff
JOIN transactions t ON t.transaction_id = ff.transaction_id
WHERE ff.fraud_flag_ip = TRUE
UNION ALL
SELECT 
    'mismatch_flag' AS flag_name,
    COUNT(*) AS times_fired,
    SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) AS confirmed_fraud,
    ROUND(SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM fraud_flags ff
JOIN transactions t ON t.transaction_id = ff.transaction_id
WHERE ff.fraud_flag_mismatch = TRUE
UNION ALL
SELECT 
    'velocity_flag' AS flag_name,
    COUNT(*) AS times_fired,
    SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) AS confirmed_fraud,
    ROUND(SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM fraud_flags ff
JOIN transactions t ON t.transaction_id = ff.transaction_id
WHERE ff.fraud_flag_velocity = TRUE
UNION ALL
SELECT 
    'new_account_flag' AS flag_name,
    COUNT(*) AS times_fired,
    SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) AS confirmed_fraud,
    ROUND(SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM fraud_flags ff
JOIN transactions t ON t.transaction_id = ff.transaction_id
WHERE ff.fraud_flag_new_account = TRUE
UNION ALL
SELECT 
    'prev_cb_flag' AS flag_name,
    COUNT(*) AS times_fired,
    SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) AS confirmed_fraud,
    ROUND(SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM fraud_flags ff
JOIN transactions t ON t.transaction_id = ff.transaction_id
WHERE ff.fraud_flag_prev_cb = TRUE
UNION ALL
SELECT 
    'odd_hour_flag' AS flag_name,
    COUNT(*) AS times_fired,
    SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) AS confirmed_fraud,
    ROUND(SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM fraud_flags ff
JOIN transactions t ON t.transaction_id = ff.transaction_id
WHERE ff.fraud_flag_odd_hour = TRUE
ORDER BY fraud_rate_pct DESC;

-- INSIGHT:
-- When tested for reliability, the flag ranking changes significantly
-- compared to the frequency ranking in the previous query.
-- prev_cb_flag is the highest precision signal -- when it fires, 27.24%
-- of those transactions are confirmed fraud. However it fires rarely
-- (2,981 times), meaning it catches only a small portion of total fraud.
-- This explains why it appeared weak in Section D where the average
-- chargeback count was near zero -- the signal is strong but narrow.
-- ip_flag (16.05%) and mismatch_flag (11.13%) are consistent with
-- findings in Sections B and C respectively, confirming they are
-- reliable mid-frequency signals worth incorporating into detection rules.
-- new_account_flag fires frequently (18,017 times) but has a moderate
-- fraud rate (12.69%), suggesting many new account flags are legitimate
-- new customers rather than fraudsters.
-- odd_hour_flag has the lowest fraud rate (9.65%) despite firing most
-- frequently (25,041 times), confirming the finding from Section F --
-- odd hours reflect normal international platform behavior rather than
-- fraud patterns.
-- velocity_flag fires zero times, confirming the data quality concern
-- identified in the previous query.
-- RECOMMENDATION FOR RISK TEAM:
-- Prioritise prev_cb_flag for high precision targeted intervention,
-- ip_flag and mismatch_flag for broad reliable detection, and
-- new_account_flag as a moderate signal requiring additional context.
-- odd_hour_flag should be deprioritised as a standalone rule.
-- The distinction between frequency and precision is critical --
-- a flag that fires rarely but reliably is more actionable than one
-- that fires constantly with weak discrimination.

-- Which flag combinations appear most in confirmed fraud?
SELECT 
    (ff.fraud_flag_ip::INT + 
     ff.fraud_flag_mismatch::INT + 
     ff.fraud_flag_velocity::INT + 
     ff.fraud_flag_new_account::INT + 
     ff.fraud_flag_prev_cb::INT + 
     ff.fraud_flag_odd_hour::INT) AS total_flags_fired,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) AS confirmed_fraud,
    ROUND(SUM(CASE WHEN t.is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM fraud_flags ff
JOIN transactions t ON t.transaction_id = ff.transaction_id
GROUP BY total_flags_fired
ORDER BY total_flags_fired DESC;

-- INSIGHT:
-- The relationship between flag count and fraud rate is clear and consistent.
-- As the number of flags fired increases, the fraud rate rises significantly:
-- 0 flags: 5.84% | 1 flag: 9.96% | 2 flags: 16.15% | 
-- 3 flags: 26.15% | 4 flags: 41.67%
-- Each additional flag fired approximately doubles the fraud rate,
-- suggesting that flags compound each other's predictive power rather
-- than overlapping on the same transactions.
-- However, 55,721 transactions have zero flags fired yet still contain
-- 3,256 confirmed fraudulent transactions -- 39.65% of all fraud
-- (3,256 of 8,211 total fraudulent transactions) goes undetected
-- by the existing flag system entirely.
-- This is the most important finding in this section and confirms the
-- central limitation identified throughout this analysis -- the current
-- rule-based flag system has significant coverage gaps that cannot be
-- closed by adding more rules alone.
-- RECOMMENDATION FOR RISK TEAM:
-- Transactions with 3 or more flags fired should be treated as high
-- priority for immediate review or blocking -- a 26-42% fraud rate
-- justifies strong intervention at that threshold.
-- Transactions with 2 flags warrant step-up authentication.
-- Single flag transactions warrant a modest risk score increase only.
-- Most importantly, the 39.65% of fraud occurring in zero-flag
-- transactions cannot be caught by rule-based systems alone.
-- This gap is the primary justification for building a machine learning
-- model in the next phase -- ML can identify subtle patterns across
-- multiple variables simultaneously that no individual flag or rule
-- combination can capture.

-- =============================================
-- SECTION H: SIGNAL RANKING SUMMARY
-- A consolidated ranking of all signals tested
-- throughout this analysis, ordered by predictive
-- strength. This serves as the risk team's priority
-- guide for which signals to act on first and
-- provides the feature selection foundation for
-- the ML phase.
-- =============================================

-- Summary: Which signals should the risk team prioritise
-- and which features should the ML model focus on?
-- This query consolidates all findings into a single
-- ranked reference table.

-- What is the ranked priority of all signals tested?
SELECT 'prev_cb_flag' AS signal, 27.24 AS fraud_rate_pct, 'Strong — high precision, low frequency' AS signal_strength
UNION ALL
SELECT 'user_is_high_risk', 22.07, 'Strong — highest spread, low coverage'
UNION ALL
SELECT 'ip_flag', 16.05, 'Strong — reliable mid-frequency signal'
UNION ALL
SELECT 'new_account_flag', 12.69, 'Moderate — high frequency, moderate precision'
UNION ALL
SELECT 'geographic_mismatch_both', 11.96, 'Moderate — compounds with other signals'
UNION ALL
SELECT 'odd_hour_flag', 9.65, 'Weak — reflects platform behavior not fraud'
UNION ALL
SELECT 'merchant_category', 8.73, 'Weak — less than 1% spread across categories'
UNION ALL
SELECT 'payment_method', 8.69, 'Weak — less than 1% spread across methods'
UNION ALL
SELECT 'device_type', 8.24, 'Weak — less than 1% spread across devices'
UNION ALL
SELECT 'transaction_amount', 8.21, 'Weak standalone — behavioral signal only'
UNION ALL
SELECT 'transaction_velocity', 0.00, 'No signal — flag never fires in this dataset'
ORDER BY fraud_rate_pct DESC;

-- INSIGHT:
-- This ranking consolidates all signals tested across Sections A through G
-- into a single priority guide for the risk team and feature selection
-- reference for the ML phase.
-- Three signals stand out as strong predictors:
-- prev_cb_flag (27.24%) is the highest precision signal but fires rarely,
-- making it a targeted rather than broad detection tool.
-- user_is_high_risk (22.07%) has the largest fraud rate gap but covers
-- only 13.09% of actual fraud, confirming it cannot stand alone.
-- ip_flag (16.05%) is the most balanced signal -- reliable, mid-frequency,
-- and available in real time at the point of transaction.
-- Two signals show moderate predictive value:
-- new_account_flag (12.69%) and geographic_mismatch (11.96%) both add
-- meaningful lift when combined with stronger signals.
-- Five signals are weak standalone predictors:
-- odd_hour, merchant category, payment method, device type, and
-- transaction amount all show less than 2% spread and should not
-- trigger fraud rules independently.
-- transaction_velocity provides no signal in this dataset.
-- RECOMMENDATION FOR RISK TEAM:
-- Prioritise ip_flag, user_is_high_risk, and prev_cb_flag as the
-- foundation of any rule-based detection system.
-- Incorporate new_account_flag and geographic_mismatch as supporting
-- signals that increase risk scores when present alongside stronger signals.
-- The signal ranking also serves as the feature importance guide for
-- the ML phase -- strong signals here are the features most likely
-- to drive model performance in the Python classification model.
-- However, as shown in Section G, 39.65% of fraud occurs in transactions
-- with zero flags fired, confirming that ML is not optional -- it is
-- the only way to close the coverage gap that rule-based systems cannot.
-- =============================================
-- END OF SQL ANALYSIS
-- Next phase: Python EDA and ML Classification
-- =============================================
