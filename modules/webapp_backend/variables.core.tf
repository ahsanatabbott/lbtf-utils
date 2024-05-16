#===================================================================================================================
# Terraform Cores
# ==================================================================================================================

variable "environment" {
  description = "Please enter a environment i-e: test, stage, prod"
  type        = string
}

variable "customer_identifier" {
  description = "Please enter a customer_identifier i-e: Nike, Spotify, XYZ"
  type        = string
}

variable "component" {
  description = "Please enter a component i-e: terraform, web-app, XYZ"
  type        = string
}

#FIXME - temporarily commented to pass pre-commit check. Once outputs are fixed, uncomment this.
#variable "export_outputs_to_ssm_ps" {
#  type        = bool
#  default     = true
#  description = "Indicates if outputs are exported SSM Parameter Store."
#}

variable "tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }
  description = "Tags for the resources"
}
