# GitHub OIDC provider + the IAM role Actions assumes (no long-lived AWS keys).
# Applied once by hand with admin credentials; long-lived (not destroyed per run).

# Fetch GitHub's OIDC TLS cert so we don't hardcode a thumbprint.
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# Trust: only this repo, and only the main branch or the 'production' environment.
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_repo}:environment:production",
      ]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = var.deploy_role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

# Permissions: EC2/VPC (the cluster), the state bucket, and the default EBS KMS key
# (instances now use encrypted root volumes).
data "aws_iam_policy_document" "permissions" {
  # A Terraform deploy role that manages the VPC, subnets, SGs and instances needs broad
  # EC2, and KMS for the default EBS key. S3 is already scoped to the state bucket, and no
  # IAM/credential-management actions are granted. Breadth here is intentional and scoped
  # to what this pipeline builds.
  #checkov:skip=CKV_AWS_356:ec2:*/kms on "*" is required to manage account-wide EC2/VPC
  #checkov:skip=CKV_AWS_111:broad write is the deploy role's purpose; S3 scoped to the bucket
  #checkov:skip=CKV_AWS_109:no IAM permission-management actions are granted
  #checkov:skip=CKV_AWS_107:no credential-exposure actions are granted
  statement {
    sid       = "Ec2AndVpc"
    effect    = "Allow"
    actions   = ["ec2:*"]
    resources = ["*"]
  }

  statement {
    sid       = "StateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketVersioning"]
    resources = ["arn:aws:s3:::${var.state_bucket}"]
  }

  statement {
    sid       = "StateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.state_bucket}/*"]
  }

  statement {
    sid       = "EbsDefaultKey"
    effect    = "Allow"
    actions   = ["kms:CreateGrant", "kms:Decrypt", "kms:GenerateDataKeyWithoutPlaintext", "kms:DescribeKey", "kms:ReEncrypt*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "galera-ptp-deploy"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.permissions.json
}
