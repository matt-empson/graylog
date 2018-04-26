// Create Cluster and ALB Security Groups
resource "aws_security_group" "sg_es_alb_allow_in" {
  name        = "es_alb_allow_in"
  description = "Allow ElasticSearch ALB traffic to INBOUND"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc-id}"

  tags {
    Name      = "ElasticSearch ALB Permit INBOUND"
    Terraform = "True"
  }
}

resource "aws_security_group_rule" "sg_rule_es_alb_in" {
  type        = "ingress"
  from_port   = 9200
  to_port     = 9200
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_cidr}"]

  security_group_id = "${aws_security_group.sg_es_alb_allow_in.id}"
}

resource "aws_security_group_rule" "sg_rule_es_alb_allow_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.sg_es_alb_allow_in.id}"
}

resource "aws_security_group" "sg_es_allow_in" {
  name        = "es_allow_in"
  description = "Allow ElasticSearch Cluster traffic to INBOUND"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc-id}"

  tags {
    Name      = "ElasticSearch Cluster Permit INBOUND"
    Terraform = "True"
  }
}

resource "aws_security_group_rule" "sg_rule_es_rest_in" {
  type      = "ingress"
  from_port = 9200
  to_port   = 9200
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.sg_es_allow_in.id}"
}

resource "aws_security_group_rule" "sg_rule_es_alb_instance_in" {
  type                     = "ingress"
  from_port                = 9200
  to_port                  = 9200
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.sg_es_alb_allow_in.id}"

  security_group_id = "${aws_security_group.sg_es_allow_in.id}"
}

resource "aws_security_group_rule" "sg_rule_es_node_in" {
  type      = "ingress"
  from_port = 9300
  to_port   = 9300
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.sg_es_allow_in.id}"
}

resource "aws_security_group_rule" "sg_rule_es_allow_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.sg_es_allow_in.id}"
}

// Create ALB
resource "aws_lb_target_group" "tg_es" {
  name     = "ElasticSearch-Cluster"
  port     = 9200
  protocol = "HTTP"
  vpc_id   = "${data.terraform_remote_state.vpc.vpc-id}"

  tags {
    Name      = "ElasticSearch Target Group"
    Terraform = "True"
  }
}

resource "aws_lb_listener" "listener_es" {
  load_balancer_arn = "${aws_lb.alb_es.arn}"
  port              = "9200"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.tg_es.arn}"
    type             = "forward"
  }
}

resource "aws_lb" "alb_es" {
  name            = "ElasticSearch-Cluster"
  internal        = true
  security_groups = ["${aws_security_group.sg_es_alb_allow_in.id}"]
  subnets         = ["${data.terraform_remote_state.vpc.private-subnet-ids}"]

  enable_deletion_protection = true

  tags {
    Name      = "ElasticSearch ALB"
    Terraform = "True"
  }
}

// Create Role to Read Tags
resource "aws_iam_policy" "es_policy" {
  name        = "ElasticSearch-Policy"
  path        = "/"
  description = "ElasticSearch Cluster Policy"

  policy = <<EOF
{
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    }
  ],
  "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_policy_attachment" "es_policy_attach" {
  name       = "ElasticSearch-Policy-Attachment"
  roles      = ["${aws_iam_role.es_role.name}"]
  policy_arn = "${aws_iam_policy.es_policy.arn}"
}

resource "aws_iam_instance_profile" "es_profile" {
  name = "es_profile"
  path = "/"
  role = "${aws_iam_role.es_role.name}"
}

resource "aws_iam_role" "es_role" {
  name = "ElasticSearch-Cluster-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

// Create Launch Configuration
resource "aws_launch_configuration" "es_launch_conf" {
  name = "ElasticSearch Cluster"

  associate_public_ip_address = false
  enable_monitoring           = false
  iam_instance_profile        = "${aws_iam_instance_profile.es_profile.id}"
  image_id                    = "${data.aws_ami.es_ami.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  security_groups             = ["${data.aws_security_group.management_allow_in.id}", "${aws_security_group.sg_es_allow_in.id}"]

  root_block_device {
    volume_size           = "40"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

// Define Autoscaling Group
resource "aws_autoscaling_group" "es_auto_scale" {
  name = "ElasticSearch-Cluster"

  availability_zones   = ["${data.aws_availability_zones.azs.names}"]
  launch_configuration = "${aws_launch_configuration.es_launch_conf.id}"
  desired_capacity     = "3"
  max_size             = "4"
  min_size             = "2"
  target_group_arns    = ["${aws_lb_target_group.tg_es.arn}"]
  vpc_zone_identifier  = ["${data.terraform_remote_state.vpc.private-subnet-ids}"]

  tag = [{
    key                 = "Name"
    value               = "ElasticSearch ASG"
    propagate_at_launch = true
  },
    {
      key                 = "ElasticSearchCluster"
      value               = "true"
      propagate_at_launch = true
    },
  ]
}
