#Define variables
variable "server_port" {
		description = "The port the server will use for HTTP requests"
		type        = number
		default     = 8080
	}
#Provider configuration
provider "aws" {
  region = "us-east-2"
}
#The resources to be deployed.Now we switched to launch config
resource "aws_launch_configuration" "example" {
	image_id 				= "ami-05fb0b8c1424f266b"
	instance_type 			= "t2.micro"
	security_groups         = [aws_security_group.instance.id]


  	user_data = <<-EOF
				#!/bin/bash
				echo "Science, bitches!!! - by Jesse" > index.html
				nohup busybox httpd -f -p ${var.server_port} &
				EOF
				#required to use launch configuration with an autoscaling groupassociate_public_ip_address
				lifecycle {
				  create_before_destroy = true
				}
}

#user date parameter is not needed in launch configuration and tags also, so just deleted both
#now we are adding block of asg so we can create launch
#configuration, launch configuration is used innstead of
#instance Launch config will let us launch multiple
#instances to achive fault tolerance and autoscaling


resource "aws_autoscaling_group" "example" {
	launch_configuration = aws_launch_configuration.example.name
	vpc_zone_identifier = data.aws_subnets.default.ids

	target_group_arns = [aws_lb_target_group.asg.arn]
	health_check_type = "ELB"


	min_size = 2
	max_size = 10


	tag {
	  key 					= "Name"
	  value 				= "terraform-asg-example"
	  propagate_at_launch 	= true
	
	}
  
}
data "aws_vpc" "default" {
	default = true
  
}
data "aws_subnets" "default" {
	filter {
		name = "vpc-id"
		values = [data.aws_vpc.default.id]
	}
  
}
resource "aws_security_group" "instance" {

	name = "terraform-example-instance"

	ingress {
		from_port 	= var.server_port
		to_port 	= var.server_port
		protocol 	= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
  
 }
}
variable "security_group_name" {
	description = "The name of the sucurity group"
	type 		= string
	default 	= "terraform-example-instance"
}
resource "aws_lb" "example" {
	name = "terraform-asg-example"
	load_balancer_type = "application"
	subnets = data.aws_subnets.default.ids
	security_groups = [aws_security_group.alb.id]
  
}
resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.example.arn
	port = 80
	protocol = "HTTP"
	#by default return a simple 404 page
	default_action {
	  type = "fixed-response"


	  fixed_response {
		content_type = "text/plain"
		message_body = "404: sience bitch!"
		status_code = 404
	  }
	}
}
resource "aws_security_group" "alb" {
	name = "terraform-example-alb"

	#Allow inbound HTTP requests
	ingress  {
		from_port=80
		to_port=80
		protocol="tcp"
		cidr_blocks=["0.0.0.0/0"]
	}
  #Allow all outbound requests
  egress{
	from_port = 0
	to_port = 0
	protocol = "-1"
	cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_lb" "example_alb" {
	name = "terraform-asg-example"
	load_balancer_type = "application"
	subnets = data.aws_subnets.default.ids
	security_groups = [aws_security_group.alb.id]
  
}
resource "aws_lb_target_group" "asg" {
	name = "terraform-asg-example"
	port = var.server_port
	protocol = "HTTP"
	vpc_id = data.aws_vpc.default.id

	health_check {
	  path = "/"
	  protocol = "HTTP"
	  matcher = "200"
	  interval = 15
	  timeout = 3
	  healthy_threshold = 2
	  unhealthy_threshold = 2
	}
  
}
resource "aws_lb_listener_rule" "asg" {
	listener_arn = aws_lb_listener.http.arn
	priority = 100

	condition {
	  path_pattern {
		
		values = ["*"]
	  }
	}
	action {
	  type = "forward"
	  target_group_arn = aws_lb_target_group.asg.arn
	}
  
}
output "alb_dns_name" {
	value 	= aws_lb.example.dns_name
	description = "The domain name of the load balancer"
}