#===================================================================================================================
# Data
# ==================================================================================================================
variable "webapp_backend_create" {
  type        = bool
  default     = false
  description = "Whether cluster should be created (affects nearly all resources)"
}

variable "component" {
  description = "Please enter a component i-e: terraform, web-app, XYZ"
  type        = string
}

variable "alb_name" {
  type        = string
  default     = ""
  description = "Name of the ALB. If not provided, will use system information(component,region etc.) to generate ALB name."
}

variable "ecs_service_name" {
  type        = string
  default     = ""
  description = "Name of the ECS service."
}

variable "webapp_backend_create_ecr_repo" {
  type        = bool
  default     = false
  description = "Whether ECR repository and relevant resources should be created"
}

variable "private_subnet_ids" {
  type        = list(string)
  default     = []
  description = "IDs of the Private subnets where to create the resources "
}

variable "public_subnet_ids" {
  type        = list(string)
  default     = []
  description = "IDs of the Public subnets where to create the resources "
}

variable "cert_arn_alb" {
  type        = string
  default     = ""
  description = "ARN of the ACM Wildcard DNS Cert"
}

variable "hosted_zone_id" {
  type        = string
  default     = ""
  description = "Hosted zone Id"
}

#===================================================================================================================
# ALB
# ==================================================================================================================
variable "webapp_backend_enable_alb_deletion_protection" {
  type        = bool
  default     = true
  description = "Indicates if ALB deletion protection should be enabled"
}

variable "alb_health_check_path" {
  type        = string
  default     = "/"
  description = "Health check path"
}

variable "alb_health_check_port" {
  type        = string
  default     = "80"
  description = "Health check port"
}
#===================================================================================================================
# ROUTE53
# ==================================================================================================================
variable "webapp_backend_service_aliases" {
  type        = list(string)
  default     = []
  description = "List of aliases e.g. adserver, thoon. This will be concatenated to base_domain_name and final result would be adserver.<base_domain_name>."
}

#===================================================================================================================
# Task Definition
# ==================================================================================================================
variable "webapp_backend_image_uri" {
  type        = string
  description = "ECR image URI"
}

variable "webapp_backend_ecr_repo_encryption_type" {
  type        = string
  default     = "AES256"
  description = "The encryption type to use for the repository. Valid values are `AES256` or `KMS`"
}

# Auto Scaling
variable "webapp_backend_enable_ecs_service_auto_scaling" {
  type        = bool
  default     = false
  description = "Indicates if ECS service auto-scaling is enabled."
}

variable "image_container_port" {
  type        = number
  default     = 80
  description = "Container port"
}

variable "ecs_service_alb_container_port" {
  type        = number
  default     = 80
  description = "Port on the container to associate with the load balancer"
}

variable "use_custom_container_definitions" {
  type        = bool
  default     = false
  description = "Indicates if default container definitions should be ignored and `ecs_task_container_definitions` should be utilized for container definitions."
}

variable "task_definition_arn" {
  type = string
  default = ""
  description = "Please provide the task definition arn if you want to create tasks with specific definition revision"
}

variable "ecs_task_container_definitions" {
  type        = string
  default     = ""
  description = "container definitions in heredoc syntax"
}

variable "ecs_task_role" {
  type        = string
  default     = ""
  description = "ECS task role."
}
variable "ecs_task_role_iam_policy" {
  type        = string
  default     = <<-ECS_TASK_ROLE_IAM_POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
  }
ECS_TASK_ROLE_IAM_POLICY
  description = "ECS task role IAM policy."
}

variable "ecs_execution_role" {
  type        = string
  default     = ""
  description = "ECS execution role."
}
variable "ecs_execution_role_iam_policy" {
  type        = string
  default     = <<-ECS_EXECUTION_ROLE_IAM_POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
  }
ECS_EXECUTION_ROLE_IAM_POLICY
  description = "ECS execution role IAM policy."
}

variable "ecs_cloudwatch_logs_retention_in_days" {
  type        = number
  default     = 14
  description = "ECS cloudwatch logs retention periods"
}
#===================================================================================================================
# SSM Parameter Store
# ==================================================================================================================
variable "create_string_parameters" {
  type        = bool
  default     = false
  description = "whether to enable string parameters support or not"
}

variable "create_string_list_parameters" {
  type        = bool
  default     = false
  description = "whether to enable stringlist parameters support or not"
}

variable "create_secure_string_parameters" {
  type        = bool
  default     = false
  description = "whether to enable  secure string parameters support or not"
}

variable "string_parameters" {
  type = list(object({
    key         = string
    value       = string
    description = string
  }))
  default     = []
  description = "List of parameters to be added as String."
}

variable "string_list_parameters" {
  type = list(object({
    key         = string
    value       = string
    description = string
  }))
  default     = []
  description = "List of parameters to be added as StringList."
}

variable "secure_string_parameters" {
  type = list(object({
    key         = string
    value       = string
    description = string
  }))
  default     = []
  description = "List of parameters to be added as SecureString."
}

variable "enable_kms_encryption_for_aws_cloudwatch_log_group" {
  type        = bool
  default     = false
  description = "whether to enable kms encryption for cloudwatch log group or not"
}

variable "create_secrets" {
  type = bool
  default = false
}
variable secrets {
  type = list(object({
    description =  string
    kms_key_id =  string
    name = string
    recovery_window_in_days = number
    secret_string = string
  }))
  default = []
}

variable "enable_container_insights" {
  type        = bool
  default     = true
  description = "Default container insights are enable for ECS cluster"
}
variable "enable_fargate_capacity_provider" {
  description = "Whether to enable Fargate capacity provider"
  default     = true
  type        = bool
}
variable "enable_fargate_spot_capacity_provider" {
  description = "Whether to enable Fargate Spot capacity provider"
  default     = false
  type        = bool
}

variable "fargate_capacity_provider_base" {
  type        = number
  default     = 1
  description = "capacity provider base"
}

variable "fargate_capacity_provider_weight" {
  type        = number
  default     = 5
  description = "capacity provider weight"
}

variable "fargate_spot_capacity_provider_base" {
  type        = number
  default     = 0
  description = "capacity provider base"
}

variable "fargate_spot_capacity_provider_weight" {
  type        = number
  default     = 20
  description = "capacity provider weight"
}

variable "ecs_service_autoscaling_dimension" {
  type = string
  default = "cpu"
  description = "Dimension for service auto-scaling"
}
variable "desired_count" {
  type        = number
  default     = 1
  description = "Number of instances of the task definition"
}
variable "ecs_service_autoscaling_min_capacity" {
  type        = number
  default     = 1
  description = "The min capacity of the scalable target"
}

variable "ecs_service_autoscaling_max_capacity" {
  type        = number
  default     = 5
  description = "The max capacity of the scalable target"
}

# Scale Up Policy
# CPU
variable "ecs_service_autoscaling_threshold_percentage" {
  type        = number
  default     = 90
  description = "The target value for the metric, in this case cpu/memory i-e: 90"
}

# Cool down Policy
variable "ecs_service_autoscaling_scale_in_cool_down" {
  type        = number
  default     = 300
  description = "The amount of time, in seconds, after a scale in activity completes before another scale in activity can start."
}

variable "ecs_service_autoscaling_scale_out_cool_down" {
  type        = number
  default     = 300
  description = "The amount of time, in seconds, after a scale out activity completes before another scale out activity can start."
}
variable "project_name" {
  type        = string
  default     = ""
}
variable "customer_identifier" {
  type        = string
}
variable "ecs_task_memory_size" {
  type        = number
  default     = 2048
  description = "Amount of memory to allocate to the task."
}

variable "ecs_task_cpu_size" {
  type        = number
  default     = 1024
  description = "Amount of cpu to allocate to the task."
}
