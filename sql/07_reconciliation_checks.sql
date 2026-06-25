-- ======================================================
-- 07 RECONCILIATION CHECKS
-- ======================================================

-- ======================================================
-- Final row count reconciliation
-- ======================================================

select
    'customers -> customer_account_portfolio' as reconciliation_check,
    (select count(*) from clean_customers) as source_count,
    (select count(*) from customer_account_portfolio) as output_count,
    (select count(*) from clean_customers)
      - (select count(*) from customer_account_portfolio) as difference

union all

select
    'branches -> branch_account_portfolio',
    (select count(*) from branches),
    (select count(*) from branch_account_portfolio),
    (select count(*) from branches)
      - (select count(*) from branch_account_portfolio)

union all

select
    'valid_accounts -> account_activity_monitoring',
    (select count(*) from valid_accounts),
    (select count(*) from account_activity_monitoring),
    (select count(*) from valid_accounts)
      - (select count(*) from account_activity_monitoring)

union all

select
    'valid_loans -> loan_payment_summary',
    (select count(*) from valid_loans),
    (select count(*) from loan_payment_summary),
    (select count(*) from valid_loans)
      - (select count(*) from loan_payment_summary)

union all

select
    'valid_loans -> loan_portfolio_base',
    (select count(*) from valid_loans),
    (select count(*) from loan_portfolio_base),
    (select count(*) from valid_loans)
      - (select count(*) from loan_portfolio_base)

union all

select
    'valid_loan_payments -> loan_payment_summary payment rows',
    (select count(*) from valid_loan_payments),
    (select sum(payment_rows_count) from loan_payment_summary),
    (select count(*) from valid_loan_payments)
      - (select sum(payment_rows_count) from loan_payment_summary)

union all

select
    'valid_transactions -> monthly_transaction_summary',
    (select count(*) from valid_transactions),
    (select sum(transaction_count) from monthly_transaction_summary),
    (select count(*) from valid_transactions)
      - (select sum(transaction_count) from monthly_transaction_summary)

union all

select
    'valid_fraud_alerts -> fraud_monitoring_summary',
    (select count(*) from valid_fraud_alerts),
    (select sum(alert_count) from fraud_monitoring_summary),
    (select count(*) from valid_fraud_alerts)
      - (select sum(alert_count) from fraud_monitoring_summary);

-- ======================================================
-- Grain uniqueness checks
-- ======================================================

select
    'customer_account_portfolio' as view_name,
    count(*) as row_count,
    count(distinct customer_id) as distinct_key_count,
    count(*) - count(distinct customer_id) as duplicate_key_count
from customer_account_portfolio

union all

select
    'branch_account_portfolio',
    count(*),
    count(distinct branch_id),
    count(*) - count(distinct branch_id)
from branch_account_portfolio

union all

select
    'account_activity_monitoring',
    count(*),
    count(distinct account_id),
    count(*) - count(distinct account_id)
from account_activity_monitoring

union all

select
    'loan_payment_summary',
    count(*),
    count(distinct loan_id),
    count(*) - count(distinct loan_id)
from loan_payment_summary

union all

select
    'loan_portfolio_base',
    count(*),
    count(distinct loan_id),
    count(*) - count(distinct loan_id)
from loan_portfolio_base

union all

select
    'monthly_transaction_summary',
    count(*),
    count(distinct transaction_month),
    count(*) - count(distinct transaction_month)
from monthly_transaction_summary

union all

select
    'fraud_monitoring_summary',
    count(*),
    count(distinct alert_month),
    count(*) - count(distinct alert_month)
from fraud_monitoring_summary;

-- ======================================================
-- Key null checks
-- ======================================================

select
    'loan_portfolio_base' as view_name,
    sum(case when loan_id is null then 1 else 0 end) as null_loan_id_count,
    sum(case when customer_id is null then 1 else 0 end) as null_customer_id_count,
    sum(case when account_id is null then 1 else 0 end) as null_account_id_count,
    sum(case when branch_id is null then 1 else 0 end) as null_branch_id_count
from loan_portfolio_base;