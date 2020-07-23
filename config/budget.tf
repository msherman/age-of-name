resource "aws_budgets_budget" "total_cost" {
  budget_type       = "COST"
  limit_amount      = "50.0"
  limit_unit        = "USD"
  time_period_end   = "2050-01-01_00:00"
  time_period_start = "2020-01-01_00:00"
  time_unit         = "MONTHLY"
}