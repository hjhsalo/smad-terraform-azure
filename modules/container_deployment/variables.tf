variable "cluster_name" {
  type = string
}

variable "mongodb_username" {
  default     = "honouser"
  type        = string
  description = "Optional username for  MongoDB"
}

variable "mongodb_password" {
  default     = "hono-secret"
  type        = string
  description = "Optional password for  MongoDB"
}

variable "mongodb_rootPassword" {
  default     = "root-secret"
  type        = string
  description = "Optional password for  MongoDB"
}

variable "ambassador_public_ip" {
  type = string
}

variable "k8s_cluster_rg_name" {
  type = string
}

variable "k8s_dns_prefix" {
  type = string
}
