#===================================================================================================================
# Locals
# ==================================================================================================================
locals {
  create              = var.create
  region              = var.region
  env                 = var.environment
  customer_identifier = var.customer_identifier
  component           = var.component
  aws_region = var.region
  aws_account_id = var.account_id
  vpc_cidr = var.vpc_cidr
  project_name = var.project_name
  ecs_cluster_name = "${local.project_name}-${local.component}"

#   ecr_repo_policy                 = replace(var.ecr_repo_policy, "444455556666", data.aws_caller_identity.current.account_id)
  ecs_task_log_group              = "/ecs/${local.env}-${local.customer_identifier}-${local.component}"
  ecs_task_primary_container_name = var.ecs_task_primary_container_name == "" ? local.component : var.ecs_task_primary_container_name
  ecr_repo_name                   = var.ecr_repo_name == "" ? "${local.env}-${local.customer_identifier}-${local.component}/default" : var.ecr_repo_name
  tags = var.tags
}
#===================================================================================================================
# ALB
# ==================================================================================================================
#FIXME
# Replace with SG community plugin
#ALB-SG
resource "aws_security_group" "alb_sg" {
  count       = local.create ? 1 : 0
  name        = "${var.project_name}-${local.component}-alb"
  description = "${var.project_name}-${local.component}-alb"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

#SG-rule
resource "aws_security_group_rule" "egress" {
  count     = local.create ? 1 : 0
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  #tfsec:ignore:aws-vpc-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All egress traffic allowed"
  security_group_id = aws_security_group.alb_sg[count.index].id
}

#SG-rule
resource "aws_security_group_rule" "http_tcp" {
  count     = local.create && var.enable_http_to_https_redirection ? 1 : 0
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  #tfsec:ignore:aws-vpc-no-public-ingress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow tcp traffic on port 80"
  security_group_id = aws_security_group.alb_sg[count.index].id
}

resource "aws_security_group_rule" "https_tcp" {
  count     = local.create ? 1 : 0
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  #tfsec:ignore:aws-vpc-no-public-ingress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow tcp traffic on port 443"
  security_group_id = aws_security_group.alb_sg[count.index].id
}

#ALB
resource "aws_lb" "alb" {
  count = local.create ? 1 : 0
  name  = var.alb_name
  #tfsec:ignore:aws-elb-alb-not-public
  internal                   = false
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  security_groups            = [aws_security_group.alb_sg[count.index].id]
  subnets                    = split(",", join(",", var.public_subnet_ids))
  enable_deletion_protection = var.enable_alb_deletion_protection
  tags                       = local.tags

  access_logs {
    enabled = false
    bucket  = var.alb_access_logs_s3_bucket_name
    prefix  = var.alb_access_logs_s3_bucket_object_prefix
  }
}

# HTTP Listener
resource "aws_alb_listener" "http_alb_listener" {
  count             = local.create && var.enable_http_to_https_redirection ? 1 : 0
  load_balancer_arn = aws_lb.alb[count.index].arn
  port              = 80
  #tfsec:ignore:aws-elb-http-not-used
  protocol = "HTTP"
  tags     = local.tags

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Bad request"
      status_code  = "400"
    }
  }
}

# HTTPS Listener
resource "aws_alb_listener" "https_alb_listener" {
  count             = local.create ? 1 : 0
  load_balancer_arn = aws_lb.alb[count.index].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.cert_arn_alb
  tags              = local.tags

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Bad request"
      status_code  = "400"
    }
  }
}

# The HTTP listener rule
resource "aws_lb_listener_rule" "http" {

  count        = local.create && var.enable_http_to_https_redirection ? 0 : (length(aws_alb_listener.http_alb_listener) > 0 && length(aws_lb_target_group.ecs_tg) > 0 ? 1 : 0)
  listener_arn = aws_alb_listener.http_alb_listener[count.index].arn
  priority     = 10
  depends_on   = [aws_lb_target_group.ecs_tg]
  tags         = local.tags

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg[count.index].arn
  }

  condition {
    host_header {
      values = [aws_route53_record.route53_record[0].fqdn]
    }
  }

  #FIXME - Verify if this is required?
  lifecycle {
    ignore_changes = [priority]
  }
}

# The HTTPS listener rule
resource "aws_lb_listener_rule" "https" {
  count        = local.create ? 1 : 0
  listener_arn = aws_alb_listener.https_alb_listener[count.index].arn
  priority     = 10
  depends_on   = [aws_lb_target_group.ecs_tg]
  tags         = local.tags

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg[count.index].arn
  }

  condition {
    host_header {
      values = [aws_route53_record.route53_record[0].fqdn]
    }
  }
  #FIXME - Verify if this is required?
  lifecycle {
    ignore_changes = [priority]
  }
}

# The HTTP to HTTPS redirect rule
resource "aws_lb_listener_rule" "http_to_https_redirect" {
  count        = local.create && var.enable_http_to_https_redirection ? 1 : 0
  listener_arn = aws_alb_listener.http_alb_listener[count.index].arn
  priority     = 10
  depends_on   = [aws_lb_target_group.ecs_tg]
  tags         = local.tags

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = [aws_route53_record.route53_record[0].fqdn]
    }
  }
  #FIXME - Verify if this is required?
  lifecycle {
    ignore_changes = [priority]
  }
}

#===================================================================================================================
# ROUTE53
# ==================================================================================================================
resource "aws_route53_record" "route53_record" {
  count           = local.create && length(compact(var.service_aliases)) > 0 ? 1 : 0
  zone_id         = var.hosted_zone_id
  name            = compact(var.service_aliases)[count.index]
  allow_overwrite = false
  type            = "A"
  depends_on      = [aws_lb.alb]

  alias {
    name                   = aws_lb.alb[count.index].dns_name
    zone_id                = aws_lb.alb[count.index].zone_id
    evaluate_target_health = var.evaluate_target_health
  }

}

#===================================================================================================================
# Task Definition
# ==================================================================================================================
#FIXME - Add execute command support, WAF, Athena workgroup(and related infra)
#FIXME - Update task definition with new image tag without CI/CD?

resource "aws_ecs_task_definition" "task_definition" {
  count  = local.create && var.task_definition_arn == "" ? 1 : 0
  family = var.task_definition_name == "" ? "${local.project_name}-${local.component}" : var.task_definition_name

  container_definitions = var.ecs_task_container_definitions
  #Optional parameters
  cpu    = var.ecs_task_cpu_size
  memory = var.ecs_task_memory_size

  requires_compatibilities = ["FARGATE"]

  network_mode = "awsvpc"

  execution_role_arn = var.ecs_execution_role

  task_role_arn = var.ecs_task_role

  volume {
    name = "${local.env}-${local.customer_identifier}-${local.component}"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.mesmer_pod[0].id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.mesmer_pod[0].id
        iam             = "ENABLED"
      }
    }
  }


  ephemeral_storage {
    size_in_gib = var.ecs_task_ephemeral_storage
  }

  tags = local.tags
}
resource "aws_ecs_cluster" "ecs_cluster" {
  count = local.create ? 1 : 0
  name  = local.ecs_cluster_name
  tags  = local.tags

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }
}

#===================================================================================================================
# ECS Service
# ==================================================================================================================
# Target Group
resource "aws_lb_target_group" "ecs_tg" {
  count                = local.create ? 1 : 0
  #FIXME:
  name                 = "${local.env}-${local.customer_identifier}-${local.component}"
  vpc_id               = var.vpc_id
  port                 = var.target_group_port
  protocol             = var.target_group_protocol
  target_type          = var.target_type
  deregistration_delay = var.deregistration_delay
  tags                 = local.tags
  depends_on           = [aws_lb.alb]

  health_check {
    enabled             = true
    interval            = var.alb_health_check_interval
    path                = var.alb_health_check_path
    port                = var.alb_health_check_port
    protocol            = var.alb_health_check_protocol
    timeout             = var.alb_health_check_timeout
    unhealthy_threshold = var.alb_health_check_unhealthy_threshold
    matcher             = "200,202"
  }
}

#ECS SG
resource "aws_security_group" "ecs_sg" {
  count       = local.create ? 1 : 0
  name        = "${var.project_name}-${local.component}-ecs"
  vpc_id      = var.vpc_id
  description = "${var.project_name}-${local.component}-ecs"
  tags        = local.tags
}

#FIXME - Why we need to allow egress traffic on all ports, sources
#SG-rule
resource "aws_security_group_rule" "ecs_egress" {
  count     = local.create ? 1 : 0
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  #tfsec:ignore:aws-vpc-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All egress traffic"
  security_group_id = aws_security_group.ecs_sg[count.index].id
  depends_on        = [aws_security_group.ecs_sg, aws_security_group.alb_sg]

}

#SG-rule
resource "aws_security_group_rule" "ecs_tcp" {
  count     = local.create ? 1 : 0
  type      = "ingress"
  from_port = var.ecs_service_sg_from_port
  to_port   = var.ecs_service_sg_to_port
  #FIXME - why -1?
  protocol                 = "-1"
  source_security_group_id = aws_security_group.alb_sg[count.index].id
  security_group_id        = aws_security_group.ecs_sg[count.index].id
  description              = "ECS Security group Rule - Allow ports according to the Container definitions"
  #FIXME - remove depends_on if not required
  depends_on = [aws_security_group.ecs_sg, aws_security_group.alb_sg]

}

resource "aws_security_group_rule" "ecs_efs" {
  count     = local.create ? 1 : 0
  type      = "ingress"
  from_port = 2049
  to_port   = 2049
  cidr_blocks = [local.vpc_cidr]
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_sg[count.index].id
  description              = "NFS inbound"
  #FIXME - remove depends_on if not required
  depends_on = [aws_security_group.ecs_sg]

}


#ECS Service

resource "aws_ecs_service" "aws_ecs_service" {
  count   = local.create ? 1 : 0
  name    = var.ecs_service_name == "" ? local.component : var.ecs_service_name
  cluster = aws_ecs_cluster.ecs_cluster[count.index].id
  #  launch_type                        = var.ecs_launch_type
  deployment_minimum_healthy_percent = var.ecs_deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.ecs_deployment_maximum_percent
  task_definition                    = var.task_definition_arn == "" ? aws_ecs_task_definition.task_definition[count.index].arn : var.task_definition_arn
  desired_count                      = var.desired_count
  health_check_grace_period_seconds  = var.ecs_service_health_check_grace_period_seconds
  wait_for_steady_state              = var.enable_ecs_service_wait_for_steady_state
  tags                               = local.tags
  #FIXME - remove depends_on if not required
  depends_on             = [aws_ecs_task_definition.task_definition, aws_security_group.ecs_sg]
  enable_execute_command = var.enable_execute_command

  deployment_circuit_breaker {
    enable   = var.enable_ecs_service_deployment_circuit_breaker
    rollback = var.enable_ecs_service_deployment_rollback
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg[count.index].arn
    container_name   = local.ecs_task_primary_container_name
    container_port   = var.ecs_service_alb_container_port
  }
  network_configuration {
    security_groups  = [aws_security_group.ecs_sg[count.index].id]
    subnets          = split(",", join(",", var.private_subnet_ids))
    assign_public_ip = false
  }
  propagate_tags = var.propagate_ecs_service_tags

  lifecycle {
    ignore_changes = [desired_count]
  }
  dynamic "capacity_provider_strategy" {
    for_each = var.enable_fargate_capacity_provider ? [1] : []
    content {
      capacity_provider = "FARGATE"
      base              = var.fargate_capacity_provider_base
      weight            = var.fargate_capacity_provider_weight
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.enable_fargate_spot_capacity_provider ? [1] : []
    content {
      capacity_provider = "FARGATE_SPOT"
      base              = var.fargate_spot_capacity_provider_base
      weight            = var.fargate_spot_capacity_provider_weight
    }
  }
}
