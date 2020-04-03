provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

locals {
  vpc_id    = "..."
  subnet_id = "..."
}

resource "aws_ebs_volume" "ddcz_code" {
  availability_zone = "us-east-1a"
  size              = 3
  type              = "standard"
  tags              = {
      "Name" = "ddcz-code"
      "product" = "ddcz"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.ddcz_code.id
  instance_id = aws_instance.ddcz.id
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

  tags              = {
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
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from the world"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags              = {
      "product" = "ddcz"
  }

}

resource "aws_instance" "ddcz" {
  ami           = "ami-80e915e9"
  instance_type = "t1.micro"
#   security_groups = [
#       "sg_ddcz",
#   ]

  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.sg_ddcz.id]
  subnet_id              = aws_subnet.ddcz_prod.id

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/aws-penpen.pem")
    host        = self.public_ip
  }

  tags              = {
      "product" = "ddcz"
  }

  provisioner "remote-exec" {
    inline = [
        "mkdir /var/www",
        "mount /dev/xvdf1 /var/www",
        "sudo echo 'deb http://archive.debian.org/debian squeeze main' > /etc/apt/sources.list'",
        "sudo echo 'deb http://archive.debian.org/debian squeeze-lts main' >> /etc/apt/sources.list",
        "sudo echo 'Acquire::Check-Valid-Until false;' > /etc/apt/apt.conf",
        "sudo apt-get update",
        "sudo apt-get -y --force-yes -q install lighttpd php5-cgi php5-cli php5-curl php5-imagick php5-mysql daemontools daemontools-run procps spawn-fcgi",
        "groupadd w-dracidoupe-cz",
        "useradd w-dracidoupe-cz -g w-dracidoupe-cz",
        "groupadd wwwserver",
        "useradd lighttpd -g www-data -g wwwserver",
        "mkdir /etc/service/dracidoupe.cz",
        "mkdir -p /var/www/dracidoupe.cz/www_root/www/php/",
        "mkdir -p /var/www/fastcgi/sockets/w-dracidoupe-cz/",
        "chown -R w-dracidoupe-cz:wwwserver /var/www/fastcgi/sockets/w-dracidoupe-cz/",
    ]
  }
}
