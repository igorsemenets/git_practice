provider "aws" {
  region = "us-east-2"
}
resource "aws_instance" "ubuntu_one" {
	ami = "ami-05fb0b8c1424f266b"
	instance_type = "t2.micro"
	tags = {
		Name = "good_ubuntu"
	}
}