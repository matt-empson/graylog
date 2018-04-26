// Create Instance
resource "aws_instance" "awsmongo_instance" {
  count = "${var.instance_count}"

  ami                    = "${data.aws_ami.mongo_ami.id}"
  key_name               = "${var.key_name}"
  instance_type          = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.sg_mongo_allow_in.id}", "${data.aws_security_group.management_allow_in.id}"]
  subnet_id              = "${data.terraform_remote_state.vpc.private-subnet-ids[count.index]}"

  root_block_device {
    volume_size           = "8"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags {
    Name      = "AWSMONGO0${count.index+1}"
    Terraform = "True"
  }
}

// Create and associate MongoDB security group
resource "aws_security_group" "sg_mongo_allow_in" {
  name        = "mongo_allow_in"
  description = "Allow MongoDB traffic to INBOUND"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc-id}"

  tags {
    Name      = "MongoDB Permit INBOUND"
    Terraform = "True"
  }
}

resource "aws_security_group_rule" "sg_rule_mongo_in" {
  type        = "ingress"
  from_port   = 27017
  to_port     = 27017
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_cidr}"]

  security_group_id = "${aws_security_group.sg_mongo_allow_in.id}"
}

resource "aws_security_group_rule" "sg_rule_mongo_rep_self_in" {
  type      = "ingress"
  from_port = 27017
  to_port   = 27017
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.sg_mongo_allow_in.id}"
}

resource "aws_security_group_rule" "sg_rule_mongo_allow_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.sg_mongo_allow_in.id}"
}
