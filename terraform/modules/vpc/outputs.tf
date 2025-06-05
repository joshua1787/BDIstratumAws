output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "vpc_default_route_table_id" {
  description = "The ID of the main route table associated with the VPC."
  value       = aws_vpc.main.default_route_table_id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways. Empty if NAT Gateway is disabled."
  value       = aws_eip.nat[*].public_ip
}

output "igw_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.gw.id
}