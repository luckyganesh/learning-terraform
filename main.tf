resource "aws_lb" "my_nlb" {
  name = "my-nlb"
  internal = false
  load_balancer_type = "network"
  subnets = [aws_subnet.web1.id,aws_subnet.web2.id]
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "targetgroup" {
  name = "web"
  port = 80
  protocol = "TCP"
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.my_nlb.arn
  port = 80
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.targetgroup.arn
  }
}

resource "aws_launch_configuration" "sai_launch_configuration" {
  name = "my_launch_configuration"
  image_id      = "ami-0e6329e222e662a52"
  instance_type = "t2.small"
  associate_public_ip_address = true
  key_name = aws_key_pair.my_key_pair.key_name
  security_groups = [aws_security_group.web_server_sg.id]
  user_data = <<-EOF
#!/bin/bash
sudo yum -y update
sudo yum install -y httpd
sudo service httpd start
echo "<html><body><h1>Hi this is SAI, how is it going?</h1></body></html>" > /var/www/html/index.html
EOF
}

resource "aws_autoscaling_group" "my_asg" {
  name = "my_asg"
  max_size = 4
  min_size = 2
  vpc_zone_identifier = [aws_subnet.web1.id, aws_subnet.web2.id]
  launch_configuration = aws_launch_configuration.sai_launch_configuration.id
  tag {
    key                 = "asg"
    value               = "my_asg"
    propagate_at_launch = true
  }

  target_group_arns = [aws_lb_target_group.targetgroup.arn]
}

resource "aws_key_pair" "my_key_pair" {
  key_name = "sai_key_pair"
  public_key = file("./sai_key_pair.pub")
}

resource "aws_security_group" "web_server_sg" {
  name        = "web_server_sg"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port = 22
    protocol  = "tcp"
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_subnet" "web1" {
  vpc_id = aws_vpc.my_vpc.id
  availability_zone_id = "aps1-az1"
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "first_subnet"
  }
}

resource "aws_subnet" "web2" {
  vpc_id = aws_vpc.my_vpc.id
  availability_zone_id = "aps1-az2"
  cidr_block = "10.0.3.0/24"
  tags = {
    Name = "second_subnet"
  }
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "sai-vpc"
  }
}

resource "aws_route" "my_route" {
  route_table_id = aws_vpc.my_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
