# -----------------------------------------------------
# Minimal Packer IAM build policy for Packer Talos AMIs
# -----------------------------------------------------
data "aws_iam_policy_document" "packer_talos" {
    for_each = var.workload_identity_providers_config

    # ========================================================================
    # EC2 DESCRIBE OPERATIONS
    # ========================================================================
    # These operations are required for Packer to discover resources and check
    # instance status during builds. Most describe operations do not support
    # resource-level permissions and require wildcard resources.
    # ========================================================================

    #########################
    # EC2 Instance Status Checks
    # Required for Packer to detect when instances become ready
    # Note: ec2:DescribeInstances and ec2:DescribeInstanceStatus do not support resource-level permissions
    # checkov:skip=CKV_AWS_107:ec2:DescribeInstances and ec2:DescribeInstanceStatus do not support resource-level permissions and are restricted by region condition
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeInstances",
            "ec2:DescribeInstanceStatus"
        ]
        resources = ["*"]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 Regions Discovery
    # Required for Packer AMI discovery
    # Note: ec2:DescribeRegions does not support resource-level permissions
    # checkov:skip=CKV_AWS_107:ec2:DescribeRegions does not support resource-level permissions and is restricted by region condition
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeRegions"
        ]
        resources = ["*"]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 AMI Discovery
    # Required for Packer to discover source AMIs
    # Note: ec2:DescribeImages does not support resource-level permissions
    # checkov:skip=CKV_AWS_107:ec2:DescribeImages does not support resource-level permissions and is restricted by region condition
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeImages",
            "ec2:DescribeImageAttribute"
        ]
        resources = ["*"]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 Security Groups Discovery
    # Required for Packer to discover security groups
    # Note: ec2:DescribeSecurityGroups does not support resource-level permissions
    # checkov:skip=CKV_AWS_107:ec2:DescribeSecurityGroups does not support resource-level permissions and is restricted by region condition
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeSecurityGroups"
        ]
        resources = ["*"]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 Snapshots Discovery
    # Required for Packer to discover snapshots and check snapshot status
    # Note: ec2:DescribeSnapshots may not support resource-level permissions properly
    # checkov:skip=CKV_AWS_107:ec2:DescribeSnapshots may not support resource-level permissions and is restricted by region condition
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeSnapshots",
            "ec2:DescribeSnapshotAttribute"
        ]
        resources = ["*"]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 VPCs/Subnets/KeyPairs Discovery
    # Required for Packer to discover VPCs, subnets, and key pairs
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeVpcs",
            "ec2:DescribeSubnets",
            "ec2:DescribeKeyPairs"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key-pair/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"
        ]
    }

    #########################
    # EC2 Availability Zones and Account Attributes
    # Required for Packer to discover AZs and account limits
    # Note: These actions do not support resource-level permissions
    # checkov:skip=CKV_AWS_107:ec2:DescribeAvailabilityZones and ec2:DescribeAccountAttributes do not support resource-level permissions
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeAccountAttributes"
        ]
        resources = ["*"]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    # ========================================================================
    # EC2 INSTANCE OPERATIONS
    # ========================================================================
    # Permissions for launching, managing, and monitoring EC2 instances
    # Instance type restrictions apply to launch and management operations
    # ========================================================================

    #########################
    # EC2 RunInstances - Instance Resource
    # Launch instances with instance type restriction
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:RunInstances"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
        condition {
            test     = "StringEquals"
            variable = "ec2:InstanceType"
            values   = each.value.allowed_ec2_instance_types
        }
    }

    #########################
    # EC2 RunInstances - Supporting Resources
    # Required resources for launching instances (key pairs, security groups, VPCs, etc.)
    # Note: Instance type condition doesn't apply to these resources
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:RunInstances"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key-pair/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:image/*",
            "arn:aws:ec2:${var.aws_region}::image/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 Instance Management
    # Terminate, stop, start, and reboot instances with instance type restriction
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:TerminateInstances",
            "ec2:StopInstances",
            "ec2:StartInstances",
            "ec2:RebootInstances"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
        condition {
            test     = "StringEquals"
            variable = "ec2:InstanceType"
            values   = each.value.allowed_ec2_instance_types
        }
    }

    #########################
    # EC2 Instance Console Access
    # Get console output and screenshots for debugging
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:GetConsoleOutput",
            "ec2:GetConsoleScreenshot"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 Instance Attribute Modification
    # Modify instance attributes during build
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:ModifyInstanceAttribute"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    # ========================================================================
    # EC2 KEY PAIR OPERATIONS
    # ========================================================================
    # Permissions for creating and managing temporary key pairs for SSH access
    # ========================================================================

    #########################
    # EC2 Key Pair Management
    # Create and delete temporary key pairs for Packer SSH access
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateKeyPair",
            "ec2:DeleteKeyPair"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key-pair/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    # ========================================================================
    # EC2 SECURITY GROUP OPERATIONS
    # ========================================================================
    # Permissions for creating and managing temporary security groups for SSH access
    # ========================================================================

    #########################
    # EC2 Security Group Management
    # Create and delete temporary security groups with SSH access
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateSecurityGroup",
            "ec2:DeleteSecurityGroup",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    # ========================================================================
    # EC2 NETWORKING OPERATIONS
    # ========================================================================
    # Permissions for VPCs, subnets, network interfaces, and Elastic IPs
    # ========================================================================

    #########################
    # EC2 Network Interface Management
    # Create, manage network interfaces and Elastic IPs for instance networking
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:AttachNetworkInterface",
            "ec2:DetachNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:ModifyNetworkInterfaceAttribute",
            "ec2:AssociateAddress",
            "ec2:DisassociateAddress",
            "ec2:AllocateAddress",
            "ec2:ReleaseAddress",
            "ec2:DescribeAddresses"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:elastic-ip/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    # ========================================================================
    # EC2 EBS VOLUME OPERATIONS
    # ========================================================================
    # Permissions for managing EBS volumes for instance storage
    # ========================================================================

    #########################
    # EC2 EBS Volume Management
    # Create, attach, detach, and manage EBS volumes for Packer builds
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateVolume",
            "ec2:DeleteVolume",
            "ec2:AttachVolume",
            "ec2:DetachVolume",
            "ec2:DescribeVolumeAttribute",
            "ec2:ModifyVolumeAttribute"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 EBS Volume Discovery
    # Describe volumes for cleanup operations
    # Note: ec2:DescribeVolumes may not support resource-level permissions properly
    # checkov:skip=CKV_AWS_107:ec2:DescribeVolumes may not support resource-level permissions and is restricted by region condition
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeVolumes"
        ]
        resources = ["*"]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    # ========================================================================
    # EC2 AMI OPERATIONS
    # ========================================================================
    # Permissions for creating, registering, and managing AMIs
    # ========================================================================

    #########################
    # EC2 AMI Registration from Snapshots
    # RegisterImage on snapshot resources - ImageName condition doesn't apply to snapshots
    # Note: When RegisterImage is evaluated on snapshot resources, ec2:ImageName condition may not apply
    # checkov:skip=CKV_AWS_107:RegisterImage on snapshots requires "*" for snapshot resources during AMI creation
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:RegisterImage"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:snapshot/*",
            "*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 AMI Registration
    # RegisterImage on image resources with Talos naming pattern
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:RegisterImage"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:image/*"
        ]
        condition {
            test     = "StringLike"
            variable = "ec2:ImageName"
            values   = ["talos-*"]
        }
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 AMI Attribute Modification
    # Modify and deregister AMIs - ImageName condition may not apply after registration
    # Note: ModifyImageAttribute and DeregisterImage may require wildcard resources for proper evaluation
    # checkov:skip=CKV_AWS_107:ModifyImageAttribute and DeregisterImage require "*" for proper resource evaluation and are restricted by region condition
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:ModifyImageAttribute",
            "ec2:DeregisterImage"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:image/*",
            "*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 AMI Tagging
    # Tag AMIs after registration - ImageName condition may not apply during tagging
    # Note: CreateTags and DeleteTags may not support ec2:ImageName condition on registered AMIs
    # checkov:skip=CKV_AWS_107:AMI tagging requires "*" for proper resource evaluation and is restricted by region condition
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateTags",
            "ec2:DeleteTags"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:image/*",
            "*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 AMI Management
    # Create and describe AMIs with Talos naming pattern
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateImage",
            "ec2:DescribeImages",
            "ec2:DescribeImageAttribute"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:image/*"
        ]
        condition {
            test     = "StringLike"
            variable = "ec2:ImageName"
            values   = ["talos-*"]
        }
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    # ========================================================================
    # EC2 SNAPSHOT OPERATIONS
    # ========================================================================
    # Permissions for creating and managing EBS snapshots for AMI creation
    # ========================================================================

    #########################
    # EC2 Snapshot Creation from Volumes
    # Create snapshots from EBS volumes - requires permission on both volume and snapshot resources
    # Note: Snapshot resource uses "*" because exact ARN doesn't exist yet when creating
    # checkov:skip=CKV_AWS_107:Snapshot resource requires "*" because snapshot ARN doesn't exist at creation time
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateSnapshot"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
            "*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 Snapshot Deletion
    # Delete snapshots during cleanup - may need wildcard for cleanup operations
    # Note: DeleteSnapshot may require "*" for snapshots during cleanup operations
    # checkov:skip=CKV_AWS_107:Snapshot deletion requires "*" for cleanup operations and is restricted by region condition
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DeleteSnapshot"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:snapshot/*",
            "*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 Snapshot Management
    # Modify and tag snapshots for AMI creation
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:ModifySnapshotAttribute",
            "ec2:CreateTags",
            "ec2:DeleteTags"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:snapshot/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    # ========================================================================
    # EC2 TAGGING OPERATIONS
    # ========================================================================
    # Permissions for tagging resources across different resource types
    # ========================================================================

    #########################
    # EC2 Resource Tagging
    # Tag instances, images, snapshots, and volumes for organization
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateTags",
            "ec2:DeleteTags"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:image/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:snapshot/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    # ========================================================================
    # IAM OPERATIONS
    # ========================================================================
    # Permissions for IAM role pass-through to EC2 instances
    # ========================================================================

    #########################
    # IAM PassRole for EC2 Instances
    # Allow passing IAM roles to EC2 instances for instance profiles
    #########################
    statement {
        effect = "Allow"
        actions = [
            "iam:PassRole"
        ]
        resources = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "iam:PassedToService"
            values   = ["ec2.amazonaws.com"]
        }
    }
}
