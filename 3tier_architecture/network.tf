resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "3-tier-vpc" }
}

# Example of one Public Subnet (You would typically create two for high availability)
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

# Example of one Private App Subnet
resource "aws_subnet" "private_app_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"
}

# Example of one Private DB Subnet
resource "aws_subnet" "private_db_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
}

# Second Public Subnet (For the ALB)
resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
}

# Second Private App Subnet (For the Auto Scaling Group)
resource "aws_subnet" "private_app_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "ap-south-1b"
}

# Second Private DB Subnet (For the RDS Database)
resource "aws_subnet" "private_db_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "ap-south-1b"
}

# ------------------------------------------------------------------------------
# INTERNET GATEWAY & ROUTING
# ------------------------------------------------------------------------------

# 1. The Internet Gateway (The door to the internet for the VPC)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

# 2. Public Route Table (Tells traffic how to reach the IGW)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # This means "all internet traffic"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-route-table" }
}

# 3. Associate the Public Subnets with this Route Table
resource "aws_route_table_association" "public_1a_assoc" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_1b_assoc" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public_rt.id
}

# ------------------------------------------------------------------------------
# NAT GATEWAY & PRIVATE ROUTING
# ------------------------------------------------------------------------------

# 1. Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# 2. The NAT Gateway (Must reside in a Public Subnet)
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1a.id
  tags          = { Name = "main-nat-gw" }

  depends_on = [aws_internet_gateway.igw]
}

# 3. Private Route Table (Directs outbound traffic to the NAT Gateway)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = { Name = "private-route-table" }
}

# 4. Associate the Private App Subnets with this Private Route Table
resource "aws_route_table_association" "private_app_1a_assoc" {
  subnet_id      = aws_subnet.private_app_1a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_app_1b_assoc" {
  subnet_id      = aws_subnet.private_app_1b.id
  route_table_id = aws_route_table.private_rt.id
}