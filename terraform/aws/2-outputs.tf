output "aws_oidc_audience" {
    description = "OIDC audience used for AWS GitHub Actions"
    value       = "sts.amazonaws.com"
}

output "aws_region" {
    description = "AWS region where the OIDC provider is created"
    value       = var.aws_region
}

output "aws_oidc_roles_to_assume" {
    description = "Map of IAM roles for GitHub OIDC workflows to assume"
    value = {
        for k, role in aws_iam_role.github_oidc_roles : 
            k => role.arn
    }
}