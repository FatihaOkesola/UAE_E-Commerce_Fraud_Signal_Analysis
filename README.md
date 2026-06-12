# UAE E-Commerce Fraud Signal Analysis

## Overview
This project analyzes 100,000 synthetic UAE e-commerce transactions to identify 
which signals are most predictive of fraudulent activity. The analysis is 
structured as a three-phase project, with each phase building on the previous:

- **Phase 1: SQL** — Database design, schema normalization, and structured 
  fraud signal analysis
- **Phase 2: Python** — Exploratory data analysis and visualization *(in progress)*
- **Phase 3: ML** — Fraud classification model *(coming)*

The analysis is framed from the perspective of a fraud analytics analyst 
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
The SQL phase tests eleven signals across eight sections, moving from 
weak categorical variables to stronger behavioral and user profile signals:

- **Section A** — Categorical variables: merchant category, device type, 
  payment method
- **Section B** — Behavioral and network signals: IP risk score, 
  transaction velocity
- **Section C** — Geographic mismatch signals
- **Section D** — User profile signals: high risk flag, previous chargebacks
- **Section E** — Transaction amount analysis
- **Section F** — Time-based fraud analysis
- **Section G** — Fraud flag analysis: frequency, reliability, combinations
- **Section H** — Signal ranking summary and risk team recommendations

---

## Key SQL Findings
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
gap. This is the primary justification for the ML phase.

---

## Status
- [x] Database design and ERD
- [x] Data loading and validation
- [x] SQL fraud analysis
- [x] Python EDA
- [ ] ML classification model

---

## Tools
PostgreSQL · pgAdmin · Python · pandas · matplotlib · scikit-learn

---

## Part of a Broader Portfolio
This project is part of a multi-tool analytics portfolio demonstrating 
that analytical skills transfer across domains — from retail sales 
diagnostics to fraud pattern analysis.
