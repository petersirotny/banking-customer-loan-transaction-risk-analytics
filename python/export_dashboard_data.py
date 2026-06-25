import pandas as pd
from sqlalchemy import create_engine
from pathlib import Path


DB_URL = "postgresql+psycopg2://postgres:1234@localhost:5432/banking_realworld_v1"

OUTPUT_DIR = Path("output/csv")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


views = {
    "customer_account_portfolio": "customer_account_portfolio",
    "branch_account_portfolio": "branch_account_portfolio",
    "account_activity_monitoring": "account_activity_monitoring",
    "loan_portfolio_base": "loan_portfolio_base",
    "monthly_transaction_summary": "monthly_transaction_summary",
    "fraud_monitoring_summary": "fraud_monitoring_summary",
}


engine = create_engine(DB_URL)

for output_name, view_name in views.items():
    df = pd.read_sql_query(f"select * from {view_name}", engine)
    output_path = OUTPUT_DIR / f"{output_name}.csv"
    df.to_csv(output_path, index=False)
    print(f"Exported {output_name}: {len(df)} rows")