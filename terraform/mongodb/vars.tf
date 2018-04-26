variable "instance_count" {
  description = "Number of instances"
  default     = "3"
}

variable "instance_type" {
  description = "Instance family"
  default     = "t2.micro"
}

variable "allowed_cidr" {
  description = "Allowed CIDR for MongoDB access"
  default     = [<insert>]
}

variable "key_name" {
  description = "Instance SSH key pair"
  default     = <insert>
}
