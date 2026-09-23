variable "environment" {
  description = "Deployment environment label, such as dev, test, or prod."
  type        = string
  default     = "dev"
}

variable "etl_warehouse_size" {
  description = "Warehouse sizing for transformation workloads."
  type        = string
  default     = "XSMALL"
}

variable "bi_warehouse_size" {
  description = "Warehouse sizing for BI and self-service accounting workloads."
  type        = string
  default     = "SMALL"
}
