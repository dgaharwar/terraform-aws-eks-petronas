#---------------------------------------------------
# AWS EKS cluster
#---------------------------------------------------

resource "aws_eks_cluster" "eks_cluster" {
  count = var.cluster_enable ? 1 : 0

  name     = var.cluster_name
  //role_arn = var.cluster_role_arn
   role_arn = var.use_existing_role ? var.existing_cluster_role_arn : aws_iam_role.eks_cluster_role[0].arn

  vpc_config {
    subnet_ids              = [var.subnet_id1, var.subnet_id2] #var.subnet_ids
    security_group_ids      = [var.security_group_id]

  }

  enabled_cluster_log_types = var.cluster_enabled_cluster_log_types
  version                   = var.cluster_version

  dynamic "encryption_config" {
    iterator = encryption_config
    for_each = var.cluster_encryption_config

    content {
      resources = lookup(encryption_config.value, "resources", null)

      dynamic "provider" {
        iterator = provider
        for_each = length(keys(lookup(encryption_config.value, "provider", {}))) > 0 ? [lookup(encryption_config.value, "provider", {})] : []

        content {
          key_arn = lookup(provider.value, "key_arn", null)
        }
      }
    }
  }

  // Blocks of type "kubernetes_network_config" are not expected here.
  // dynamic "kubernetes_network_config" {
  //   iterator = kubernetes_network_config
  //   for_each = var.cluster_kubernetes_network_config
  //   content {
  //     service_ipv4_cidr = lookup(kubernetes_network_config.value, "service_ipv4_cidr", null)
  //   }
  // }

  dynamic "timeouts" {
    iterator = timeouts
    for_each = length(keys(var.cluster_timeouts)) > 0 ? [var.cluster_timeouts] : []

    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }

  tags = merge({ Name = var.cluster_name }, var.tags )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [aws_iam_role.eks_cluster_role]
}
