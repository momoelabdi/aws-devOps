# ********** Postgresql instance **********************
resource "aws_db_instance" "db" {
  identifier             = var.db_identifier
  instance_class         = var.db_instance_type
  backup_retention_period = 1
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "17.3"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.db_params.name
  skip_final_snapshot    = true
}

# ******* Postgresql read replica instance ******
resource "aws_db_instance" "replica" {
  identifier             = "${var.db_identifier}-replica"
  replicate_source_db    = aws_db_instance.db.identifier
  instance_class         = var.db_instance_type
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.db_params.name
  skip_final_snapshot    = true
}

#******* DB Subnets ( private ) **********
resource "aws_db_subnet_group" "db_subnet" {
  name       = var.db_subnet_name
  subnet_ids = var.private_subnets_ids
}

# ******* DB @Params ( version ) *************
resource "aws_db_parameter_group" "db_params" {
  name   = "db-params"
  family = "postgres17"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

# TODO restrict access to conerened service only !!
# ************  RDS security group ***********
resource "aws_security_group" "rds" {
  name   = "rds-security-group"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}

