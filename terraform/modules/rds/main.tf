data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.db_credentials_secret_arn
}

locals {
  db_creds             = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
  db_resolved_username = local.db_creds[var.db_master_username_in_secret]
  db_resolved_password = local.db_creds["password"]

  source_sg_id_map = {
    for idx, sg_id in var.db_security_group_ingress_source_sg_ids : tostring(idx) => sg_id
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "${var.project_name}-${var.environment}-rds-sng"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-sng"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow PostgreSQL traffic to RDS instance"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = length(var.db_security_group_ingress_cidr_blocks) > 0 ? var.db_security_group_ingress_cidr_blocks : []
    content {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "Allow PostgreSQL from specified CIDR"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  })
}

resource "aws_security_group_rule" "rds_ingress_from_source_sgs" {
  for_each = local.source_sg_id_map

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.rds.id
  description              = "Allow PostgreSQL from Source SG ${each.value}"
}

resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-${var.environment}-rds"
  allocated_storage      = var.db_allocated_storage
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = local.db_resolved_username
  password               = local.db_resolved_password
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = var.skip_final_snapshot
  multi_az               = var.multi_az
  publicly_accessible    = false

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-instance"
  })
}