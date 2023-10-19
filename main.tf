resource "aws_security_group" "ec2_instance" {
  name   = "ec2-instance"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "alb_instance" {
  name   = "alb-instance"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "launch_template" {
  name        = "launch-template-group"
  vpc_id = aws_vpc.main.id
  # Inbound rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from any source (public access)
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from any source (public access)
  }

  # You can add more ingress rules as needed for your use case.

  # Outbound rules (you can customize these as needed)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ingress_ec2_instance_traffic" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2_instance.id
  source_security_group_id = aws_security_group.alb_instance.id
}

resource "aws_security_group_rule" "ingress_ec2_instance_health_check" {
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2_instance.id
  source_security_group_id = aws_security_group.alb_instance.id
}

# resource "aws_security_group_rule" "full_egress_ec2_instance" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   security_group_id = aws_security_group.ec2_instance.id
#   cidr_blocks       = ["0.0.0.0/0"]
# }

resource "aws_security_group_rule" "ingress_alb_instance_http_traffic" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb_instance.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_alb_instance_https_traffic" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb_instance.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_alb_instance_traffic" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_instance.id
  source_security_group_id = aws_security_group.ec2_instance.id
}

resource "aws_security_group_rule" "egress_alb_instance_health_check" {
  type                     = "egress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_instance.id
  source_security_group_id = aws_security_group.ec2_instance.id
}


