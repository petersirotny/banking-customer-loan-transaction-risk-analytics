-- ======================================================
-- 06 TRANSACTION FRAUD VIEWS
-- ======================================================

-- 1. MONTHLY TRANSACTION SUMMARY
-- Grain: 1 row = 1 transaction_month

create or replace view monthly_transaction_summary as
with monthly_base as (
select
		date_trunc('month', transaction_date)::date as transaction_month,
		count(*) as transaction_count,
		sum(case when direction = 'Credit' then 1 else 0 end) as credit_transaction_count,
		sum(case when direction = 'Debit' then 1 else 0 end) as debit_transaction_count,
		sum(case when direction = 'Credit' then amount else 0 end) as total_credit_amount,
		sum(case when direction = 'Debit' then amount else 0 end) as total_debit_amount,
		sum(case when direction = 'Credit' then amount else 0 end) -
		sum(case when direction = 'Debit' then amount else 0 end) as net_cash_flow
from
	valid_transactions
group by
	date_trunc('month', transaction_date)::date),
with_previous as (
select
		*,
		lag(net_cash_flow) over (
	order by transaction_month) as previous_month_net_cash_flow
from
	monthly_base)
select
	*,
	net_cash_flow - previous_month_net_cash_flow as mom_net_cash_flow_change,
	round(((net_cash_flow - previous_month_net_cash_flow) * 100.0 / nullif(previous_month_net_cash_flow, 0))::numeric, 2) as mom_net_cash_flow_change_rate,
	sum(total_credit_amount) over (
	order by transaction_month rows between 2 preceding and current row) as rolling_3m_credit_amount,
	sum(total_debit_amount) over (
	order by transaction_month rows between 2 preceding and current row) as rolling_3m_debit_amount,
	sum(net_cash_flow) over (
	order by transaction_month rows between 2 preceding and current row) as rolling_3m_net_cash_flow
from
	with_previous;

-- 2. FRAUD MONITORING SUMMARY
-- Grain: 1 row = 1 alert_month

drop view if exists fraud_monitoring_summary;

create or replace view fraud_monitoring_summary as
with monthly_base as (
select
    date_trunc('month', a.alert_date)::date as alert_month,
    count(*) as alert_count,
    sum(case when a.alert_status = 'Closed' then 1 else 0 end) as closed_alert_count,
    sum(case when a.alert_status = 'Open' then 1 else 0 end) as open_alert_count,
    sum(case when a.alert_status = 'Under Review' then 1 else 0 end) as under_review_alert_count,
    sum(case when a.investigation_outcome = 'Confirmed Fraud' then 1 else 0 end) as confirmed_fraud_count,
    sum(case when a.investigation_outcome = 'Customer Confirmed' then 1 else 0 end) as customer_confirmed_count,
    sum(case when a.investigation_outcome = 'False Positive' then 1 else 0 end) as false_positive_count,
    sum(case when a.investigation_outcome = 'Inconclusive' then 1 else 0 end) as inconclusive_count,
    sum(case when a.investigation_outcome is null or trim(a.investigation_outcome) = '' then 1 else 0 end) as missing_outcome_count,
    round(sum(t.amount)::numeric, 2) as total_alerted_transaction_amount,
    round(avg(a.risk_score)::numeric, 2) as average_risk_score,
    round((sum(case when a.investigation_outcome = 'Confirmed Fraud' then 1 else 0 end) * 100.0 / nullif(count(*), 0))::numeric, 2) as confirmed_fraud_rate_pct,
    round((sum(case when a.investigation_outcome = 'False Positive' then 1 else 0 end) * 100.0 / nullif(count(*), 0))::numeric, 2) as false_positive_rate_pct
from
    valid_fraud_alerts a
join valid_transactions t on
    t.transaction_id = a.transaction_id
group by
    date_trunc('month', a.alert_date)::date
),
previous as (
select
    *,
    lag(alert_count) over (order by alert_month) as previous_month_alert_count
from monthly_base
)
select
    *,
    alert_count - previous_month_alert_count as mom_alert_count_change
from previous;