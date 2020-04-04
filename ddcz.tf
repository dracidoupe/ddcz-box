provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  
}

locals {
    internet_cidr = "0.0.0.0/0"
}

resource "aws_ebs_volume" "ddcz_code" {
  availability_zone = "us-east-1a"
  size              = 3
  type              = "standard"
  skip_destroy      = true
  tags              = {
      "Name" = "ddcz-code"
      "product" = "ddcz"
  }
}

resource "aws_key_pair" "penpen" {
  key_name   = "penpen"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCEqL1cYHsgiTuo6OdjPhFYzKbxATotj6edn4ISiLDMFnyNtjSJAD83jU//dzR91Q2VkTOeQAW6CTwCFDFZksFeZFAsZOaA/DiidHhF4lHCEcnH8G+L2rBHWW/4kS1754eccGNxawjZbL4UlZHKHWEE7hCwNapFf6HFQwZ0U5bM0dQC0yhfBdVizEkX2dTR9isRBt07Ro3Gicf2sBLOJ6o9N2pkHR05cvzT16AUvgAd9jwACMJjrOsWiaEvyqtODkb42pZ79Tjyy6OZKh+Kc/R6Whfz2CkAm9J5Zn0aB2v0cLorAysqZNa8kLXW8fXLDxCJ027LlGuf0qRJDjApFdCh"
}

resource "aws_vpc" "ddcz_prod" {
  cidr_block = "192.168.0.0/16"

  tags              = {
      "product" = "ddcz"
  }

}

resource "aws_subnet" "ddcz_prod" {
  vpc_id     = aws_vpc.ddcz_prod.id
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = true

  tags              = {
      "product" = "ddcz"
  }

}

resource "aws_internet_gateway" "ddcz_prod" {
  vpc_id = aws_vpc.ddcz_prod.id

  tags              = {
      "product" = "ddcz"
  }
}

resource "aws_route_table" "ddcz_prod" {
 vpc_id = aws_vpc.ddcz_prod.id
 route {
    cidr_block = local.internet_cidr
    gateway_id = aws_internet_gateway.ddcz_prod.id
 }
 tags = {
      "product" = "ddcz"
 }
}
resource "aws_route_table_association" "ddcz_prod" {
  subnet_id      = aws_subnet.ddcz_prod.id
  route_table_id = aws_route_table.ddcz_prod.id
}

resource "aws_network_acl" "ddcz_prod" {
  vpc_id = aws_vpc.ddcz_prod.id
  subnet_ids = [ aws_subnet.ddcz_prod.id ]

  ingress {
      protocol = "all"
      rule_no = 100
      action = "allow"
      cidr_block = local.internet_cidr
      from_port = 0
      to_port = 0
  }

  egress {
      protocol = "all"
      rule_no = 100
      action = "allow"
      cidr_block = local.internet_cidr
      from_port = 0
      to_port = 0
  }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = local.internet_cidr
#     from_port  = 22
#     to_port    = 22
#   }
  
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = local.internet_cidr
#     from_port  = 80
#     to_port    = 80
#   }
  
#   egress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = local.internet_cidr
#     from_port  = 22 
#     to_port    = 22
#   }
  
#   egress {
#     protocol   = "tcp"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = local.internet_cidr
#     from_port  = 80  
#     to_port    = 80 
#   }
 
   tags = {
    "product" = "ddcz"
   }
}

resource "aws_security_group" "sg_ddcz" {
  name        = "sg_ddcz"
  description = "SG for DDCZ"
  vpc_id      = aws_vpc.ddcz_prod.id

  ingress {
    description = "SSH from the world"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.internet_cidr]
  }

  ingress {
    description = "HTTP from the world"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.internet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.internet_cidr]
  }

  tags              = {
      "product" = "ddcz"
  }

}

resource "aws_instance" "ddcz" {
  ami           = "ami-80e915e9"
  instance_type = "t1.micro"
  key_name      = aws_key_pair.penpen.key_name
#   security_groups = [
#       "sg_ddcz",
#   ]

  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.sg_ddcz.id]
  subnet_id              = aws_subnet.ddcz_prod.id

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/aws-penpen.pem")
    host        = self.public_ip
  }
  
  user_data = file("setup.sh")
  
  tags              = {
      "product" = "ddcz"
  }

  provisioner "file" {
    source      = "etc/services/run"
    destination = "/etc/service/dracidoupe.cz/run"
  }

  provisioner "file" {
    source      = "etc/lighttpd.conf"
    destination = "/etc/lighttpd/lighttpd.conf"
  }

  provisioner "file" {
    source      = "etc/modules/custom-access-log"
    destination = "/etc/lighttpd/modules/custom-access-log"
  }

  provisioner "file" {
    source      = "etc/modules/fcgi-socket-php"
    destination = "/etc/lighttpd/modules/fcgi-socket-php"
  }

  provisioner "file" {
    source      = "etc/sites/dracidoupe.cz"
    destination = "/etc/lighttpd/sites/dracidoupe.cz"
  }


#   provisioner "remote-exec" {
#     inline = [
#         "mkdir /var/www",
#         "mount -t ext4 /dev/xvdf1 /var/www",
#         "sudo echo 'deb http://archive.debian.org/debian squeeze main' > /etc/apt/sources.list'",
#         "sudo echo 'deb http://archive.debian.org/debian squeeze-lts main' >> /etc/apt/sources.list",
#         "sudo echo 'Acquire::Check-Valid-Until false;' > /etc/apt/apt.conf",
#         "sudo apt-get update",
#         "sudo apt-get -y --force-yes -q install lighttpd php5-cgi php5-cli php5-curl php5-imagick php5-mysql daemontools daemontools-run procps spawn-fcgi",
#         "groupadd w-dracidoupe-cz",
#         "useradd w-dracidoupe-cz -g w-dracidoupe-cz",
#         "groupadd wwwserver",
#         "useradd lighttpd -g www-data -g wwwserver",
#         "mkdir /etc/service/dracidoupe.cz",
#         "mkdir -p /var/www/dracidoupe.cz/www_root/www/php/",
#         "mkdir -p /var/www/fastcgi/sockets/w-dracidoupe-cz/",
#         "chown -R w-dracidoupe-cz:wwwserver /var/www/fastcgi/sockets/w-dracidoupe-cz/",
#     ]
#   }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.ddcz_code.id
  instance_id = aws_instance.ddcz.id
}
