data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "pyforum"
  cidr = "10.20.0.0/16"

  azs              = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets   = ["10.20.1.0/24", "10.20.2.0/24"]
  database_subnets = ["10.20.21.0/24", "10.20.22.0/24"]

  create_database_subnet_group = true
  map_public_ip_on_launch      = true
  enable_nat_gateway           = false
  enable_dns_hostnames         = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
}
