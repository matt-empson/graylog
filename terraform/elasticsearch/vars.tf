variable "instance_count" {
  description = "Number of instances"
  default     = "1"
}

variable "instance_type" {
  description = "Instance family"
  default     = "t2.medium"
}

variable "allowed_cidr" {
  description = "Allowed CIDR for ALB"
  default     = [<insert>]
}

variable "key_name" {
  description = "Instance SSH key pair"
  default     = <insert>
}
