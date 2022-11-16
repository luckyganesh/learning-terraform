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