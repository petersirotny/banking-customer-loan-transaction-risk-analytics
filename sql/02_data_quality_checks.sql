-- ======================================================
-- 02 DATA QUALITY CHECKS
-- ======================================================


-- 1. ORPHAN REFERENCE SUMMARY

select
	'accounts -> customers' as relationship_name,
	count(*) as child_row_count,
	sum(case when a.customer_id is not null and not exists (select 1 from customers c where c.customer_id = a.customer_id) then 1 else 0 end) as orphan_count,
	round((sum(case when a.customer_id is not null and not exists (select 1 from customers c where c.customer_id = a.customer_id) then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as orphan_percentage
from
	accounts a
union all
select
	'accounts -> branches' as relationship_name,
	count(*) as child_row_count,
	sum(case when a.branch_id is not null and not exists (select 1 from branches b where b.branch_id = a.branch_id) then 1 else 0 end) as orphan_count,
	round((sum(case when a.branch_id is not null and not exists (select 1 from branches b where b.branch_id = a.branch_id) then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as orphan_percentage
from
	accounts a
union all
select
	'cards -> accounts' as relationship_name,
	count(*) as child_row_count,
	sum(case when c.account_id is not null and not exists (select 1 from accounts a where a.account_id = c.account_id) then 1 else 0 end) as orphan_count,
	round((sum(case when c.account_id is not null and not exists (select 1 from accounts a where a.account_id = c.account_id) then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as orphan_percentage
from
	cards c
union all
select
	'loans -> customers' as relationship_name,
	count(*) as child_row_count,
	sum(case when l.customer_id is not null and not exists (select 1 from customers c where c.customer_id = l.customer_id) then 1 else 0 end) as orphan_count,
	round((sum(case when l.customer_id is not null and not exists (select 1 from customers c where c.customer_id = l.customer_id) then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as orphan_percentage
from
	loans l
union all
select
	'loans -> accounts' as relationship_name,
	count(*) as child_row_count,
	sum(case when l.account_id is not null and not exists (select 1 from accounts a where a.account_id = l.account_id) then 1 else 0 end) as orphan_count,
	round((sum(case when l.account_id is not null and not exists (select 1 from accounts a where a.account_id = l.account_id) then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as orphan_percentage
from
	loans l
union all
select
	'loan_payments -> loans' as relationship_name,
	count(*) as child_row_count,
	sum(case when lp.loan_id is not null and not exists (select 1 from loans l where l.loan_id = lp.loan_id) then 1 else 0 end) as orphan_count,
	round((sum(case when lp.loan_id is not null and not exists (select 1 from loans l where l.loan_id = lp.loan_id) then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as orphan_percentage
from
	loan_payments lp
union all
select
	'transactions -> accounts' as relationship_name,
	count(*) as child_row_count,
	sum(case when t.account_id is not null and not exists (select 1 from accounts a where a.account_id = t.account_id) then 1 else 0 end) as orphan_count,
	round((sum(case when t.account_id is not null and not exists (select 1 from accounts a where a.account_id = t.account_id) then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as orphan_percentage
from
	transactions t
union all
select
	'fraud_alerts -> transactions' as relationship_name,
	count(*) as child_row_count,
	sum(case when f.transaction_id is not null and not exists (select 1 from transactions t where t.transaction_id = f.transaction_id) then 1 else 0 end) as orphan_count,
	round((sum(case when f.transaction_id is not null and not exists (select 1 from transactions t where t.transaction_id = f.transaction_id) then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as orphan_percentage
from
	fraud_alerts f
union all
select
	'fraud_alerts -> customers' as relationship_name,
	count(*) as child_row_count,
	sum(case when f.customer_id is not null and not exists (select 1 from customers c where c.customer_id = f.customer_id) then 1 else 0 end) as orphan_count,
	round((sum(case when f.customer_id is not null and not exists (select 1 from customers c where c.customer_id = f.customer_id) then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as orphan_percentage
from
	fraud_alerts f
union all
select
	'customer_contacts -> customers' as relationship_name,
	count(*) as child_row_count,
	sum(case when cc.customer_id is not null and not exists (select 1 from customers c where c.customer_id = cc.customer_id) then 1 else 0 end) as orphan_count,
	round((sum(case when cc.customer_id is not null and not exists (select 1 from customers c where c.customer_id = cc.customer_id) then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as orphan_percentage
from
	customer_contacts cc
order by orphan_count desc, relationship_name;

-- 2. INVALID NUMERIC VALUES

-- 2.1 Invalid transaction amounts

select
	count(*) as row_count,
	sum(case when amount = 0 then 1 else 0 end) as zero_amount_count,
	sum(case when amount < 0 then 1 else 0 end) as negative_amount_count,
	sum(case when amount <= 0 then 1 else 0 end) as invalid_amount_count,
	round((sum(case when amount <= 0 then 1 else 0 end) * 100.0 / nullif(count(*), 0))::numeric, 2) as invalid_amount_percentage
from
	transactions;

-- 2.2 Invalid loan payment values

select
	count(*) as row_count,
	sum(case when expected_amount <= 0 then 1 else 0 end) as invalid_expected_amount_count,
	sum(case when paid_amount < 0 then 1 else 0 end) as negative_paid_amount_count,
	sum(case when days_past_due < 0 then 1 else 0 end) as negative_days_past_due_count
from
	loan_payments;

-- 2.3 Invalid fraud risk scores

select
	count(*) as row_count,
	sum(case when risk_score < 1 then 1 else 0 end) as below_range_count,
	sum(case when risk_score > 100 then 1 else 0 end) as above_range_count,
	sum(case when risk_score < 1 or risk_score > 100 then 1 else 0 end) as invalid_risk_score_count,
	round((sum(case when risk_score < 1 or risk_score > 100 then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as invalid_risk_score_percentage
from
	fraud_alerts;

-- 2.4 Invalid loan numeric values

select
	count(*) as row_count,
	sum(case when loan_amount <= 0 then 1 else 0 end) as invalid_loan_amount_count,
	sum(case when interest_rate < 0 then 1 else 0 end) as invalid_interest_rate_count,
	sum(case when term_months <= 0 then 1 else 0 end) as invalid_term_months_count,
	sum(case when monthly_installment <= 0 then 1 else 0 end) as invalid_monthly_installment_count
from
	loans;

-- 3. BUSINESS RULE MISMATCHES

-- 3.1 Overpaid loan installments

select
	count(*) as row_count,
	sum(case when paid_amount > expected_amount then 1 else 0 end) as overpaid_payment_count,
	round(sum(case when paid_amount > expected_amount then paid_amount - expected_amount else 0 end)::numeric, 2) as total_overpaid_amount,
	round((sum(case when paid_amount > expected_amount then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as overpaid_payment_percentage
from
	loan_payments;

-- 3.2 Late payments without valid dpd

select
	count(*) as row_count,
	sum(case when payment_status = 'Late' then 1 else 0 end) as late_payment_count,
	sum(case when payment_status = 'Late' and days_past_due is null then 1 else 0 end) as late_with_null_dpd_count,
	sum(case when payment_status = 'Late' and days_past_due <= 0 then 1 else 0 end) as late_with_non_positive_dpd_count,
	sum(case when payment_status = 'Late' and (days_past_due is null or days_past_due <= 0) then 1 else 0 end) as late_with_invalid_dpd_count,
	round((sum(case when payment_status = 'Late' and (days_past_due is null or days_past_due <= 0) then 1 else 0 end) * 100.0 /
	nullif(sum(case when payment_status = 'Late' then 1 else 0 end), 0))::numeric, 2) as invalid_dpd_percentage_of_late
from
	loan_payments;

-- 3.3 Loans without payment schedule

select
	l.loan_status,
	count(*) as loans_count,
	sum(case when not exists (select 1 from loan_payments lp where lp.loan_id = l.loan_id) then 1 else 0 end) as loans_without_schedule_count,
	round((sum(case when not exists (select 1 from loan_payments lp where lp.loan_id = l.loan_id) then 1 else 0 end) * 100.0 / 
	nullif(count(*), 0))::numeric, 2) as without_schedule_percentage
from
	loans l
group by
	l.loan_status
order by
	loans_without_schedule_count desc;

-- 3.4 Transactions outside account lifecycle

select
	count(*) as linked_transaction_count,
	sum(case when t.transaction_date::date < a.opened_date then 1 else 0 end) as before_account_open_count,
	sum(case when a.closed_date is not null and t.transaction_date::date > a.closed_date then 1 else 0 end) as after_account_close_count,
	sum(case when t.transaction_date::date < a.opened_date or (a.closed_date is not null and t.transaction_date::date > a.closed_date) then 1 else 0 end) as invalid_timing_count,
	count(distinct case when t.transaction_date::date < a.opened_date or (a.closed_date is not null and t.transaction_date::date > a.closed_date) then t.account_id end) as affected_accounts_count,
	round((sum(case when t.transaction_date::date < a.opened_date or (a.closed_date is not null and t.transaction_date::date > a.closed_date) then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as invalid_timing_percentage
from
	transactions t
join accounts a on
	a.account_id = t.account_id;

-- 3.5 Transaction direction mismatch

select
    count(*) as row_count,
    sum(
        case
            when transaction_type = 'Cash Deposit'
             and direction <> 'Credit'
            then 1
            else 0
        end
    ) as cash_deposit_direction_mismatch_count,
    sum(
        case
            when transaction_type = 'Salary'
             and direction <> 'Credit'
            then 1
            else 0
        end
    ) as salary_direction_mismatch_count,
    sum(
        case
            when transaction_type = 'Cash Withdrawal'
             and direction <> 'Debit'
            then 1
            else 0
        end
    ) as cash_withdrawal_direction_mismatch_count,
    sum(
        case
            when transaction_type = 'Card Payment'
             and direction <> 'Debit'
            then 1
            else 0
        end
    ) as card_payment_direction_mismatch_count,
    sum(
        case
            when transaction_type = 'Direct Debit'
             and direction <> 'Debit'
            then 1
            else 0
        end
    ) as direct_debit_direction_mismatch_count,
    sum(
        case
            when transaction_type = 'Fee'
             and direction <> 'Debit'
            then 1
            else 0
        end
    ) as fee_direction_mismatch_count,
    sum(
        case
            when transaction_type = 'Interest'
             and direction <> 'Credit'
            then 1
            else 0
        end
    ) as interest_direction_mismatch_count,
    sum(
        case
            when transaction_type = 'Loan Payment'
             and direction <> 'Debit'
            then 1
            else 0
        end
    ) as loan_payment_direction_mismatch_count,
    sum(
        case
            when (
                transaction_type = 'Cash Deposit'
                and direction <> 'Credit'
            )
            or (
                transaction_type = 'Salary'
                and direction <> 'Credit'
            )
            or (
                transaction_type = 'Cash Withdrawal'
                and direction <> 'Debit'
            )
            or (
                transaction_type = 'Card Payment'
                and direction <> 'Debit'
            )
            or (
                transaction_type = 'Direct Debit'
                and direction <> 'Debit'
            )
            or (
                transaction_type = 'Fee'
                and direction <> 'Debit'
            )
            or (
                transaction_type = 'Interest'
                and direction <> 'Credit'
            )
            or (
                transaction_type = 'Loan Payment'
                and direction <> 'Debit'
            )
            then 1
            else 0
        end
    ) as total_direction_mismatch_count,
    round(
        (
            sum(
                case
                    when (
                        transaction_type = 'Cash Deposit'
                        and direction <> 'Credit'
                    )
                    or (
                        transaction_type = 'Salary'
                        and direction <> 'Credit'
                    )
                    or (
                        transaction_type = 'Cash Withdrawal'
                        and direction <> 'Debit'
                    )
                    or (
                        transaction_type = 'Card Payment'
                        and direction <> 'Debit'
                    )
                    or (
                        transaction_type = 'Direct Debit'
                        and direction <> 'Debit'
                    )
                    or (
                        transaction_type = 'Fee'
                        and direction <> 'Debit'
                    )
                    or (
                        transaction_type = 'Interest'
                        and direction <> 'Credit'
                    )
                    or (
                        transaction_type = 'Loan Payment'
                        and direction <> 'Debit'
                    )
                    then 1
                    else 0
                end
            ) * 100.0
            / nullif(count(*), 0)
        )::numeric,
        2
    ) as direction_mismatch_percentage
from transactions;

-- 3.6 Loan customer and account owner mismatch

select
	count(*) as linked_loan_counts,
	sum(case when l.customer_id <> a.customer_id then 1 else 0 end) as customer_account_mismatch_count,
	round((sum(case when l.customer_id <> a.customer_id then 1 else 0 end) * 100.0 /
	nullif(count(*), 0))::numeric, 2) as mismatch_percentage
from
	loans l
join valid_accounts a on
	a.account_id = l.account_id;