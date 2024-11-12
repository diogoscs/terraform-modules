output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "cidr_block" {
  description = "The ID of the VPC"
  value       = try(aws_vpc.main.cidr_block, null)
}

output "subnets_prd_private" {
  description = "The ID of the VPC"
  value       = try(aws_subnet.prd_private[*].cidr_block, null)
}

output "subnets_dev_private" {
  description = "The ID of the VPC"
  value       = try(aws_subnet.dev_private[*].cidr_block, null)
}

output "subnets_prd_public" {
  description = "The ID of the VPC"
  value       = try(aws_subnet.prd_public[*].cidr_block, null)
}

output "subnets_dev_public" {
  description = "The ID of the VPC"
  value       = try(aws_subnet.dev_public[*].cidr_block, null)
}

output "subnets_prd_private_id" {
  description = "The ID of the VPC"
  value       = try(aws_subnet.prd_private[*].id, null)
}

output "subnets_dev_private_id" {
  description = "The ID of the VPC"
  value       = try(aws_subnet.dev_private[*].id, null)
}

output "subnets_prd_public_id" {
  description = "The ID of the VPC"
  value       = try(aws_subnet.prd_public[*].id, null)
}

output "subnets_dev_public_id" {
  description = "The ID of the VPC"
  value       = try(aws_subnet.dev_public[*].id, null)
}

output "prd_private_dbsubnet_group" {
  description = "Name of PRD Subnet Group"
  value       = try(aws_db_subnet_group.prd_private_dbsubnet_group[*].name, null)
}

output "dev_private_dbsubnet_group" {
  description = "Name of PRD Subnet Group"
  value       = try(aws_db_subnet_group.dev_private_dbsubnet_group[*].name, null)
}

output "nat_gw_eip" {
  description = "EIP from Nat GW"
  value       = try(aws_eip.nat_gw["0"].public_ip, null)
}