data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/22"
  
  tags = {
    Name = "My Test VPC"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "My Test IGW"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.my_igw.id}"
  }

  tags {
    Name = "My Test RTB"
  }
}

resource "aws_default_route_table" "private_route" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"

  tags {
    Name = "My Test private RTB"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = "${var.subnet_count}"
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.public_cidrs[count.index]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"

  tags {
    Name = "My Test Public Subnet.${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count                   = "${var.subnet_count}"
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.private_cidrs[count.index]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"

  tags {
    Name = "My Test Private Subnet.${count.index + 1}"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  count           = "${aws_subnet.public_subnet.count}"
  route_table_id  = "${aws_route_table.public_route_table.id}"
  subnet_id       = "${aws_subnet.public_subnet.*.id[count.index]}"
  depends_on      = ["aws_route_table.public_route", "aws_subnet.public_subnet"]
}

resource "aws_route_table_association" "private_subnet_association" {
  count           = "${aws_subnet.private_subnet.count}"
  route_table_id  = "${aws_default_route_table.private_route.id}"
  subnet_id       = "${aws_subnet.private_subnet.*.id[count.index]}"
  depends_on      = ["aws_default_route_table.private_route", "aws_subnet.private_subnet"]
}

resource "aws_security_group" "public_sg" {
  name   = "Allow Web Server Traffic"
  vpc_id = "${aws_vpc.main.id}"
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "private_sg" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = "${aws_security_group.public_sg.id}"
}

resource "aws_eip" "eip" {
  count = "${var.eip_count}"
}

resource "aws_nat_gateway" "gw" {
  count           = "${var.eip_count}"
  allocation_id   = "${aws_eip.eip.*.id, count.index}"
  subnet_id       = "${aws_subnet.public_subnet.*.id[count.index]}"
  depends_on      = ["aws_internet_gateway.my_igw"]
}

