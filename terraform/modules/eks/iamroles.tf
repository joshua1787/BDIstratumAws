# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Starting from Kubernetes version 1.23, AmazonEKSVPCResourceController is also recommended for the cluster role
# to manage ENIs for services of type LoadBalancer and for other networking resources.
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController" # For EKS to manage ENIs in your VPC
  role       = aws_iam_role.eks_cluster_role.name
}


# IAM Role for EKS Worker Nodes
resource "aws_iam_role" "eks_nodes_role" {
  name = "${var.project_name}-${var.environment}-eks-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-nodes-role"
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" # To pull images from ECR
  role       = aws_iam_role.eks_nodes_role.name
}

# AmazonEKS_CNI_Policy is required for the AWS VPC CNI plugin (networking for pods)
resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes_role.name
}

# --- IAM Role for backend Service Account (IRSA) ---
resource "aws_iam_role" "backend_service_account_role" {
  name_prefix = "${var.project_name}-${var.environment}-backend-sa-role-"
  description = "IAM role for backend Kubernetes Service Account to access AWS resources."

  # The trust policy allowing EKS to assume this role for a service account
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # IMPORTANT: Replace 'stratum-ns' with your actual Kubernetes namespace if different
            # IMPORTANT: Replace 'stratum-backend-sa' with your actual Service Account name if different
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:stratum-ns:stratum-backend-sa"
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-backend-sa-role"
  })
}

# --- IAM Policy for Secrets Manager Read Access ---
resource "aws_iam_policy" "backend_secrets_manager_policy" {
  name        = "${var.project_name}-${var.environment}-backend-secrets-policy"
  description = "Allows backend service account to read RDS credentials from Secrets Manager."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = var.db_credentials_secret_arn # Allow access only to the specific secret ARN
      },
      # Add other permissions here if your backend needs to access other AWS services
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-backend-secrets-policy"
  })
}

# --- Attach the policy to the role ---
resource "aws_iam_role_policy_attachment" "backend_sa_secrets_policy_attach" {
  role       = aws_iam_role.backend_service_account_role.name
  policy_arn = aws_iam_policy.backend_secrets_manager_policy.arn
}

# --- Data source to get current AWS account ID for OIDC provider ---
data "aws_caller_identity" "current" {}

# --- IAM Role for AWS Load Balancer Controller Service Account ---
resource "aws_iam_role" "aws_lb_controller_role" {
  name_prefix = "${var.project_name}-${var.environment}-aws-lb-controller-role-"
  description = "IAM role for AWS Load Balancer Controller Kubernetes Service Account."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # IMPORTANT: The namespace must match where you deploy the controller (usually kube-system)
            # IMPORTANT: The service account name for the controller is 'aws-load-balancer-controller'
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-aws-lb-controller-role"
  })
}

# --- AWS Load Balancer Controller IAM Policy ---
# This policy is quite extensive and typically comes from AWS documentation.
# We will embed it directly as a managed policy or create it here.
# For simplicity and adherence to AWS docs, let's define it directly.
# https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller-getting-started.html
# Step 4: Create the IAM policy
resource "aws_iam_policy" "aws_lb_controller_policy" {
  name        = "${var.project_name}-${var.environment}-aws-lb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller to manage ALBs."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:DescribeAvailabilityZones",
          "ec2:ModifyInstanceAttribute",
          "ec2:ReportInstanceStatus",
          "ec2:UnmonitorInstances",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:AttachVolume",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeKeyPairs",
          "ec2:RunInstances",
          "ec2:MonitorInstances",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup",
          "ec2:CreateSecurityGroup",
          "ec2:DescribeSecurityGroupRules",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:SetWebACL",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:SetLbAsSecurityGroupSource",
          "elasticloadbalancing:SetRulePriorities",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:CreateListenerCertificate",
          "elasticloadbalancing:DeleteListenerCertificate",
          "elasticloadbalancing:SetStatus",
          "elasticloadbalancing:SetType",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:DescribeAccountLimits",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:ModifyListenerCertificates",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeTargetHealth"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "tag:GetResources",
          "tag:TagResources",
          "waf:GetWebACL",
          "waf:GetWebACLForResource",
          "waf:AssociateWebACL",
          "waf:DisassociateWebACL",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL"
        ],
        Resource = "*"
      }
    ]
  })
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-aws-lb-controller-policy"
  })
}

# --- Attach the policy to the Load Balancer Controller role ---
resource "aws_iam_role_policy_attachment" "aws_lb_controller_policy_attach" {
  role       = aws_iam_role.aws_lb_controller_role.name
  policy_arn = aws_iam_policy.aws_lb_controller_poli