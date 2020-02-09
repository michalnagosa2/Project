resource "aws_vpc" "project-vpc" {
    cidr_block = "192.168.0.0/16"
    enable_dns_hostnames = true
  tags = {
    Name = "Project vpc"
  }
}


resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.project-vpc.id}"
}

resource "aws_security_group" "nat" {
    name = "vpc_nat"
    description = "Allow traffic to pass from the private subnet to the internet"


    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 2375
        to_port = 2375
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["192.168.0.0/16"]
    }
    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.project-vpc.id}"

    tags={
        Name = "NATSG"
    }
}

resource "aws_key_pair" "Project_key" {
  key_name = "Project_key"
  public_key = file("Project_key.pub")
}

resource "aws_instance" "nat" {
    ami = "ami-00a9d4a05375b2763" # this is a special ami preconfigured to do NAT
    availability_zone = "us-east-1b"
    instance_type = "m1.small"
    key_name = aws_key_pair.Project_key.key_name
    vpc_security_group_ids = ["${aws_security_group.nat.id}"]
    subnet_id = "${aws_subnet.public-subnet.id}"
    associate_public_ip_address = true
    source_dest_check = false

    tags= {
        Name = "VPC NAT"
    }
}
resource "aws_eip" "nat" {
    instance = "${aws_instance.nat.id}"
    vpc = true
}

##################################################################
#  Public Subnet
##################################################################
resource "aws_subnet" "public-subnet" {
    vpc_id = "${aws_vpc.project-vpc.id}"
    cidr_block = "192.168.1.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1b"
tags ={
    name = "public-subnet"
 }
}

resource "aws_route_table" "eu-west-1a-public" {
    vpc_id = "${aws_vpc.project-vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags= {
        Name = "Public Subnet"
    }
}

resource "aws_route_table_association" "eu-west-1a-public" {
    subnet_id = "${aws_subnet.public-subnet.id}"
    route_table_id = "${aws_route_table.eu-west-1a-public.id}"
}

##################################################################
#  Private Subnet
##################################################################


resource "aws_subnet" "priavte-subnet1" {
    vpc_id = "${aws_vpc.project-vpc.id}"
    cidr_block = "192.168.2.0/24"
    availability_zone = "us-east-1a"
    tags ={
        name = "priavte-subnet"
    }
}


resource "aws_route_table" "eu-west-1a-private" {
    vpc_id = "${aws_vpc.project-vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat.id}"
    }

    tags ={
        Name = "Private Subnet"
    }
}

resource "aws_route_table_association" "eu-west-1a-private" {
    subnet_id = "${aws_subnet.priavte-subnet1.id}"
    route_table_id = "${aws_route_table.eu-west-1a-private.id}"
}
