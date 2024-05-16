locals {
  project_name = "frq-dv-brandcheck-202300003"
  kms_key_arn = "arn:aws:kms:us-east-1:851725235588:key/67dec56e-b486-4c69-b754-fdc232485d81"
  base_domain_name = "dev.frequencyads.com"
  stage = "nonprod"
  vpc_id = "vpc-01e56c3b8a922b93b"
  vpc_cidr = "172.24.32.0/21"
  private_subnet_ids = [ "subnet-005a2b364399a657f",  "subnet-034bdcf031f9e015c"]
  public_subnet_ids = [ "subnet-04af5a86c962265c6", "subnet-01cc8fc88c0c65096" ]
  cert_arn_alb =  "arn:aws:acm:us-east-1:851725235588:certificate/11393067-c024-495f-ad88-1a0daceab52a"
  hosted_zone_id =  "Z04372652ALFC91L0GGKK"
  aws_region = "us-east-1"
  aws_account_id = "851725235588"
  alb_access_logs_s3_bucket_name = ""
  alb_name = "brandcheck-lbstudio"
  ecs_execution_role = var.ecs_execution_role
  ecs_task_role = var.ecs_task_role
  customer_identifier = var.customer_identifier
}
module "webapp_backend" {
  source  = "./modules/webapp_backend"

  # insert required variables here
  create          = var.webapp_backend_create
  create_ecr_repo = var.webapp_backend_create_ecr_repo

  alb_name         = local.alb_name
  ecs_service_name = var.ecs_service_name

  #=================================
  # Core
  #=================================
  environment         = local.stage
  customer_identifier = local.customer_identifier
  region              = local.aws_region
  component           = var.component
  tags                = merge({
    ProjectName = local.project_name
    Stage = local.stage
  })

  base_domain_name = local.base_domain_name

  kms_key = local.kms_key_arn

  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids
  public_subnet_ids  = local.public_subnet_ids

  cert_arn_alb   = local.cert_arn_alb
  hosted_zone_id = local.hosted_zone_id

  service_aliases = var.webapp_backend_service_aliases

  enable_ecs_service_auto_scaling = var.webapp_backend_enable_ecs_service_auto_scaling

  desired_count = var.desired_count
  ecs_service_autoscaling_min_capacity = var.ecs_service_autoscaling_min_capacity
  ecs_service_autoscaling_max_capacity = var.ecs_service_autoscaling_max_capacity
  ecs_service_autoscaling_scale_in_cool_down = var.ecs_service_autoscaling_scale_in_cool_down
  ecs_service_autoscaling_scale_out_cool_down = var.ecs_service_autoscaling_scale_out_cool_down
  ecs_service_autoscaling_threshold_percentage = var.ecs_service_autoscaling_threshold_percentage

  ecs_service_autoscaling_dimension = var.ecs_service_autoscaling_dimension

  image_uri                      = var.webapp_backend_image_uri
  image_container_port           = var.image_container_port
  ecs_service_alb_container_port = var.ecs_service_alb_container_port
  alb_health_check_path          = var.alb_health_check_path
  alb_health_check_port          = var.alb_health_check_port

  enable_container_insights = var.enable_container_insights

  ecr_repo_encryption_type = var.webapp_backend_ecr_repo_encryption_type

  enable_alb_deletion_protection = var.webapp_backend_enable_alb_deletion_protection

  use_custom_container_definitions = var.use_custom_container_definitions

  task_definition_arn = var.task_definition_arn

  enable_fargate_capacity_provider = var.enable_fargate_capacity_provider
  enable_fargate_spot_capacity_provider = var.enable_fargate_spot_capacity_provider

  fargate_capacity_provider_weight = var.fargate_capacity_provider_weight
  fargate_capacity_provider_base = var.fargate_capacity_provider_base

  fargate_spot_capacity_provider_weight = var.fargate_spot_capacity_provider_weight
  fargate_spot_capacity_provider_base = var.fargate_spot_capacity_provider_base
  #FIXME: remove hardcoded value
  enable_execute_command = true

  ecs_task_container_definitions   = "[ ${templatefile("${path.module}/primary-container-definition.tftpl",{
    stage = local.stage
    app_port = var.image_container_port
    project_name = local.project_name
    component = var.component
    customer_id = local.customer_identifier
    aws_region = local.aws_region
    aws_account_id = local.aws_account_id })} ]"

  account_id = local.aws_account_id


  ecs_execution_role            = local.ecs_execution_role
  ecs_execution_role_iam_policy = var.ecs_execution_role_iam_policy
  ecs_task_role                 = local.ecs_task_role
  ecs_task_role_iam_policy      = var.ecs_task_role_iam_policy

  # ================ SSM PARAMETER STORE ================
  create_string_parameters        = var.create_string_parameters
  string_parameters               = var.string_parameters
  create_string_list_parameters   = var.create_string_list_parameters
  string_list_parameters          = var.string_list_parameters
  create_secure_string_parameters = var.create_secure_string_parameters
  secure_string_parameters        = var.secure_string_parameters
  kms_key_id_for_secure_string    = local.kms_key_arn

  # ================ Secrets Manager ================
  create_secrets = var.create_secrets
  secrets        = var.secrets


  alb_access_logs_s3_bucket_name = local.alb_access_logs_s3_bucket_name

  project_name = local.project_name
  vpc_cidr = local.vpc_cidr
  mp_efs_kms_key_id = local.kms_key_arn

  ecs_task_memory_size = var.ecs_task_memory_size
  ecs_task_cpu_size = var.ecs_task_cpu_size

  depends_on = [aws_cloudwatch_log_group.aws_cloudwatch_log_group]
}

resource "aws_cloudwatch_log_group" "aws_cloudwatch_log_group" {
  count             = var.webapp_backend_create && var.use_custom_container_definitions ? 1 : 0
  name              = "/ecs/${local.project_name}-${var.component}"
  retention_in_days = var.ecs_cloudwatch_logs_retention_in_days
#   kms_key_id        = local.kms_key_arn
}
