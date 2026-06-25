-- ======================================================
-- 05 LOAN RISK VIEWS
-- ======================================================

-- 1. LOAN PAYMENT SUMMARY
-- Grain: 1 row = 1 loan_id

create or replace view loan_payment_summary as
select
	l.loan_id,
	count(lp.payment_id) as payment_rows_count,
	count(lp.payment_id) > 0 as has_payment_schedule,
	coalesce(sum(lp.expected_amount), 0) as total_expected_amount,
	coalesce(sum(lp.paid_amount), 0) as total_paid_amount,
	coalesce(sum(lp.expected_amount), 0) - coalesce(sum(lp.paid_amount), 0) as outstanding_scheduled_amount,
	round((sum(lp.paid_amount) * 100.0 / nullif(sum(lp.expected_amount), 0))::numeric, 2) as collection_rate_pct,
	sum(case when lp.payment_status = 'Paid' then 1 else 0 end) as paid_payment_count,
	sum(case when lp.payment_status = 'Late' then 1 else 0 end) as late_payment_count,
	sum(case when lp.payment_status = 'Partially Paid' then 1 else 0 end) as partially_paid_payment_count,
	sum(case when lp.payment_status = 'Missed' then 1 else 0 end) as missed_payment_count,
	sum(case when lp.payment_status = 'Pending' then 1 else 0 end) as pending_payment_count,
	max(case when lp.days_past_due > 0 and lp.has_invalid_dpd = false then lp.days_past_due end) as max_days_past_due,
	round(avg(case when lp.days_past_due > 0 and lp.has_invalid_dpd = false then lp.days_past_due end)::numeric, 2) as average_days_past_due,
	sum(case when lp.has_invalid_dpd = true then 1 else 0 end) as invalid_dpd_count,
	min(lp.due_date) as first_due_date,
	max(lp.due_date) as last_due_date,
	max(lp.payment_date) as last_payment_date
from
	valid_loans l
left join valid_loan_payments lp on
	lp.loan_id = l.loan_id
group by
	l.loan_id;
	

select
    count(*) as row_count,
    count(distinct loan_id) as distinct_loan_count,
    sum(case when has_payment_schedule = false then 1 else 0 end)
        as loans_without_schedule_count,
    sum(payment_rows_count) as total_payment_rows,
    sum(
        case
            when payment_rows_count <>
                 paid_payment_count
               + late_payment_count
               + partially_paid_payment_count
               + missed_payment_count
               + pending_payment_count
            then 1
            else 0
        end
    ) as payment_status_count_mismatch,
    sum(
        case
            when has_payment_schedule = false
             and collection_rate_pct is not null
            then 1
            else 0
        end
    ) as no_schedule_rate_mismatch
from loan_payment_summary;

-- 2. LOAN PORTFOILO BASE
-- Grain: 1 row = 1 loan_id

create or replace view loan_portfolio_base as
select
	l.loan_id,
	c.customer_id,
	c.customer_name,
	c.customer_segment,
	c.risk_rating as customer_risk_rating,
	c.is_pep,
	a.account_id,
	b.branch_id,
	b.branch_name,
	b.region,
	l.loan_type,
	l.application_date,
	l.approval_date,
	l.loan_amount,
	l.interest_rate,
	l.term_months,
	l.monthly_installment,
	l.loan_status,
	l.risk_grade,
	lp.payment_rows_count,
	lp.has_payment_schedule,
	lp.total_expected_amount,
	lp.total_paid_amount,
	lp.outstanding_scheduled_amount,
	lp.collection_rate_pct,
	lp.late_payment_count,
	lp.partially_paid_payment_count,
	lp.missed_payment_count,
	lp.pending_payment_count,
	lp.max_days_past_due,
	lp.average_days_past_due,
	lp.invalid_dpd_count
from valid_loans l
join loan_payment_summary lp on lp.loan_id = l.loan_id
join valid_accounts a on a.account_id = l.account_id
join clean_customers c on c.customer_id = a.customer_id
join branches b on b.branch_id = a.branch_id;