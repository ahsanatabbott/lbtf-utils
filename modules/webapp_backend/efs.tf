//provider "aws" {
//  version = "3.21.0"
//}

variable "mp_efs_enable_encryption" {
  type = bool
  default = true
}
variable "mp_efs_kms_key_id" {
  type = string
}
variable "mp_efs_performance_mode" {
  type = string
  default = "generalPurpose"
}
# variable "mp_efs_provisioned_throughput_in_mibps" {
#   type = string
# }
variable "mp_efs_throughput_mode" {
  type = string
  default = "bursting"
}
variable "mp_efs_enabled" {
  type = bool
  default = true
}
resource "aws_efs_file_system" "mesmer_pod" {
  count = local.create && var.mp_efs_enabled ? 1 : 0

  encrypted = var.mp_efs_enable_encryption
  kms_key_id = var.mp_efs_kms_key_id
  performance_mode = var.mp_efs_performance_mode
  //  provisioned_throughput_in_mibps = var.mp_efs_provisioned_throughput_in_mibps
  throughput_mode = var.mp_efs_throughput_mode
  tags = merge(local.tags, {
    Name = "${local.project_name}-${local.component}"
  })

}


//========================================================================
//EFS File System Policy
//========================================================================

resource "aws_efs_file_system_policy" "mesmer_pod" {
  count = local.create && var.mp_efs_enabled ? 1 : 0
  file_system_id = aws_efs_file_system.mesmer_pod[0].id
  policy = data.template_file.mesmer_pod[0].rendered
}

data "template_file" "mesmer_pod" {
  count = local.create && var.mp_efs_enabled ? 1 : 0
  template = file("${path.module}/templates/efs/efs-policy.tftpl")
  vars = {
    mp_efs_account_id = local.aws_account_id
    mp_efs_region = local.aws_region
    mp_efs_access_point_id = aws_efs_access_point.mesmer_pod[0].id
    mp_efs_file_system_arn = aws_efs_file_system.mesmer_pod[0].arn
    mp_efs_ecs_role_arn = var.ecs_task_role
  }
}

resource "aws_efs_access_point" "mesmer_pod" {
  count = local.create && var.mp_efs_enabled ? 1 : 0
  file_system_id = aws_efs_file_system.mesmer_pod[0].id
  root_directory {
    path = "/${local.env}-${local.customer_identifier}-${local.component}"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "0777"
    }
  }
}

resource "aws_efs_mount_target" "mesmer_pod" {
  count = local.create && var.mp_efs_enabled ? length(var.private_subnet_ids) : 0
  file_system_id = aws_efs_file_system.mesmer_pod[0].id
#   subnet_id = element(tolist(data.aws_subnet_ids.private-subnet-ids.ids), count.index)
  subnet_id = var.private_subnet_ids[count.index]
  security_groups = [ aws_security_group.ecs_sg[0].id ]
}
