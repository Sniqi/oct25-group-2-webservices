# EKS Terraform module

Minimal EKS module (cluster + managed node group) intended for training/demo.

- Private API endpoint only (`endpoint_public_access = false`)
- Nodes in private subnets

Use from env roots under `infra/aws/*`.
