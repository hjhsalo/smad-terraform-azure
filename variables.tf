#
## Global variables used in many modules
#

variable "environment" {
  default = "development"
}

variable "location" {
  default = "West Europe"
}

variable "project_name" {
  default = "kuksatrng"
}

#
## Terraform Shared State -module related variables
#
# NOTE:
# Since storage for Terraform Shared State cannot be created in the 
# same Terraform script that creates K8S resources, these variables are
# also defined in './modules/tfstate_storage_azure/variables.tf'.
# If you already have a storage for Terraform Shared State, you can 
# change these variables to match your configuration.
# If you plan to customize these variables when creating storage for 
# Terraform Shared State with './modules/tfstate_storage_azure/main.tf', 
# you must also change the variables in 
# './modules/tfstate_storage_azure/variables.tf'.

variable "tfstate_resource_group_name_suffix" {
  default = "tfstate-rg"
}

# 'name' must be unique across the entire Azure service, 
#  not just within the resource group.
# 'name' can only consist of lowercase letters and numbers, 
#  and must be between 3 and 24 characters long.
variable "tfstate_storage_account_name_suffix" {
  default = "tfstatesa"
}

variable "tfstate_container_name" {
  default = "tfstate"
}

#
## Azure Kubernetes Service -module related variables
#


variable "k8s_agent_count" {
  default = 3
}

# Specify node count for testing purposes
variable "testing_k8s_agent_count" {
  default = 2
}


# variable "k8s_ssh_public_key" {
#     default = "~/.ssh/id_rsa.pub"
# }

variable "k8s_dns_prefix" {
  default = "k8stest"
}

variable "k8s_resource_group_name_suffix" {
  default = "k8stest-rg"
}

variable "k8s_cluster_name_suffix" {
  default = "k8stest-cluster"
}

# You can use the same resource group that was used with K8S cluster in AKS
# 'k8s_resource_group_name_suffix'
variable "container_registry_resource_group_suffix" {
  default = "k8stest-rg"
}

variable "log_analytics_workspace_name" {
  default = "testLogAnalyticsWorkspaceName"
}

# refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
variable "log_analytics_workspace_location" {
  default = "westeurope"
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
variable "log_analytics_workspace_sku" {
  default = "PerGB2018"
}

variable "cluster_name" {
  default = "k8stest"
}

variable "resource_group_name" {
  default = "azure-k8stest"
}


#variable "enable_influxdb_module" {
#  type        = bool
#  default     = true
#  description = "Enable influxdb module"
#}

###################################
## Container deployment variables##
###################################

variable "mongodb_username" {
  default = "honouser"
  type    = string
}

variable "mongodb_password" {
  default = "hono-secret"
  type    = string
}

variable "use_separate_storage_rg" {
  default     = false
  type        = bool
  description = "If true, use a separate resource group for storage needs. The resource group must be created via the separate module beforehand."
}

variable "email" {
  default = ""
  type = string
  description = "Email address for obtaining TLS certificates via cert-manager"
}