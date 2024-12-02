//Create Virtual Private Cloud
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    tags = {
        name= "main" 
    }
}

//Create 2 subnets across 2 AZs
resource "aws_subnet" "subnet1" {
    vpc_id = aws_vpc.main.id 
    //Dynamically calculate CIDR range for subnet based on VPC CIDR
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
    map_public_ip_on_launch = true
    availability_zone = "eu-west-1a"
}

resource "aws_subnet" "subnet2" {
    vpc_id = aws_vpc.main.id 
    //Dynamically calculate CIDR range for subnet based on VPC CIDR
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 2)
    map_public_ip_on_launch = true
    availability_zone = "eu-west-1b"
}

//Create Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.main.id
    tags = {
      Name = "internet_gateway"
    }
}

//Create Route Table
resource "aws_route_table" "route_table" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gateway.id
    }
}

//Associate both subnets
resource "aws_route_table_association" "subnet1_route" {
    subnet_id = aws_subnet.subnet1.id
    route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "subnet2_route" {
    subnet_id = aws_subnet.subnet2.id
    route_table_id = aws_route_table.route_table.id
}

//Create Security Group
resource "aws_security_group" "security_group" {
    name = "ecs-security-group"
    vpc_id = aws_vpc.main.id

    //Allow all inbound and outbound traffic for now
    ingress {
        from_port = 0
        to_port = 0
        protocol = -1
        self = "false"
        cidr_blocks = ["0.0.0.0/0"]
        description = "any"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
