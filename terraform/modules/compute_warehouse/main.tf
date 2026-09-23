terraform {
  required_version = ">= 1.5.0"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.21"
    }
  }
}

# ------------------------------------------------------------------------------
# Workload-Isolated Compute Clusters
# Demonstrates architectural pattern for segregating batch ETL transformations
# from high-concurrency BI ad-hoc workloads with automated FinOps auto-suspend.
# ------------------------------------------------------------------------------

resource "snowflake_warehouse" "etl_transformation_wh" {
  name                = "WH_TRANSFORMATION_${upper(var.environment)}"
  warehouse_size      = var.etl_warehouse_size
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "Dedicated compute cluster for dbt Medallion batch transformations."
}

resource "snowflake_warehouse" "bi_serving_wh" {
  name                = "WH_BI_SERVING_${upper(var.environment)}"
  warehouse_size      = var.bi_warehouse_size
  auto_suspend        = 300
  auto_resume         = true
  initially_suspended = true
  comment             = "Dedicated compute cluster for BI tools and self-serve ad-hoc reporting."
}
