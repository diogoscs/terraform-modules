locals {
  default-tags = {
    managed-by = "terraform"
    project    = var.name
  }
}

################
# VPC SETTINGS #
################
resource "aws_vpc" "main" {

  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    {
      Name = "${var.name}-vpc"
    },
    var.tags,
    local.default-tags
  )
}

####################
# SUBNETS SETTINGS #
####################

# PRD PUBLIC SUBNETS
#-------------------
locals {
  len_prd_public_subnets    = length(var.prd_public_subnets)
  create_prd_public_subnets = local.len_prd_public_subnets > 0
}

resource "aws_subnet" "prd_public" {

  count = local.create_prd_public_subnets ? local.len_prd_public_subnets : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = element(concat(var.prd_public_subnets, [""]), count.index)
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      Name = try(
        var.prd_public_subnets_names[count.index],
        format("${var.name}-${var.prd_public_subnets_suffix}-%s", element(var.azs, count.index))
      )
      environment = var.env_prd
      subnet-type = "${var.env_prd}-public"
    },
    var.tags,
    local.default-tags
  )
}

# PRD PRIVATE SUBNETS
#---------------------
locals {
  len_prd_private_subnets    = length(var.prd_private_subnets)
  create_prd_private_subnets = local.len_prd_private_subnets > 0
}

resource "aws_subnet" "prd_private" {

  count = local.create_prd_private_subnets ? local.len_prd_private_subnets : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = element(concat(var.prd_private_subnets, [""]), count.index)
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      Name = try(
        var.prd_private_subnets_names[count.index],
        format("${var.name}-${var.prd_private_subnets_suffix}-%s", element(var.azs, count.index))
      )
      environment = var.env_prd
      subnet-type = "${var.env_prd}-private"
    },
    var.tags,
    local.default-tags
  )
}

# DEV PUBLIC SUBNETS
#--------------------
locals {
  len_dev_public_subnets    = length(var.dev_public_subnets)
  create_dev_public_subnets = local.len_dev_public_subnets > 0
}

resource "aws_subnet" "dev_public" {

  count = local.create_dev_public_subnets ? local.len_dev_public_subnets : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = element(concat(var.dev_public_subnets, [""]), count.index)
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      Name = try(
        var.dev_public_subnets_names[count.index],
        format("${var.name}-${var.dev_public_subnets_suffix}-%s", element(var.azs, count.index))
      )
      environment = var.env_dev
      subnet-type = "${var.env_dev}-public"
    },
    var.tags,
    local.default-tags
  )
}

# DEV PRIVATE SUBNETS
#---------------------
locals {
  len_dev_private_subnets    = length(var.dev_private_subnets)
  create_dev_private_subnets = local.len_dev_private_subnets > 0
}

resource "aws_subnet" "dev_private" {

  count = local.create_dev_private_subnets ? local.len_dev_private_subnets : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = element(concat(var.dev_private_subnets, [""]), count.index)
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      Name = try(
        var.dev_private_subnets_names[count.index],
        format("${var.name}-${var.dev_private_subnets_suffix}-%s", element(var.azs, count.index))
      )
      environment = var.env_dev
      subnet-type = "${var.env_dev}-private"
    },
    var.tags,
    local.default-tags
  )
}

# NET RESOURCES SUBNETS
#-----------------------
locals {
  len_net_resources_subnets    = length(var.net_resources_subnets)
  create_net_resources_subnets = local.len_net_resources_subnets > 0
}

resource "aws_subnet" "net_resources" {

  count = local.create_net_resources_subnets ? local.len_net_resources_subnets : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = element(concat(var.net_resources_subnets, [""]), count.index)
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      Name = try(
        var.net_resources_subnets_names[count.index],
        format("${var.name}-${var.net_resources_subnets_suffix}-%s", element(var.azs, count.index))
      )
      environment = var.env_net
      subnet-type = var.env_net
    },
    var.tags,
    local.default-tags
  )
}

################
# ACL SETTINGS #
################

# ACL PRD
#---------
locals {
  create_prd_network_acl = local.create_prd_public_subnets || local.create_prd_private_subnets
}

resource "aws_network_acl" "prd" {
  count = local.create_prd_network_acl ? 1 : 0

  vpc_id = aws_vpc.main.id
  subnet_ids = concat(
    coalesce(flatten(aws_subnet.prd_public[*].id), []),
    coalesce(flatten(aws_subnet.prd_private[*].id), []),
  )

  dynamic "ingress" {
    for_each = var.nacl_prd_ingress_rules
      content {
        from_port       = lookup(ingress.value, "from_port", null)
        to_port         = lookup(ingress.value, "to_port", null)
        protocol        = lookup(ingress.value, "protocol", null)
        rule_no         = lookup(ingress.value, "rule_no", null)
        action          = lookup(ingress.value, "action", null)
        cidr_block      = lookup(ingress.value, "cidr_block", null)
        }
  }
  
  dynamic "egress" {
    for_each = var.nacl_prd_egress_rules
      content {
        from_port       = lookup(egress.value, "from_port", null)
        to_port         = lookup(egress.value, "to_port", null)
        protocol        = lookup(egress.value, "protocol", null)
        rule_no         = lookup(egress.value, "rule_no", null)
        action          = lookup(egress.value, "action", null)
        cidr_block      = lookup(egress.value, "cidr_block", null)
    }
  }

  tags = merge(
    {
      Name        = "${var.name}-${var.env_prd}-acl"
      environment = var.env_prd
    },
    var.tags,
    local.default-tags
  )
}

# ACL DEV
#---------
locals {
  create_dev_network_acl = local.create_dev_public_subnets || local.create_dev_private_subnets
}

resource "aws_network_acl" "dev" {
  count = local.create_dev_network_acl ? 1 : 0

  vpc_id = aws_vpc.main.id
  subnet_ids = concat(
    coalesce(flatten(aws_subnet.dev_public[*].id), []),
    coalesce(flatten(aws_subnet.dev_private[*].id), []),
  )

  dynamic "ingress" {
    for_each = var.nacl_dev_ingress_rules
      content {
        from_port       = lookup(ingress.value, "from_port", null)
        to_port         = lookup(ingress.value, "to_port", null)
        protocol        = lookup(ingress.value, "protocol", null)
        rule_no         = lookup(ingress.value, "rule_no", null)
        action          = lookup(ingress.value, "action", null)
        cidr_block      = lookup(ingress.value, "cidr_block", null)
        }
  }
  
  dynamic "egress" {
    for_each = var.nacl_dev_egress_rules
      content {
        from_port       = lookup(egress.value, "from_port", null)
        to_port         = lookup(egress.value, "to_port", null)
        protocol        = lookup(egress.value, "protocol", null)
        rule_no         = lookup(egress.value, "rule_no", null)
        action          = lookup(egress.value, "action", null)
        cidr_block      = lookup(egress.value, "cidr_block", null)
    }
  }

  tags = merge(
    {
      Name        = "${var.name}-${var.env_dev}-acl"
      environment = var.env_dev
    },
    var.tags,
    local.default-tags
  )
}

# ACL NET
#---------
locals {
  create_net_network_acl = local.create_net_resources_subnets
}

resource "aws_network_acl" "net" {
  count = local.create_net_network_acl ? 1 : 0

  vpc_id = aws_vpc.main.id
  subnet_ids = concat(
    coalesce(flatten(aws_subnet.net_resources[*].id), []))

  dynamic "ingress" {
    for_each = var.nacl_net_ingress_rules
      content {
        from_port       = lookup(ingress.value, "from_port", null)
        to_port         = lookup(ingress.value, "to_port", null)
        protocol        = lookup(ingress.value, "protocol", null)
        rule_no         = lookup(ingress.value, "rule_no", null)
        action          = lookup(ingress.value, "action", null)
        cidr_block      = lookup(ingress.value, "cidr_block", null)
        }
  }
  
  dynamic "egress" {
    for_each = var.nacl_net_egress_rules
      content {
        from_port       = lookup(egress.value, "from_port", null)
        to_port         = lookup(egress.value, "to_port", null)
        protocol        = lookup(egress.value, "protocol", null)
        rule_no         = lookup(egress.value, "rule_no", null)
        action          = lookup(egress.value, "action", null)
        cidr_block      = lookup(egress.value, "cidr_block", null)
    }
  }

  tags = merge(
    {
      Name        = "${var.name}-${var.env_net}-acl"
      environment = var.env_net
    },
    var.tags,
    local.default-tags
  )
}

#############################
# INTERNET GATEWAY SETTINGS #
#############################
resource "aws_internet_gateway" "gw" {
  count  = local.prd_public_route_tables ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.name}-igw"
      environment = var.env_general
    },
    var.tags,
    local.default-tags
  )
}

resource "aws_route" "public_prd_internet_gateway" {
  count = local.prd_public_route_tables ? 1 : 0

  route_table_id         = aws_route_table.prd_public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw[0].id
}

resource "aws_route" "public_dev_internet_gateway" {
  count = local.dev_public_route_tables ? 1 : 0

  route_table_id         = aws_route_table.dev_public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw[0].id
}

resource "aws_route" "net_resources_internet_gateway" {
  count = local.net_resources_route_tables ? 1 : 0

  route_table_id         = aws_route_table.net_resources[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw[0].id
}

################
# EIP SETTINGS #
################
resource "aws_eip" "nat_gw" {
  count = local.create_prd_public_subnets && var.enable_nat_gateway ? 1 : 0

  domain = "vpc"
  tags = merge(
    {
      Name = "${var.name}-natgw"
      environment = var.env_general
    },
    var.tags,
    local.default-tags
  )
}

###################
# NAT GW SETTINGS #
###################
resource "aws_nat_gateway" "main" {
  count = local.create_prd_public_subnets && var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat_gw[0].id
  subnet_id     = try(aws_subnet.net_resources[0].id,aws_subnet.prd_public[0].id)
  tags = merge(
    {
      Name = "${var.name}-natgw"
      environment = var.env_general
    },
    var.tags,
    local.default-tags
  )

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route" "public_prd_nat_gateway" {
  count = local.prd_private_route_tables && var.enable_nat_gateway ? 1 : 0

  route_table_id         = try(aws_route_table.prd_private[0].id)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.main[0].id

}

resource "aws_route" "public_dev_nat_gateway" {
  count = local.dev_private_route_tables && var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.dev_private[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.main[0].id

}

########################
# ROUTE TABLE SETTINGS #
########################

# PRD PUBLIC RTB
#----------------
locals {
  prd_public_route_tables = local.len_prd_public_subnets > 0
}

resource "aws_route_table" "prd_public" {
  count = local.prd_public_route_tables ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = "${var.name}-${var.env_prd}-public-rtb"
      environment = var.env_prd
    },
    var.tags,
    local.default-tags
  )
}

resource "aws_route_table_association" "prd_public" {
  count = local.prd_public_route_tables ? local.len_prd_public_subnets : 0

  subnet_id      = aws_subnet.prd_public[count.index].id
  route_table_id = aws_route_table.prd_public[0].id
}

# PRD PRIVATE RTB
#-----------------
locals {
  prd_private_route_tables = local.len_prd_private_subnets > 0
}

resource "aws_route_table" "prd_private" {
  count = local.prd_private_route_tables ? 1 : 0

  vpc_id = aws_vpc.main.id
  tags = merge(
    {
      Name        = "${var.name}-${var.env_prd}-private-rtb"
      environment = var.env_prd
    },
    var.tags,
    local.default-tags
  )
}

resource "aws_route_table_association" "prd_private" {
  count = local.prd_private_route_tables ? local.len_prd_private_subnets : 0

  subnet_id      = aws_subnet.prd_private[count.index].id
  route_table_id = aws_route_table.prd_private[0].id
}

# DEV PUBLIC RTB
#----------------
locals {
  dev_public_route_tables = local.len_dev_public_subnets > 0
}

resource "aws_route_table" "dev_public" {
  count = local.dev_public_route_tables ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name        = "${var.name}-${var.env_dev}-public-rtb"
      environment = var.env_dev
    },
    var.tags,
    local.default-tags
  )
}

resource "aws_route_table_association" "dev_public" {
  count = local.dev_public_route_tables ? local.len_dev_public_subnets : 0

  subnet_id      = aws_subnet.dev_public[count.index].id
  route_table_id = aws_route_table.dev_public[0].id
}

# DEV PRIVATE RTB
#-----------------
locals {
  dev_private_route_tables = local.len_dev_private_subnets > 0
}

resource "aws_route_table" "dev_private" {
  count = local.dev_private_route_tables ? 1 : 0

  vpc_id = aws_vpc.main.id
  tags = merge(
    {
      Name        = "${var.name}-${var.env_dev}-private-rtb"
      environment = var.env_dev
    },
    var.tags,
    local.default-tags
  )
}

resource "aws_route_table_association" "dev_private" {
  count = local.dev_private_route_tables ? local.len_dev_private_subnets : 0

  subnet_id      = aws_subnet.dev_private[count.index].id
  route_table_id = aws_route_table.dev_private[0].id
}

# NET RESOURCES RTB
#-------------------
locals {
  net_resources_route_tables = local.len_net_resources_subnets > 0
}

resource "aws_route_table" "net_resources" {
  count = local.net_resources_route_tables ? 1 : 0

  vpc_id = aws_vpc.main.id
  tags = merge(
    {
      Name        = "${var.name}-${var.env_net}-net-rtb"
      environment = var.env_net
    },
    var.tags,
    local.default-tags
  )
}

resource "aws_route_table_association" "net_resources" {
  count = local.net_resources_route_tables ? local.len_net_resources_subnets : 0

  subnet_id      = aws_subnet.net_resources[count.index].id
  route_table_id = aws_route_table.net_resources[0].id
}


#########################
# SUBNET GROUP SETTINGS #
#########################

# SUBNET GROUP PRD PRIVATE
#--------------------------
locals {
  create_prd_dbsubnet_group = local.create_prd_public_subnets && local.create_prd_private_subnets
}

resource "aws_db_subnet_group" "prd_private_dbsubnet_group" {
  count = local.create_prd_dbsubnet_group ? 1 : 0

  name        = "${var.name}-subnetgroup-prd-private"
  subnet_ids  = coalesce(flatten(aws_subnet.prd_private[*].id), [])
  description = "Subnet Group PRD do projeto ${var.name}"

  tags = merge(
    {
      environment = var.env_prd
    },
    var.tags,
    local.default-tags
  )
}

# SUBNET GROUP DEV PRIVATE
#--------------------------
locals {
  create_dev_dbsubnet_group = local.create_dev_public_subnets && local.create_dev_private_subnets
}

resource "aws_db_subnet_group" "dev_private_dbsubnet_group" {
  count = local.create_dev_dbsubnet_group ? 1 : 0

  name        = "${var.name}-subnetgroup-dev-private"
  subnet_ids  = coalesce(flatten(aws_subnet.dev_private[*].id), [])
  description = "Subnet Group DEV do projeto ${var.name}"

  tags = merge(
    {
      environment = var.env_dev
    },
    var.tags,
    local.default-tags
  )
}