data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name

  # Prevents a hard failure on the first apply when the cluster doesn't exist yet.
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name

  # Same reasoning as above; the auth token requires the cluster to exist.
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# --- EBS CSI (required for PVCs on modern Kubernetes versions) ---

locals {
  oidc_issuer = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_host   = replace(local.oidc_issuer, "https://", "")
}

resource "aws_iam_role" "ebs_csi_irsa" {
  name = "dataops-ebs-csi-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_host}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${local.oidc_host}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Environment = "shared"
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.ebs_csi_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_irsa.arn

  depends_on = [aws_iam_role_policy_attachment.ebs_csi_policy]
}

# --- ingress-nginx (internal) ---

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [yamlencode({
    controller = {
      service = {
        type = "LoadBalancer"
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-internal" = "true"
        }
      }
    }
  })]
}

# --- Monitoring (Prometheus + Alertmanager + Grafana) ---

resource "helm_release" "kube_prometheus_stack" {
  name             = "kps"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  values = [yamlencode({
    grafana = {
      adminPassword = "admin"

      # Auto-provision Loki datasource.
      sidecar = {
        datasources = {
          enabled = true
        }
      }

      additionalDataSources = [
        {
          name      = "Loki"
          type      = "loki"
          access    = "proxy"
          url       = "http://loki.logging.svc.cluster.local:3100"
          isDefault = false
        }
      ]
    }
  })]
}

# --- Loki + Promtail ---

resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  namespace        = "logging"
  create_namespace = true

  # If a previous install attempt left a FAILED release behind, allow Helm to reuse the name.
  replace         = true
  cleanup_on_fail = true

  values = [yamlencode({
    # Disable memcached caches for this small demo cluster (they can request ~10Gi RAM by default).
    chunksCache  = { enabled = false }
    resultsCache = { enabled = false }

    # Demo-friendly: single process + local filesystem storage.
    # SimpleScalable/Distributed require object storage (S3/GCS/etc), which we don't want here.
    deploymentMode = "SingleBinary"

    backend = { replicas = 0 }
    read    = { replicas = 0 }
    write   = { replicas = 0 }

    gateway = {
      enabled = false
    }

    singleBinary = {
      replicas = 1
      persistence = {
        enabled = true
        size    = "10Gi"
      }
    }

    loki = {
      auth_enabled  = false
      useTestSchema = true

      commonConfig = {
        replication_factor = 1
      }

      storage = {
        type = "filesystem"
      }
    }
  })]
}

resource "helm_release" "promtail" {
  name             = "promtail"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "promtail"
  namespace        = "logging"
  create_namespace = true

  values = [yamlencode({
    config = {
      clients = [
        {
          # Loki chart in SingleBinary mode exposes the service as "loki-single-binary".
          url = "http://loki-single-binary.logging.svc.cluster.local:3100/loki/api/v1/push"
        }
      ]
    }
  })]
}
