locals {
  cluster_name     = var.eks_cluster_name == "" ? "${var.project_name}-${var.environment}-eks-cluster" : var.eks_cluster_name
  node_group_name  = var.eks_node_group_name == "" ? "${var.project_name}-${var.environment}-ng" : var.eks_node_group_name
}

# Security Group for EKS Worker Nodes
resource "aws_security_group" "eks_nodes_sg" {
  name        = "${local.cluster_name}-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rules will be added by EKS for cluster communication.
  # We might add more specific rules later (e.g., for node port services if needed from a load balancer)

  tags = merge(var.common_tags, {
    Name = "${local.cluster_name}-nodes-sg"
  })
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn # From iam_roles.tf
  version  = var.eks_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids # Deploy control plane ENIs and nodes in private subnets
    endpoint_private_access = var.eks_cluster_endpoint_private_access
    endpoint_public_access  = var.eks_cluster_endpoint_public_access
    public_access_cidrs     = var.eks_cluster_endpoint_public_access_cidrs
    # Explicitly assign the worker node SG to the cluster as well. EKS also creates its own cluster SG.
    # This helps in defining rules between control plane and nodes if needed.
    # Alternatively, you can let EKS create its own cluster SG and then use that.
    # For simplicity and control over the worker nodes' primary SG:
    security_group_ids = [aws_security_group.eks_nodes_sg.id]
  }

  tags = merge(var.common_tags, {
    Name = local.cluster_name
  })

  # Ensure IAM Role is created before cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController,
  ]
}

# EKS Managed Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = local.node_group_name
  node_role_arn   = aws_iam_role.eks_nodes_role.arn # From iam_roles.tf
  subnet_ids      = var.private_subnet_ids        # Nodes will be in private subnets

  instance_types = var.eks_node_instance_types
  capacity_type  = "ON_DEMAND" # Or SPOT

  scaling_config {
    desired_size = var.eks_node_desired_size
    min_size     = var.eks_node_min_size
    max_size     = var.eks_node_max_size
  }

  # Associate with the security group we created for the nodes.
  # If not specified, EKS creates one. By specifying, we have its ID.
  # Note: EKS managed node groups will also automatically be part of the cluster's primary security group.
  # The `vpc_security_group_ids` argument here is for additional SGs.
  # The primary SG for node group communication is often handled by EKS or implicitly.
  # For worker nodes, the SG defined in `aws_eks_cluster.vpc_config.security_group_ids` or the one we created (`aws_security_group.eks_nodes_sg.id`)
  # should be what we use for RDS access. Let's ensure our created SG is effectively used by the nodes.
  # By adding our SG to the cluster's vpc_config, nodes launched will implicitly use it,
  # or EKS will ensure communication paths.
  # The node group itself doesn't directly take a list of security_group_ids to attach to ENIs in the same way EC2 instances do.
  # It relies on the cluster's security group and possibly launch templates for SG customization.
  # The `aws_security_group.eks_nodes_sg` that we created is intended for the worker nodes.
  # We've associated it at the cluster level's vpc_config. This SG will be used by the control plane ENIs.
  # Worker nodes will communicate via this SG or the main cluster SG EKS creates.
  # Let's ensure we output the correct SG for RDS: `aws_security_group.eks_nodes_sg.id`.

  update_config {
    max_unavailable = 1 # Or max_unavailable_percentage
  }

  tags = merge(var.common_tags, {
    Name                                             = local.node_group_name
    "eks:cluster-name"                               = local.cluster_name # Recommended tag
    "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"          # For cluster autoscaler
    "k8s.io/cluster-autoscaler/enabled"              = "true"             # For cluster autoscaler
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKS_CNI_Policy,
    aws_eks_cluster.main,
  ]
}