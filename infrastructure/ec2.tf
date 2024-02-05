# Variables
variable "instanceName" {
  type    = string
  default = "ecs-preprod"
}

variable "keyName" {
  type    = string
  default = "ecs-preprod-ssh-key"
}

# Resources

# ECS role for EC2
resource "aws_iam_role" "ec2InstanceRole" {
  name = "ecs-Instance-Role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2008-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
}

# Iam policy for EC2
resource "aws_iam_policy" "ec2InstancePolicy" {
  name = "EC2-permissions-for-ecs"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DescribeTags",
            "ecs:CreateCluster",
            "ecs:DeregisterContainerInstance",
            "ecs:DiscoverPollEndpoint",
            "ecs:Poll",
            "ecs:RegisterContainerInstance",
            "ecs:StartTelemetrySession",
            "ecs:UpdateContainerInstancesState",
            "ecs:Submit*",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "ecs:TagResource",
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "ecs:CreateAction" : [
                "CreateCluster",
                "RegisterContainerInstance"
              ]
            }
          }
        }
      ]
    }
  )
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "policy-role-attachment" {
  policy_arn = aws_iam_policy.ec2InstancePolicy.arn
  role       = aws_iam_role.ec2InstanceRole.name
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2InstanceProfile" {
  name = "ec2InstanceProfile"
  role = aws_iam_role.ec2InstanceRole.name
}

# Launch Template
resource "aws_launch_template" "ecsLaunchTemplate" {
  name_prefix            = "ecs-launch-template"
  image_id               = "ami-0a3c3a20c09d6f377"
  instance_type          = "t3.micro"
  key_name               = var.keyName
  vpc_security_group_ids = [aws_security_group.ecsSecurityGroup.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2InstanceProfile.name
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }
  user_data = filebase64("${path.module}/ecs.sh")
  tags = {
    Name = "ecs-preprod-instances"
  }
}

# Attach launch template to auto-scaling group
resource "aws_autoscaling_group" "ecsAutoScalingGroup" {
  vpc_zone_identifier = [aws_subnet.preprodSubnet1.id, aws_subnet.preprodSubnet2.id]
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  launch_template {
    id      = aws_launch_template.ecsLaunchTemplate.id
    version = "$Latest"
  }
}

# Application Load Balancer
resource "aws_lb" "applicationLoadBalancer" {
  name               = "preprod-application-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecsSecurityGroup.id]
  subnets            = [aws_subnet.preprodSubnet1.id, aws_subnet.preprodSubnet2.id]
}

# Listener for the load balancer above
resource "aws_lb_listener" "applicationLoadBalancerListener" {
  load_balancer_arn = aws_lb.applicationLoadBalancer.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.applicationLoadBalancerTargetGroup.arn
  }
}

# Target group for the above listener
resource "aws_lb_target_group" "applicationLoadBalancerTargetGroup" {
  name        = "preprod-targetgroup"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.preprodVpc.id
  health_check {
    path = "/"
  }
}