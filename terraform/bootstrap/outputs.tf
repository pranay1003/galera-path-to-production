output "deploy_role_arn" {
  description = "Set this as the AWS_DEPLOY_ROLE repo variable (used by deploy.yml)."
  value       = aws_iam_role.deploy.arn
}
