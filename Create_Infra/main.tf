resource "null_resource" "check_backend_sh_exists" {
  provisioner "local-exec" {
    command = "test -f files/backend.sh || (echo 'backend.sh not found!' && exit 1)"
  }
}

resource "null_resource" "check_frontend_sh_exists" {
  provisioner "local-exec" {
    command = "test -f files/frontend.sh || (echo 'frontend.sh not found!' && exit 1)"
  }
}


resource "aws_vpc" "MyVpc" {
   cidr_block = "10.0.0.0/16"
   instance_tenancy = "default"
   tags = {
     Name = "diptesh-VPC"
   }
}

resource "aws_subnet" "public" {
   vpc_id = aws_vpc.MyVpc.id
   cidr_block = "10.0.1.0/24"
   tags = {
     Name = "PUBLIC"
    }
}

resource "aws_subnet" "private" {
   vpc_id = aws_vpc.MyVpc.id
   cidr_block = "10.0.2.0/24"
   tags = {
     Name = "PRIVATE"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.MyVpc.id
    tags = {
      Name = "diptesh-igw"
     }
}

resource "aws_route_table" "rt-ig" {
  vpc_id = aws_vpc.MyVpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "diptesh-rt-ig"
   }
}

resource "aws_route_table_association" "rt-a-public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.rt-ig.id
}

resource "aws_eip" "eip" {
  tags = {
    Name = "nat-gateway-eip"
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "diptesh-ngw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [
    aws_internet_gateway.igw,
    null_resource.check_frontend_sh_exists,
    null_resource.check_backend_sh_exists
  ]

}

resource "aws_route_table" "rt-nat" {
  vpc_id = aws_vpc.MyVpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
   }
  tags = {
    Name = "diptesh-rt-nat"
   }
}


resource "aws_route_table_association" "rt-a-private" {
   subnet_id = aws_subnet.private.id
   route_table_id = aws_route_table.rt-nat.id
}


data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  	}
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_security_group" "sg_public_ins" {
   name = "allow_ssh_public"
   description = "Allow SSH inbound traffic to public instance"
   vpc_id = aws_vpc.MyVpc.id
   ingress {
     description = "SSH from anywhere"
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description     = "Allow ping from everywhere"
     from_port       = -1
     to_port         = -1
     protocol        = "icmp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "Allow HTTP from everywhere on port 3000"
     from_port   = 3000
     to_port     = 3000
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
   tags = {
     Name = "diptesh-sg-public"
   }
}

resource "aws_security_group" "sg_private_ins" {
   name = "allow_ssh_private"
   description = "Allow SSH inbound traffic to private instance"
   vpc_id = aws_vpc.MyVpc.id
   ingress {
     description = "Allow SSH from within the VPC"
     from_port = 22
     to_port = 22
     protocol = "tcp"
     cidr_blocks = [aws_subnet.public.cidr_block]     
   }
   ingress {
     description     = "Allow ping from within the VPC"
     from_port       = -1
     to_port         = -1
     protocol        = "icmp"
     cidr_blocks = [aws_subnet.public.cidr_block]
   }
   egress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   tags = {
     Name = "diptesh-sg-private"
   }
}

resource "aws_security_group_rule" "allow_frontend_to_backend" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.sg_private_ins.id
  source_security_group_id = aws_security_group.sg_public_ins.id
  description              = "Allow frontend SG - backend on port 5000"
}

resource "tls_private_key" "private_key_pair" {
  algorithm = "RSA"
}

resource "local_file" "private_key_pair" {
   content = tls_private_key.private_key_pair.private_key_pem
   filename = "backend.pem"
   file_permission = "0400"
}

resource "aws_key_pair" "private_key_pair" {
   key_name = "diptesh-private-key"
   public_key = tls_private_key.private_key_pair.public_key_openssh
}

resource "aws_instance" "backend" {
   ami = data.aws_ami.ubuntu.id
   instance_type = "t3.micro"
   key_name = aws_key_pair.private_key_pair.key_name
   subnet_id = aws_subnet.private.id
   vpc_security_group_ids = [aws_security_group.sg_private_ins.id]
   depends_on = [aws_key_pair.private_key_pair]

   tags = {
     Name = "BACKEND"
    }
}

resource "tls_private_key" "public_key_pair" {
  algorithm = "RSA"
}

resource "local_file" "public_key_pair" {
   content = tls_private_key.public_key_pair.private_key_pem
   filename = "frontend.pem"
   file_permission = "0400"
}

resource "aws_key_pair" "public_key_pair" {
   key_name = "diptesh-public-key"
   public_key = tls_private_key.public_key_pair.public_key_openssh
}

resource "aws_instance" "frontend" {
   ami = data.aws_ami.ubuntu.id
   instance_type = "t3.micro"
   key_name = aws_key_pair.public_key_pair.key_name
   subnet_id = aws_subnet.public.id
   vpc_security_group_ids = [aws_security_group.sg_public_ins.id]
   associate_public_ip_address = true
   depends_on = [
     aws_key_pair.public_key_pair,
   ]

   tags = {
     Name = "FRONTEND"
    }
}

resource "null_resource" "backend_provisioner" {
   depends_on = [aws_instance.backend,
                 aws_instance.frontend,
                 null_resource.check_backend_sh_exists 
                ]
   provisioner "file" {
     source = "files/backend.sh"
     destination = "backend.sh"
   }
   provisioner "remote-exec" {
     inline = [
          "chmod +x backend.sh",
          "sudo ./backend.sh ${var.backend_port}",
          "sudo docker --version",
          "sudo docker ps",
         ]
    }
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = tls_private_key.private_key_pair.private_key_pem
     host = aws_instance.backend.private_ip
     bastion_host = aws_instance.frontend.public_ip
     bastion_user = "ubuntu"
     bastion_private_key = tls_private_key.public_key_pair.private_key_pem
   }
}


resource "null_resource" "frontend_provisioner" {
   depends_on = [aws_instance.backend,
                 aws_instance.frontend,
                 null_resource.check_frontend_sh_exists,
                 null_resource.backend_provisioner
                ]
   provisioner "file" {
     source = "backend.pem"
     destination = "backend.pem"
   }
   provisioner "file" {
     source = "files/frontend.sh"
     destination = "frontend.sh"
   }
   provisioner "remote-exec" {
     inline = [
          "chmod +x frontend.sh",
          "sudo ./frontend.sh ${aws_instance.backend.private_ip} ${var.frontend_port}",
          "chmod 400 backend.pem",
          "sudo docker --version",
          "sudo docker ps",
          "curl -I http://${aws_instance.backend.private_ip}:${var.backend_port}"
         ]
    }
   connection {
     type = "ssh"
     user = "ubuntu"
     private_key = tls_private_key.public_key_pair.private_key_pem
     host = aws_instance.frontend.public_ip
   }
}
