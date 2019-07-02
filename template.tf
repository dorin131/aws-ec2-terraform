provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "demo_nginx_vpc" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "demo_nginx_subnet" {
  vpc_id     = "${aws_vpc.demo_nginx_vpc.id}"
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "demo_nginx_http" {
  vpc_id      = "${aws_vpc.demo_nginx_vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["80.169.33.150/32", "88.98.174.98/32", "82.46.207.17/32"]
  }
}

resource "aws_network_interface" "demo_nginx_ni" {
  subnet_id       = "${aws_subnet.demo_nginx_subnet.id}"
  security_groups = ["${aws_security_group.demo_nginx_http.id}"]
}


resource "aws_instance" "demo_nginx_ec2" {
  ami           = "ami-0bdfa1adc3878cd23" # Amazon Linux AMI 2018.03.0 (HVM), SSD Volume Type
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.demo_nginx_http.id}"]
  subnet_id = "${aws_subnet.demo_nginx_subnet.id}"
  associate_public_ip_address = true
  # key_name = "nginx_demo"
  user_data = <<-EOF
    #!/bin/bash
    sudo yum install -y docker 
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    sudo chmod 666 /var/run/docker.sock
    docker run -d -p 80:80 nginx
  EOF
}

resource "aws_internet_gateway" "demo_nginx_ig" {
  vpc_id = "${aws_vpc.demo_nginx_vpc.id}"
}

resource "aws_route_table" "demo_nginx_rt" {
  vpc_id = "${aws_vpc.demo_nginx_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.demo_nginx_ig.id}"
  }
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.demo_nginx_subnet.id}"
  route_table_id = "${aws_route_table.demo_nginx_rt.id}"
}