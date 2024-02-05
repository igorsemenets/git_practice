provider "aws" {
  region = "us-east-2"
}
resource "aws_instance" "example" {
	ami 					= "ami-05fb0b8c1424f266b"
	instance_type 			= "t2.micro"
	vpc_security_group_ids 	= [aws_security_group.instance.id]


	user_data = <<-EOF
				#!/bin/bash
				echo "Hello,Igorushka!" > index.html
				nohup busybox httpd -f -p 8080 &
				EOF

user_data_replace_on_change = true
tags = {
	Name = "Terraform-example"
 }
}
resource "aws_security_group" "instance" {

	name = var.security_group_name

	ingress {
		from_port 	= 8080
		to_port 	= 8080
		protocol 	= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
  
 }
}
variable "security_group_name" {
	description = "The name of the sucurity group"
	type 		= string
	default 	= "terraform-example-instance"
}

output "public_ip" {
	value 	= aws_instance.example.public_ip
	description = "The public IP of the instance"
}