-- ======================================================
-- 03 CLEAN VIEWS
-- ======================================================

-- 1. CLEAN CUSTOMERS
-- Grain: 1 row = 1 customer_id

create or replace view clean_customers as
with ranked_customers as (
	select
		*,
		row_number() over (partition by customer_id order by customer_row_id desc) as rn
	from customers
	where customer_id is not null)
select
	customer_id,
	customer_name,
	birth_date,
	country,
	city,
	customer_since,
	customer_segment,
	employment_status,
	annual_income,
	risk_rating,
	is_pep,
	customer_status,
	email,
	phone
from ranked_customers
where rn = 1;

-- 2. VALID ACCOUNTS
-- Grain: 1 row = 1 account_id

create or replace view valid_accounts as
select
	a.*
from
	accounts a
where
	(a.closed_date is null
		or a.closed_date >= a.opened_date)
	and exists (
	select
		1
	from
		clean_customers c
	where
		c.customer_id = a.customer_id)
	and exists (
	select
		1
	from
		branches b
	where
		b.branch_id = a.branch_id);

-- 3. VALID TRANSACTIONS
-- Grain: 1 row = 1 transaction_id

create or replace view valid_transactions as 
select
	t.*
from transactions t
join valid_accounts a on a.account_id = t.account_id
where t.amount > 0 and
	t.transaction_date::date >= a.opened_date and
	(a.closed_date is null or t.transaction_date::date <= a.closed_date) and
	((t.transaction_type = 'Salary' and t.direction = 'Credit') or
	(t.transaction_type = 'Cash Withdrawal' and t.direction = 'Debit') or
	(t.transaction_type = 'Card Payment' and t.direction = 'Debit') or
	(t.transaction_type = 'Bank Transfer' and t.direction in ('Credit', 'Debit')) or
	(t.transaction_type = 'Cash Deposit' and t.direction = 'Credit') or
	(t.transaction_type = 'Direct Debit' and t.direction = 'Debit') or
	(t.transaction_type = 'Fee' and t.direction = 'Debit') or
	(t.transaction_type = 'Interest' and t.direction = 'Credit') or
	(t.transaction_type = 'Loan Payment' and t.direction = 'Debit'));

-- 4. VALID LOANS
-- Grain: 1 row = 1 loan_id

create or replace view valid_loans as 
select
	l.*
from
	loans l
join valid_accounts a on
	a.account_id = l.account_id
	and a.customer_id = l.customer_id
where
	l.loan_amount > 0
	and
	l.interest_rate >= 0
	and
	l.term_months > 0
	and 
	l.monthly_installment > 0
	and
	(l.approval_date is null
		or l.approval_date >= l.application_date);

-- 5. VALID LOAN PAYMENTS
-- Grain: 1 row = 1 payment_id

create or replace view valid_loan_payments as
select
	lp.*,
	case
		when lp.payment_status = 'Late'
		and (lp.days_past_due is null
		or lp.days_past_due <= 0) then true
		else false
	end as has_invalid_dpd
from
	loan_payments lp
where
	lp.expected_amount > 0
	and
	lp.paid_amount >= 0
	and
	(lp.days_past_due is null or lp.days_past_due >= 0)
	and
	exists (
	select
		1
	from
		valid_loans l
	where
		l.loan_id = lp.loan_id);

-- 6. VALID CARDS
-- Grain: 1 row = 1 card_id

create or replace view valid_cards as
select
	c.*
from cards c
where c.daily_limit >= 0 and
	c.expiry_date >= c.issued_date and
	exists (
		select 1
		from valid_accounts a
		where a.account_id = c.account_id);

-- 7. VALID FRAUD ALERTS
-- Grain: 1 row = 1 alert_id

create or replace view valid_fraud_alerts as
select
	f.alert_id,
	f.transaction_id,
	a.customer_id,
	f.customer_id as source_customer_id,
	f.alert_date,
	f.alert_type,
	f.risk_score,
	f.alert_status,
	f.investigation_outcome,
	case
		when f.customer_id is not null
		and f.customer_id <> a.customer_id then true
		else false
	end as customer_id_mismatch
from
	fraud_alerts f
join valid_transactions t on
	t.transaction_id = f.transaction_id
join valid_accounts a on
	a.account_id = t.account_id
where
	f.risk_score between 1 and 100;

-- 8. VALID CUSTOMER CONTACTS
-- Grain: 1 row = contact_id

create or replace view valid_customer_contacts as
select
	cc.*
from
	customer_contacts cc
where
	exists (
	select
		1
	from
		clean_customers c
	where
		c.customer_id = cc.customer_id);