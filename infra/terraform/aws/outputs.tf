output "cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = aws_db_instance.this.address
}

output "app_secret_name" {
  value = aws_secretsmanager_secret.app.name
}
