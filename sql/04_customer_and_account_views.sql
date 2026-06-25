-- ======================================================
-- 04 CUSTOMER AND ACCOUNT VIEWS
-- ======================================================

-- 1. CUSTOMER ACCOUNT PORTFOLIO
-- Grain: 1 row = 1 customer_id

create or replace
view customer_account_portfolio as
select
	c.customer_id,
	c.customer_name,
	c.customer_segment,
	c.risk_rating,
	c.customer_status,
	count(a.account_id) as account_count,
	sum(case when a.account_id is not null and a.closed_date is null then 1 else 0 end) as open_account_count,
	sum(case when a.closed_date is not null then 1 else 0 end) as closed_account_count,
	coalesce(round(sum(a.current_balance)::numeric, 2), 0) as total_current_balance,
	coalesce(round((sum(a.current_balance) / nullif(count(a.account_id), 0))::numeric, 2), 0) as average_current_balance,
	coalesce(round(sum(a.overdraft_limit)::numeric, 2), 0) as total_overdraft_limit,
	sum(case when a.current_balance < 0 then 1 else 0 end) as negative_balance_account_count,
	min(a.opened_date) as first_account_opened_date,
	max(a.opened_date) as latest_account_opened_date
from
	clean_customers c
left join valid_accounts a on
	a.customer_id = c.customer_id
group by
	1,
	2,
	3,
	4,
	5;

-- 2. BRANCH ACCOUNT PORTFOLIO
-- Grain: 1 row = 1 branch_id

create or replace view branch_account_portfolio as 
select
	b.branch_id,
	b.branch_name,
	b.city,
	b.region,
	b.manager_name,
	b.opened_date as branch_opened_date,
	count(distinct a.customer_id) as customer_count,
	count(a.account_id) as account_count,
	sum(case when a.account_id is not null and a.closed_date is null then 1 else 0 end) as open_account_count,
	sum(case when a.closed_date is not null then 1 else 0 end) as closed_account_count,
	coalesce(round(sum(a.current_balance)::numeric, 2), 0) as total_current_balance,
	coalesce(round(avg(a.current_balance)::numeric, 2), 0) as average_current_balance,
	coalesce(round(sum(a.overdraft_limit)::numeric, 2), 0) as total_overdraft_limit,
	sum(case when a.current_balance < 0 then 1 else 0 end) as negative_balance_account_count
from branches b
left join valid_accounts a on a.branch_id = b.branch_id
group by 1, 2, 3, 4, 5, 6;

-- 3. ACCOUNT ACTIVITY MONITORING
-- Grain: 1 row = 1 account_id

create or replace view account_activity_monitoring as 
with reference_date as (
select
		max(transaction_date::date) as snapshot_date
from
	valid_transactions),
transaction_summary as (
select
		account_id,
		count(*) as transaction_count,
		min(transaction_date::date) as first_transaction_date,
		max(transaction_date::date) as last_transaction_date
from
	valid_transactions
group by
	account_id)
select
	a.account_id,
	a.customer_id,
	a.branch_id,
	a.account_type,
	a.account_status,
	a.current_balance,
	a.opened_date,
	a.closed_date,
	coalesce(ts.transaction_count, 0) as transaction_count,
	ts.first_transaction_date,
	ts.last_transaction_date,
	r.snapshot_date - ts.last_transaction_date as days_since_last_transaction,
	case
		when a.closed_date is not null then 'Closed'
		when ts.transaction_count is null then 'No Transactions'
		when r.snapshot_date - ts.last_transaction_date > 90 then 'Dormant'
		else 'Active'
	end as account_activity_status
from
	valid_accounts a
left join transaction_summary ts on
	ts.account_id = a.account_id
cross join reference_date r;