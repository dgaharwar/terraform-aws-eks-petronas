resource "aws_iam_role" "eks_cluster_role" {
  count = var.use_existing_role ? 0 : 1

  name = var.new_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy_attachment" {
  count      = var.use_existing_role ? 0 : 1
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = data.aws_iam_policy.existing_iam_policy.arn
}

data "aws_iam_policy" "existing_iam_policy" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
