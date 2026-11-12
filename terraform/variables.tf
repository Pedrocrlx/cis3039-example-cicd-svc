variable "subscription_id" {
  description = "Azure subscription ID used for this deployment. Obtain it with az account show --query id -o tsv."
  type        = string
}

variable "location" {
  description = "Azure region allowed by your subscription policies and supporting Flex Consumption."
  type        = string
}

variable "name_prefix" {
  description = "Globally unique deployment prefix, for example pipeline-lab-ps47. Resource names are derived from it."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}[a-z0-9]$", var.name_prefix))
    error_message = "Use 3 to 20 lowercase letters, digits or hyphens; start with a letter and end with a letter or digit."
  }
}

variable "cors_allowed_origins" {
  description = "Browser origins allowed to call the API, for example http://localhost:5173. Empty disables CORS."
  type        = list(string)
  default     = []
}
