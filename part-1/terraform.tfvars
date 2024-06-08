# AWS Credentials
#aws_region     = <region>
#aws_access_key_id = <access-key-id>
#aws_secret_access_key = <secret-access-key>

# Application Definition
app_name        = "sequra-challenge"
app_environment = "dev"

# Network Configuration
vpc_cidr      = "10.20.0.0/16"
subnet_1_cidr = "10.20.1.0/24"
subnet_2_cidr = "10.20.2.0/24"

## Redshift Cluster Variables
redshift_cluster_name       = "sequra-challenge"
redshift_database_name      = "spacex"
redshift_master_username    = "admin"
redshift_node_type          = "dc2.large"
tags = {
  Group = "sequra-challenge"
}
