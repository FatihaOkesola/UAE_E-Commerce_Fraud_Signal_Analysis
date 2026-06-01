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
