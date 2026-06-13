# UAE E-Commerce Fraud Signal Analysis
## Phase 1: SQL — Database Design and Fraud Signal Analysis

This repository covers the first phase of a three-part fraud analytics project 
analyzing 100,000 synthetic UAE e-commerce transactions.

The analysis is written from the perspective of a fraud analytics analyst 
at a payments company, with findings translated into actionable recommendations 
for a risk team.

---

## Dataset
- **Source:** Kaggle — UAE E-Commerce Fraud Detection dataset
- **Note:** This is a synthetic dataset generated to simulate real-world 
  e-commerce fraud patterns. Some signals that would typically appear in 
  real transaction data — such as transaction velocity — show no variation 
  in this dataset, which is noted and documented in the analysis.
- 100,000 transactions | 28,937 unique users
- Fraud rate: 8.21% (8,211 fraudulent transactions)
- Features: transaction details, user profile, device and network signals, 
  geographic data, and pre-computed fraud flags

---

## Database Structure
Three normalized tables designed from scratch:

- **Users** — user profile and risk attributes (28,937 records)
- **Transactions** — full transaction details including card, device, 
  and geographic data (100,000 records)
- **Fraud_Flags** — six specific fraud trigger flags per transaction 
  (100,000 records)

See `erdplus-Credit_card.png` for the full ERD.

---

## SQL Analysis Structure
Eight sections testing eleven signals, moving from weak categorical 
variables to stronger behavioral and user profile signals:

- **Section A** — Categorical variables: merchant category, device type, payment method
- **Section B** — Behavioral and network signals: IP risk score, transaction velocity
- **Section C** — Geographic mismatch signals
- **Section D** — User profile signals: high risk flag, previous chargebacks
- **Section E** — Transaction amount analysis
- **Section F** — Time-based fraud analysis
- **Section G** — Fraud flag analysis: frequency, reliability, combinations
- **Section H** — Signal ranking summary and risk team recommendations

---

## Key Findings
Three signals stand out as strong fraud predictors:
- **prev_cb_flag** — 27.24% fraud rate when fired, highest precision signal
- **user_is_high_risk** — 22.07% fraud rate, but covers only 13% of actual fraud
- **ip_flag** — 16.05% fraud rate, most balanced signal available in real time

Two signals show moderate predictive value:
- **new_account_flag** — 12.69% fraud rate, high frequency moderate precision
- **geographic_mismatch** — 11.96% fraud rate when both mismatches present

Five signals are weak standalone predictors and should not trigger 
fraud rules independently: odd hour, merchant category, payment method, 
device type, and transaction amount.

Most importantly, 39.65% of fraud occurs in transactions with zero flags 
fired — confirming that rule-based systems alone cannot close the detection 
gap and justifying the need for a machine learning model in Phase 3.

---

## Status
- [x] Database design and ERD
- [x] Data loading and validation
- [x] SQL fraud analysis

---

## Tools
PostgreSQL · pgAdmin

---

## Project Phases
- **Phase 1: SQL** — Database design and fraud signal analysis *(this repo)*
- **Phase 2: Python EDA** — Visualizations and pattern validation *(coming)*
- **Phase 3: ML** — Fraud classification model *(coming)*

---

## Part of a Broader Portfolio
This project is part of a multi-tool analytics portfolio demonstrating 
that analytical skills transfer across domains — from retail sales 
diagnostics to fraud pattern analysis.
