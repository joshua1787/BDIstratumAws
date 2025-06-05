db_credentials_secret_arn = "arn:aws:secretsmanager:us-east-1:842346213197:secret:stratum/rds/credentials-x4yssG"


availability_zones = ["us-east-1a", "us-east-1b"] # Example for us-east-1 region

# aws_region = "us-east-1" # Uncomment if you want to explicitly set the region here
# project_name = "stratum"

# vpc_cidr = "10.0.0.0/16"
# public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
# private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

# db_instance_class = "db.t3.micro"
# db_name           = "stratumdb"
# rds_multi_az      = false
# rds_skip_final_snapshot = true

 temporary_db_access_cidrs = ["117.196.34.50/32"]