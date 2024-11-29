#---------------------------------------------------
# Create EKS Node Group Role ARN
#---------------------------------------------------

# Create a new EKS node group role if the user chooses not to use an existing role
resource "aws_iam_role" "eks_node_group_role" {
  count = var.use_existing_role ? 0 : 1

  name = "${var.new_role_name}-nodeGroup"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [
          "eks.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_group_role_policy_attachment" {
  count      = var.use_existing_role ? 0 : 1
  role       = aws_iam_role.eks_node_group_role[0].name
  policy_arn = data.aws_iam_policy.existing_iam_policy.arn
}

#---------------------------------------------------
# AWS EKS node group
#---------------------------------------------------
resource "aws_eks_node_group" "eks_node_group" {
  count = var.node_group_enable ? 1 : 0

  // cluster_name    = var.node_group_cluster_name
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  // node_role_arn   = var.node_group_role_arn
  node_role_arn   = var.use_existing_role ? var.existing_node_group_role_arn : aws_iam_role.eks_node_group_role[0].arn
  //subnet_ids      = var.node_group_subnet_ids
  subnet_ids = [var.node_group_subnet_id_1, var.node_group_subnet_id_2]

  
  scaling_config {
    max_size     = var.node_group_max_size
    desired_size = var.node_group_desired_size
    min_size     = var.node_group_min_size
  }
  

  ami_type = var.node_group_ami_type
  // capacity_type        = var.node_group_capacity_type
  disk_size            = var.node_group_disk_size
  force_update_version = var.node_group_force_update_version
  instance_types       = [var.node_group_instance_types]
  labels               = var.node_group_labels
  release_version      = var.node_group_release_version
  version              = var.node_group_version

  dynamic "remote_access" {
    iterator = remote_access
    for_each = var.node_group_remote_access

    content {
      ec2_ssh_key               = lookup(remote_access.value, "ec2_ssh_key", null)
      source_security_group_ids = lookup(remote_access.value, "source_security_group_ids", null)
    }
  }

  dynamic "launch_template" {
    iterator = launch_template
    for_each = var.node_group_launch_template

    content {
      id      = lookup(launch_template.value, "id", null)
      name    = lookup(launch_template.value, "name", null)
      version = lookup(launch_template.value, "version", null)
    }
  }

  dynamic "timeouts" {
    iterator = timeouts
    for_each = length(keys(var.node_group_timeouts)) > 0 ? [var.node_group_timeouts] : []

    content {
      create = lookup(timeouts.value, "create", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }

  tags = merge({ Name = var.node_group_name }, var.tags )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}
