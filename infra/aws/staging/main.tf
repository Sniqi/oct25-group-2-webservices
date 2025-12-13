terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # This project uses a single EKS cluster and separates environments via namespaces.
  # Apply cluster infra from infra/aws/dev. Namespace/app resources live under k8s/.
}

provider "aws" {
  region = "eu-west-3" # Paris
}
