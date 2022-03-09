######################################################################################################################################################
# Sample Data Engineering Service - AWS Infrastructure
######################################################################################################################################################

provider "aws" {
  version = "<= 3.37.0"
  region  = "us-east-1"
  profile = "dev-DE"
}


######################################################################################################################################################
# VPC
######################################################################################################################################################

# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}


######################################################################################################################################################
# SUBNETS
######################################################################################################################################################

# Providing a reference to our default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-1a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-east-1b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "us-east-1c"
}


######################################################################################################################################################
# ECR REPO
######################################################################################################################################################

resource "aws_ecr_repository" "sample_svc_repo" {
  name = "sample-svc-repo"
}

output "repo-url" {
  value = "$aws_ecr_repository.sample_svc_repo.repository_url"
}


######################################################################################################################################################
# ECS CLUSTER
######################################################################################################################################################

resource "aws_ecs_cluster" "sample_svc_cluster" {
  name = "sample-svc-cluster"
  tags = {
    name = "sample-svc-cluster"
  }
}


######################################################################################################################################################
# ECS TASK
######################################################################################################################################################

resource "aws_ecs_task_definition" "sample_svc_task" {
  family                   = "sample-svc-task"
  container_definitions    = "${data.template_file.task_definition_json.rendered}"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  execution_role_arn       = "${aws_iam_role.sample_svc_task_exec_role.arn}"
  task_role_arn            = "${aws_iam_role.sample_svc_task_exec_role.arn}"
  #memory                   = "8192"
  #cpu                      = "4096"
}

data "template_file" "task_definition_json" {
  template = "${file("${path.module}/task_definition.json")}"
}


######################################################################################################################################################
# IAM INSTANCE PROFILE
######################################################################################################################################################

resource "aws_iam_instance_profile" "sampl_svc_profile" {
  name = "sample-svc-profile"
  path = "/"
  role = aws_iam_role.ecs_instance_role.name
  #provisioner "local_exec" {
  #  command = "sleep 60"
  #}
}


######################################################################################################################################################
# POLICY
######################################################################################################################################################
resource "aws_iam_policy" "logs_policy" {
  name = "sample-svc-logs-policy"
  description = "The logs policy for Sample Data Engineering Service."
  policy = "${data.aws_iam_policy_document.logs_policy.json}"
}


######################################################################################################################################################
# POLICY DOCUMENTS
######################################################################################################################################################

data "aws_iam_policy_document" "service_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_insance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "logs_policy" {
  statement {
    actions = ["logs:*"]
    resources = ["*"]
  }
}


######################################################################################################################################################
# IAM ROLES
######################################################################################################################################################

resource "aws_iam_role" "sample_svc_role" {
  name               = "sample-svc-role"
  assume_role_policy = "${data.aws_iam_policy_document.service_assume_role_policy.json}"
}

resource "aws_iam_role" "sample_svc_task_exec_role" {
  name               = "sample-svc-task-exec-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_task_assume_role_policy.json}"
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role-${aws_ecs_cluster.mse_svc_cluster.name}"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_insance_assume_role_policy.json}"
}


######################################################################################################################################################
# IAM ROLE POLICY ATTACHMENTS
######################################################################################################################################################

resource "aws_iam_role_policy_attachment" "sample_svc_role_policy" {
  role       = "${aws_iam_role.mse_svc_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_role_policy_attachment" "sample_svc_task_exec_role_policy" {
  role       = "${aws_iam_role.mse_svc_task_exec_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy"{
  role       = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "logs_role_policy"{
  role       = "${aws_iam_role.sample_svc_task_exec_role.name}"
  policy_arn = "${aws_iam_policy.logs_policy.arn}"
}


######################################################################################################################################################
# LOAD BALANCER
######################################################################################################################################################

resource "aws_alb" "application_load_balancer" {
  name               = "sample-lb-tf" # Naming our load balancer
  load_balancer_type = "application"
  subnets = [ # Referencing the default subnets
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}",
    "${aws_default_subnet.default_subnet_c.id}"
  ]
  # Referencing the security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "load_balancer_security_group" {
  name = "sample-svc-sg"
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "sample-svc-target-group"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_default_vpc.default_vpc.id}" # Referencing the default VPC

  #STEP 1 - ECS task Running
  health_check {
    healthy_threshold   = 3
    interval            = 120
    timeout             = 30
    port                = 5000
    path                = "/"
    protocol            = "HTTP"
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}" # Referencing our load balancer
  port              = "5000"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our tagrte group
  }
}


######################################################################################################################################################
# ECS SERVICE
######################################################################################################################################################

resource "aws_ecs_service" "sample_service" {
  name            = "sample-service"                             # Naming our first service
  cluster         = "${aws_ecs_cluster.sample_svc_cluster.id}"             # Referencing our created Cluster
  task_definition = "${aws_ecs_task_definition.sample_svc_task.arn}" # Referencing the task our service will spin up
  launch_type     = "EC2"
  desired_count   = 1 # Setting the number of containers to 3
  depends_on = ["aws_lb_listener.listener"]
  #iam_role = "${aws_iam_role.sample_svc_role.arn}"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our target group
    container_name   = "sample-svc-ecs-container"  
    container_port   = 5000 # Specifying the container port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
    security_groups  = ["${aws_security_group.service_security_group.id}"] # Setting the security group
    assign_public_ip = "false"
  }
}


######################################################################################################################################################
# SECURITY GROUP
######################################################################################################################################################

resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


######################################################################################################################################################
# LAUNCH CONFIGURATION
######################################################################################################################################################

resource "aws_launch_configuration" "sample_ecs_instance"{
    name = "sample-svc-ecs-instance"
    instance_type = "m4.4xlarge"
    image_id = "${data.aws_ami.ecs_ami.id}"
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
    iam_instance_profile = aws_iam_instance_profile.mse_svc_profile.name
    user_data              = "${data.template_file.user_data.rendered}"
    #lifecycle {
    #  ignore_changes         = ["ami", "user_data", "subnet_id", "key_name", "ebs_optimized", "private_ip"]
    #}
}


######################################################################################################################################################
# AUTO-SCALING GROUP
######################################################################################################################################################

resource "aws_autoscaling_group" "ecs_cluster_instances"{
    availability_zones = ["us-east-1a"]
    name = "mse-svc-ecs-cluster-instances"
    min_size = 1
    max_size = 1
    launch_configuration = "${aws_launch_configuration.sample_ecs_instance.name}"

    tag {
      key = "Name"
      value = "MSE Service ASG"
      propagate_at_launch = true
    }
}


######################################################################################################################################################
# AMI
######################################################################################################################################################

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

######################################################################################################################################################
# AWS ECS-EC2
######################################################################################################################################################
#resource "aws_instance" "ec2_instance" {
#  ami                    = "${data.aws_ami.ecs_ami.id}"
#  #subnet_id              =  "subnet-087e48d4db31e442d" #CHANGE THIS
#  instance_type          = "t2.medium"
#  iam_instance_profile   = aws_iam_instance_profile.mse_svc_profile.name
#  vpc_security_group_ids = ["${aws_security_group.load_balancer_security_group.id}"]
#  #key_name               = "mse-svc" #CHANGE THIS
#  ebs_optimized          = "false"
#  source_dest_check      = "false"
#  user_data              = "${data.template_file.user_data.rendered}"
#
#  lifecycle {
#    ignore_changes         = ["ami", "user_data", "subnet_id", "key_name", "ebs_optimized", "private_ip"]
#  }
#}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"
}


###############################################################
# AWS ECS-ROUTE53
###############################################################
resource "aws_route53_zone" "r53_private_zone" {
  name         = "sample-svc.com"
  #private_zone = false
}

resource "aws_route53_record" "dns" {
  zone_id = "${aws_route53_zone.r53_private_zone.zone_id}"
  name    = "sample-svc-test"
  type    = "A"

  alias {
    evaluate_target_health = false
    name                   = "${aws_alb.application_load_balancer.dns_name}"
    zone_id                = "${aws_alb.application_load_balancer.zone_id}"
  }
}
