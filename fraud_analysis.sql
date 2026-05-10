-- =============================================
-- CREDIT CARD FRAUD DETECTION
-- SQL Fraud Analysis
-- =============================================

-- =============================================
-- SECTION A: CATEGORICAL FRAUD ANALYSIS
-- Testing whether fraud is concentrated in 
-- specific categories, devices, or payment methods
-- =============================================

-- Which merchant category has the highest fraud rate?
SELECT t.merchant_category, 
    ROUND(SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS merchant_fraud_pct
FROM transactions AS t
GROUP BY t.merchant_category
ORDER BY merchant_fraud_pct DESC;

-- Which device type has the highest fraud rate?
SELECT t.device_type,
    ROUND(SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS device_fraud_pct
FROM transactions AS t
GROUP BY t.device_type
ORDER BY device_fraud_pct DESC;

-- Which payment method has the highest fraud rate?
SELECT t.payment_method,
    ROUND(SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS payment_fraud_pct
FROM transactions AS t
GROUP BY t.payment_method
ORDER BY payment_fraud_pct DESC;

-- INSIGHT:
-- Fraud rate was tested across three categorical variables:
-- merchant category (7.70% - 8.73%), device type (7.88% - 8.24%),
-- and payment method (8.03% - 8.69%).
-- In all three cases the spread is less than 1%, indicating that
-- categorical variables alone are not strong fraud discriminators.
-- Fraud appears evenly distributed across categories, devices, and
-- payment methods, suggesting that behavioral and network signals
-- may be stronger predictors.

-- =============================================
-- SECTION B: BEHAVIORAL AND NETWORK SIGNALS
-- Testing continuous and boolean variables as
-- fraud indicators
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
-- Yes, fraudulent transactions have a higher average IP risk score (46.25)
-- compared to legitimate ones (39.24), a difference of 7 points.
-- This suggests IP risk score is a meaningful fraud signal, unlike the
-- categorical variables tested earlier which showed less than 1% spread.

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
-- Transaction velocity is not a meaningful fraud signal in this dataset.
-- Both fraudulent and legitimate transactions show near-zero average
-- velocity in the hour and 24 hours before the transaction.
-- Fraudsters in this dataset do not appear to make rapid repeated
-- transactions before committing fraud.

-- =============================================
-- SECTION C: GEOGRAPHIC MISMATCH SIGNALS
-- Testing whether address and card country
-- mismatches are associated with higher fraud rates
-- =============================================

-- Do transactions with card country and shipping/billing mismatches have higher fraud rates?
SELECT 
    t.card_country_match, 
    t.shipping_billing_match,
    COUNT(*) AS total_transactions,
    ROUND(SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_pct
FROM transactions AS t
GROUP BY t.card_country_match, t.shipping_billing_match
ORDER BY fraud_pct DESC;

-- INSIGHT:
-- Transactions where both card country and shipping/billing address don't match
-- have the highest fraud rate (11.96%), almost 5% higher than transactions
-- where both match (7.21%).
-- Transactions with even one mismatch show elevated fraud rates, and the
-- effect compounds when both mismatches are present.
-- Geographic mismatch is the strongest categorical fraud signal found so far.

-- =============================================
-- SECTION D: USER PROFILE SIGNALS
-- Testing whether user-level risk attributes
-- predict fraudulent transactions
-- =============================================
--Do high-risk users have higher fraud rates?
SELECT 
    u.user_is_high_risk, 
    COUNT(*) AS total_high_risk,
    ROUND(SUM(CASE WHEN is_fraud = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS risk_pct
FROM transactions AS t
JOIN users u ON u.user_id = t.user_id
GROUP BY u.user_is_high_risk
ORDER BY risk_pct DESC;

-- INSIGHT:
-- High-risk users have a significantly higher fraud rate (22.07%) compared
-- to non-high-risk users (7.50%), a gap of nearly 15 percentage points.
-- This is the strongest single fraud signal identified in this analysis,
-- suggesting that the user_is_high_risk flag is a reliable fraud predictor.
-- However, it is worth noting that high-risk users account for only 4,871
-- transactions out of 100,000 -- meaning most fraud still comes from users
-- not flagged as high risk. Relying solely on this flag would miss the
-- the majority of fraudulent transactions.

-- Do fraudulent transactions come from users with more previous chargebacks?
SELECT 
    t.is_fraud,
    COUNT(*) AS total_chargebacks,
    ROUND(AVG(u.user_prev_chargebacks), 2) AS avg_user_chargebacks
FROM transactions AS t
JOIN users u ON u.user_id = t.user_id
GROUP BY t.is_fraud
ORDER BY avg_user_chargebacks;

-- INSIGHT:
-- Fraudulent transactions come from users with a higher average chargeback
-- history (0.10) compared to legitimate ones (0.02).
-- While the relative difference is significant (5x), the absolute values
-- are too small to make this a reliable standalone predictor.
-- Most fraudulent users have zero previous chargebacks, meaning this signal
-- is most useful in combination with other variables rather than on its own.
