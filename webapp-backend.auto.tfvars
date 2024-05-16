webapp_backend_create          = true
webapp_backend_create_ecr_repo = false
customer_identifier = "brandcheck"
component                      = "labelstudio"
image_container_port           = 8080
ecs_service_alb_container_port = 8080
alb_health_check_port          = 8080
enable_container_insights = false



ecs_execution_role = "arn:aws:iam::851725235588:role/frequencyads-dev-nginx-execution-role"
ecs_task_role = "arn:aws:iam::851725235588:role/frequencyads-dev-nginx-task-role"


##Route53
webapp_backend_service_aliases = ["labelstudio"]
#enable_fargate_spot = true

##ECS Service
webapp_backend_enable_ecs_service_auto_scaling = false
#webapp_backend_use_cpu_for_scaling             = true
webapp_backend_image_uri = ""

##ALB
webapp_backend_enable_alb_deletion_protection = false
alb_health_check_path = "/user/login"


#ECR
webapp_backend_ecr_repo_encryption_type = "KMS"
use_custom_container_definitions = true

# ================ SSM PARAMETER STORE ================
create_string_parameters = false
string_parameters        = [
]

create_string_list_parameters = false
string_list_parameters        = [
]
create_secure_string_parameters = false
secure_string_parameters = []

# ================ KMS encryption ================
enable_kms_encryption_for_aws_cloudwatch_log_group = false

# ================ Secrets Manager ================
create_secrets = false

#======================== ONLY SPOT =================================
desired_count = 1

#capacity provider settings
enable_fargate_capacity_provider      = true
enable_fargate_spot_capacity_provider = false

fargate_capacity_provider_base   = 1
fargate_capacity_provider_weight = 1

fargate_spot_capacity_provider_base   = 0
fargate_spot_capacity_provider_weight = 1

ecs_service_autoscaling_dimension = "alb"
ecs_service_autoscaling_min_capacity         = 1
ecs_service_autoscaling_max_capacity         = 14
ecs_service_autoscaling_scale_in_cool_down   = 300
ecs_service_autoscaling_scale_out_cool_down  = 300
ecs_service_autoscaling_threshold_percentage = 1
ecs_task_memory_size = 16384
ecs_task_cpu_size = 4096