resource "aws_launch_template" "my_app_instance" {
  name                   = "my-app-instance"
  image_id               = "ami-0df435f331839b2d6"
  key_name               = "devops"
  instance_type = "t2.micro"
  # vpc_security_group_ids = [aws_security_group.ec2_instance.id]
  network_interfaces {
    security_groups = [aws_security_group.launch_template.id]
    subnet_id                   = "${aws_subnet.public_us_east_1a.id}"
    associate_public_ip_address = true
    delete_on_termination       = true 
  }
  user_data = base64encode("${file("user-data.sh")}")
}

resource "aws_lb_target_group" "my_app_instance" {
  name     = "my-app-instance"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    port                = 8081
    interval            = 30
    protocol            = "HTTP"
    path                = "/health"
    matcher             = "200"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_autoscaling_group" "my_app_instance" {
  name     = "my-app-instance"
  min_size = 1
  max_size = 3

  health_check_type = "EC2"

  vpc_zone_identifier = [
    aws_subnet.private_us_east_1a.id,
    aws_subnet.private_us_east_1b.id
  ]

  target_group_arns = [aws_lb_target_group.my_app_instance.arn]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.my_app_instance.id
        version = "${aws_launch_template.my_app_instance.latest_version}"
      }
    }
  }
}

resource "aws_autoscaling_policy" "my_app_instance" {
  name                   = "my-app-instance"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.my_app_instance.name

  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 25.0
  }
}

resource "aws_lb" "my_app_instance" {
  name               = "my-app-instance"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_instance.id]

  subnets = [
    aws_subnet.public_us_east_1a.id,
    aws_subnet.public_us_east_1b.id
  ]
}

resource "aws_lb_listener" "my_app_instance" {
  load_balancer_arn = aws_lb.my_app_instance.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_app_instance.arn
  }
}



