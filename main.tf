provider "aws"{

    region = "us-east-1"


}
resource "aws_autoscaling_group" "example_autoscaling"{

    launch_configuration = "${aws_launch_configuration.example_launch.name}"
    min_size = 2
    max_size = 3
    vpc_zone_identifier = ["${data.aws_subnet_ids.default_subnet.ids}"]

    tag = {
        key = "Name"
        value = "example-ags"
        propagate_at_launch = true

    }


}

resource "aws_launch_configuration" "example_launch" {
  image_id = "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.sg_instance.id}"]
  


  user_data =
             <<-EOF
             #!/BIN/BASH
             sudo yum update -yum
             sudo yum install -y httpd
             echo "Hello world" > index.html
             mv index.html /var/www/html
             sudo service httpd start
             EOF
   lifecycle = {
      create_before_destroy = true
  }

  

}

data "aws_vpc" "data_vpc"{
    default = true
}
data "aws_subnet_ids" "default_subnet" {

    vpc_id = "${data.aws_vpc.data_vpc.id}"


  
}
resource "aws_security_group" "sg_instance" {
    name = "${var.instance_security_group_name}"

    ingress = {
        from_port = "${var.server_port}"
        to_port = "${var.server_port}"
        protocol = "HTTP"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_lb" "example_lb" {
    name = "${var.alb_name}"
    load_balancer_type = "application"
    subnets = ["${data.aws_subnet_ids.default_subnet.ids}"]
    security_groups = ["${aws_security_group.sg_lb.id}"]
  
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.example_lb.arn}"
  port = 80
  protocol = "HTTP"

  default_action = {
      
      type = "fixed-resource"
      fixed_response = {
            content_type = "text/plain"
            message_body = "404 not found"
            status_code = 404
      }
      
  }
}

resource "aws_lb_target_group" "asg" {
  
  name = "${var.alb_name}"
  port = "${var.server_port}"
  protocol = "HTTP"
  vpc_id = "${data.aws_vpc.data_vpc.id}"

  health_check = {
      path = "/"
      protocol = "HTTP"
      mather = "200"
      interval = 15
      timeout = 3
      health_threshould = 2
      unhealthy_threshold = 2
  }


}
resource "aws_lb_listener_rule" "asg" {
  
  listener_arn = "${aws_lb_listener.http.arn}"
  priority = 100

  condition{
      path_pattern{
          values = ["*"]
      }
  }
  action{
      type = "forward"
      target_group_arn = "${aws_lb_target_group.asg.arn}"
  }

}

resource "aws_security_group" "sg_lb" {
    name = "${var.alb_security_group_name}"

    ingress{
        from_port = 80
        to_port = 80
        protocol = "HTTP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}




