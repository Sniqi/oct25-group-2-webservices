output "node_group_name" {
  value = aws_eks_node_group.default.node_group_name
}

output "node_role_arn" {
  value = aws_iam_role.node_role.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc.arn
}
