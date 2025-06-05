# ~/Stratum_JD_AWS/terraform/modules/vpc/main.tf

# Defines the AWS Virtual Private Cloud (VPC) and its core networking components.

# --- VPC Resource ---
resource "aws_vpc" "main" {
  # CIDR block for the VPC, defined by the calling module.
  cidr_block           = var.vpc_cidr
  # Enable DNS support (e.g., DNS resolution for AWS services).
  enable_dns_support   = true
  # Enable DNS hostnames (e.g., EC2 instances get a public DNS name).
  enable_dns_hostnames = true

  # Merge common tags with VPC-specific tags.
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# --- Internet Gateway (IGW) ---
# Allows communication between resources in the VPC and the internet.
resource "aws_internet_gateway" "gw" {
  # Attaches the IGW to the created VPC.
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

# --- Data Source: AWS Availability Zones ---
# Dynamically fetches available Availability Zones in the specified region.
# This helps distribute subnets across AZs for high availability.
data "aws_availability_zones" "available" {
  # Filter for 'available' state zones.
  state = "available"
}

# --- Public Subnets ---
# Creates multiple public subnets based on the provided CIDR blocks.
resource "aws_subnet" "public" {
  # 'count' creates an instance of this resource for each CIDR in the list.
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  # Distributes subnets evenly across available AZs.
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  # Instances launched in these subnets automatically get a public IP address.
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  })
}

# --- Private Subnets ---
# Creates multiple private subnets based on the provided CIDR blocks.
resource "aws_subnet" "private" {
  # 'count' creates an instance of this resource for each CIDR in the list.
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  # Distributes subnets evenly across available AZs.
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  # Private subnets typically do not automatically assign public IP addresses.
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  })
}

# --- Elastic IP (EIP) for NAT Gateway ---
# Required for NAT Gateway to provide a static public IP address.
resource "aws_eip" "nat" {
  # Only create if NAT Gateway is enabled.
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(aws_subnet.public)) : 0
  vpc   = true # Associates the EIP with the VPC.

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  })
}

# --- NAT Gateway ---
# Allows instances in private subnets to initiate outbound connections to the internet.
resource "aws_nat_gateway" "gw" {
  # Only create if NAT Gateway is enabled.
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(aws_subnet.public)) : 0
  # Attaches the NAT Gateway to a public subnet.
  subnet_id     = aws_subnet.public[count.index].id
  # Associates an Elastic IP with the NAT Gateway.
  allocation_id = aws_eip.nat[count.index].id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-gw-${count.index + 1}"
  })
}

# --- Route Table for Public Subnets ---
# The default route table of the VPC is used for public subnets.
# This rule directs all internet-bound traffic (0.0.0.0/0) to the Internet Gateway.
resource "aws_default_route_table" "public" {
  # Refers to the default route table automatically created with the VPC.
  default_route_table_id = aws_vpc.main.default_route_table_id

  # Route for all IPv4 traffic to the Internet Gateway.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-rtb"
  })
}

# --- Route Table for Private Subnets ---
# Creates a new route table for each private subnet.
resource "aws_route_table" "private" {
  # Creates one route table for each private subnet.
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  # Route for all IPv4 traffic to the NAT Gateway.
  route {
    cidr_block = "0.0.0.0/0"
    # Routes to the NAT Gateway. If single_nat_gateway is true, all point to the first NAT GW.
    # Otherwise, each points to its corresponding NAT GW in its AZ.
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.gw[0].id : aws_nat_gateway.gw[count.index].id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-rtb-${count.index + 1}"
  })
}

# --- Route Table Associations for Private Subnets ---
# Associates each private subnet with its respective private route table.
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

