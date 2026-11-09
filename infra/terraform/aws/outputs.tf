output "cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = aws_db_instance.this.address
}

output "rds_secret_arn" {
  value = aws_db_instance.this.master_user_secret[0].secret_arn
}
