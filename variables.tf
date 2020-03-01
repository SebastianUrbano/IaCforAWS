variable "alb_security_group_name" {
  type = "string"
  default = "sg-alb"
}

variable "server_port" {
  
  type = "string"
  default = "80"
}
variable "alb_name" {
  
  type = "string"
  default = "Alb class"
}

variable "instance_security_group_name" {
  type = "string"

  default = "sg-instance"
}



