resource "aws_db_subnet_group" "db_subnet" {
  name       = "main-db-subnet"
  subnet_ids = [aws_subnet.private_db_1a.id, aws_subnet.private_db_1b.id] 
}

resource "aws_db_instance" "app_db" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "appdata"
  username               = "admin"
  password               = "securepassword123"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.db_sg.id] 
  skip_final_snapshot    = true
}

