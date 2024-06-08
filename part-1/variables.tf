# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "aws_access_key_id" {
  type        = string
  description = "AWS access key ID"
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret access key"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "app_name" {
  type        = string
  description = "Application name"
}

variable "app_environment" {
  type        = string
  description = "Application environment"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC IPv4 CIDR"
}

variable "subnet_1_cidr" {
  type        = string
  description = "IPv4 CIDR for Redshift subnet 1"
}

variable "subnet_2_cidr" {
  type        = string
  description = "IPv4 CIDR for Redshift subnet 2"
}

variable "redshift_cluster_name" {
  description = "The name used to namespace all resources created by these module, including the DB instance. Must be unique for this region. May contain only lowercase alphanumeric characters, hyphens"
  type        = string
}

variable "redshift_master_username" {
  description = "The username for the master user"
  type        = string
}

variable "redshift_database_name" {
  description = "Redshift Database Name"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "redshift_node_type" {
  type        = string
  description = "Redshift Node Type"
  default     = "dc2.large"
}

variable "redshift_cluster_type" {
  type        = string
  description = "Redshift Cluster Type"
  default     = "single-node" // options are single-node or multi-node
}

variable "redshift_number_of_nodes" {
  type        = number
  description = "Redshift Number of Nodes in the Cluster"
  default     = 1
}

variable "redshift_manage_master_password" {
  description = "Whether to use AWS SecretsManager to manage the Redshift cluster admin credentials."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
