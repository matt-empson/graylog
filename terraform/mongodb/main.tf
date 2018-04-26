provider "aws" {
  profile = <insert>
  region  = <insert>
}

// Remote State
terraform {
  backend "s3" {
    bucket         = <insert>
    key            = <insert>
    region         = <insert>
    dynamodb_table = <insert>
    profile        = <insert>
  }
}

// Data Resources
data "aws_availability_zones" "azs" {}

data "aws_ami" "mongo_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["*Mongo*"]
  }
}

data "aws_security_group" "management_allow_in" {
  vpc_id = "${data.terraform_remote_state.vpc.vpc-id}"

  filter {
    name   = "group-name"
    values = ["management_allow_in"]
  }
}

// Remote State Data
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket         = <insert>
    key            = <insert>
    region         = <insert>
    dynamodb_table = <insert>
    profile        = <insert>
  }
}
