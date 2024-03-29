terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "almad-terraform-states"
    key    = "ddcz/state"
    region = "eu-central-1"
  }


provider "aws" {
  region  = "eu-central-1"
}

provider "aws" {
  region = "eu-west-1"
  alias = "heroku_eu_home"
}

provider "aws" {
  region = "us-east-1"
  alias = "global_home"
}

locals {
  internet_cidr = "0.0.0.0/0"
  az            = "eu-central-1b"
  secondary_az  = "eu-central-1a"
  user_uploads_domain = "uploady.dracidoupe.cz"

  heroku_az            = "eu-west-1b"
  heroku_secondary_az  = "eu-west-1a"

}

variable "RDS_PASSWORD" {}

resource "aws_ebs_volume" "ddcz_userdata_backup" {
  availability_zone = local.az
  size              = 1
  type              = "standard"
  tags = {
    "Name"    = "ddcz-userbackup"
    "product" = "ddcz"
  }
}

resource "aws_key_pair" "penpen" {
  key_name   = "penpen"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCEqL1cYHsgiTuo6OdjPhFYzKbxATotj6edn4ISiLDMFnyNtjSJAD83jU//dzR91Q2VkTOeQAW6CTwCFDFZksFeZFAsZOaA/DiidHhF4lHCEcnH8G+L2rBHWW/4kS1754eccGNxawjZbL4UlZHKHWEE7hCwNapFf6HFQwZ0U5bM0dQC0yhfBdVizEkX2dTR9isRBt07Ro3Gicf2sBLOJ6o9N2pkHR05cvzT16AUvgAd9jwACMJjrOsWiaEvyqtODkb42pZ79Tjyy6OZKh+Kc/R6Whfz2CkAm9J5Zn0aB2v0cLorAysqZNa8kLXW8fXLDxCJ027LlGuf0qRJDjApFdCh"
}

resource "aws_vpc" "ddcz_prod" {
  cidr_block           = "192.168.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    "product" = "ddcz"
  }

}

resource "aws_subnet" "ddcz_prod" {
  availability_zone       = local.az
  vpc_id                  = aws_vpc.ddcz_prod.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    "product" = "ddcz"
  }
}

resource "aws_subnet" "ddcz_secondary_az" {
  availability_zone       = local.secondary_az
  vpc_id                  = aws_vpc.ddcz_prod.id
  cidr_block              = "192.168.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    "product" = "ddcz"
  }

}


resource "aws_vpc" "ddcz_prod_heroku" {
  provider = aws.heroku_eu_home
  cidr_block           = "192.168.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    "product" = "ddcz"
  }

}

resource "aws_subnet" "ddcz_prod_heroku" {
  provider = aws.heroku_eu_home
  availability_zone       = local.heroku_az
  vpc_id                  = aws_vpc.ddcz_prod_heroku.id
  cidr_block              = "192.168.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    "product" = "ddcz"
  }
}

resource "aws_subnet" "ddcz_secondary_az_heroku" {
  provider = aws.heroku_eu_home
  availability_zone       = local.heroku_secondary_az
  vpc_id                  = aws_vpc.ddcz_prod_heroku.id
  cidr_block              = "192.168.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    "product" = "ddcz"
  }

}


resource "aws_internet_gateway" "ddcz_prod" {
  vpc_id = aws_vpc.ddcz_prod.id

  tags = {
    "product" = "ddcz"
  }
}

resource "aws_internet_gateway" "ddcz_prod_heroku" {
  provider = aws.heroku_eu_home
  vpc_id = aws_vpc.ddcz_prod_heroku.id

  tags = {
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
  vpc_id     = aws_vpc.ddcz_prod.id
  subnet_ids = [aws_subnet.ddcz_prod.id]

  ingress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = local.internet_cidr
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = local.internet_cidr
    from_port  = 0
    to_port    = 0
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



resource "aws_security_group" "ddcz" {
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

  tags = {
    "product" = "ddcz"
  }

}


resource "aws_route_table" "ddcz_prod_heroku" {
  provider = aws.heroku_eu_home
  vpc_id = aws_vpc.ddcz_prod_heroku.id
  route {
    cidr_block = local.internet_cidr
    gateway_id = aws_internet_gateway.ddcz_prod_heroku.id
  }
  tags = {
    "product" = "ddcz"
  }
}

resource "aws_route_table_association" "ddcz_prod_heroku" {
  provider = aws.heroku_eu_home
  subnet_id      = aws_subnet.ddcz_prod_heroku.id
  route_table_id = aws_route_table.ddcz_prod_heroku.id
}

resource "aws_network_acl" "ddcz_prod_heroku" {
  provider = aws.heroku_eu_home
  vpc_id     = aws_vpc.ddcz_prod_heroku.id
  subnet_ids = [aws_subnet.ddcz_prod_heroku.id]

  ingress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = local.internet_cidr
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "all"
    rule_no    = 100
    action     = "allow"
    cidr_block = local.internet_cidr
    from_port  = 0
    to_port    = 0
  }

  tags = {
    "product" = "ddcz"
  }
}


resource "aws_security_group" "ddcz_heroku" {
  provider = aws.heroku_eu_home

  name        = "sg_ddcz_heroku"
  description = "SG for DDCZ"
  vpc_id      = aws_vpc.ddcz_prod_heroku.id

  ingress {
    description = "RDS  from the world (because Heroku)"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [local.internet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.internet_cidr]
  }

  tags = {
    "product" = "ddcz"
  }

}


resource "aws_db_subnet_group" "ddcz_mysql_heroku" {
  provider = aws.heroku_eu_home
  name        = "ddcz-mysql-subnet"
  description = "RDS subnet group"
  subnet_ids  = [aws_subnet.ddcz_prod_heroku.id, aws_subnet.ddcz_secondary_az_heroku.id]
}

resource "aws_db_instance" "mysql_heroku" {
  provider = aws.heroku_eu_home


  availability_zone         = local.heroku_az
  allocated_storage         = 5
  engine                    = "mysql"
  engine_version            = "5.7.34"
  instance_class            = "db.t3.micro"
  identifier                = "ddcz-mysql"
  name                      = "dracidoupe_cz"
  username                  = "root"
  password                  = var.RDS_PASSWORD
  parameter_group_name      = "default.mysql5.7"
  skip_final_snapshot       = true
  final_snapshot_identifier = "ddcz-heroku-mysql-snap"
  deletion_protection = true

  multi_az = "false"

  db_subnet_group_name   = aws_db_subnet_group.ddcz_mysql_heroku.name
  vpc_security_group_ids = [aws_security_group.ddcz_heroku.id]

  storage_type        = "standard"
  publicly_accessible = "true"

  tags = {
    "product" = "ddcz"
  }
}

resource "aws_s3_bucket" "ddcz_uploads_bucket" {
  bucket = "uploady.dracidoupe.cz"
  acl    = "public-read"

  tags = {
    "product" = "ddcz"
  }
}


resource "aws_eip" "ddcz" {
  instance   = aws_instance.ddcz.id
  vpc        = true
  depends_on = [aws_internet_gateway.ddcz_prod, aws_instance.ddcz]
}

resource "aws_instance" "ddcz" {
  ami                     = "ami-041855a8b7934ebae"
  instance_type           = "t2.nano"
  disable_api_termination = "true"
  key_name                = aws_key_pair.penpen.key_name
  availability_zone       = local.az

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ddcz.id]
  subnet_id                   = aws_subnet.ddcz_prod.id

  root_block_device {
    volume_type           = "standard"
    volume_size           = 4
    delete_on_termination = true
  }


  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/aws-penpen.pem")
    host        = self.public_ip
  }

  #  user_data = file("setup.sh")

  provisioner "file" {
    source      = "etc/services/run"
    destination = "/etc/service/dracidoupe.cz/run"
  }

  provisioner "file" {
    source      = "etc/lighttpd.conf"
    destination = "/etc/lighttpd/lighttpd.conf"
  }

  provisioner "file" {
    source      = "dbcore.php"
    destination = "/var/www/dracidoupe.cz/www_root/www/htdocs/dbcore.php"
  }

  #   provisioner "file" {
  #     source      = "etc/modules/custom-access-log"
  #     destination = "/etc/lighttpd/modules/custom-access-log"
  #   }

  #   provisioner "file" {
  #     source      = "etc/modules/fcgi-socket-php"
  #     destination = "/etc/lighttpd/modules/fcgi-socket-php"
  #   }

  #   provisioner "file" {
  #     source      = "etc/sites/dracidoupe.cz"
  #     destination = "/etc/lighttpd/sites/dracidoupe.cz"
  #   }

  tags = {
    "product" = "ddcz"
  }

  volume_tags = {
    "Name"    = "ddcz-userbackup"
    "product" = "ddcz"
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
  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.ddcz_userdata_backup.id
  instance_id  = aws_instance.ddcz.id
  skip_destroy = true
}

resource "aws_acm_certificate" "ddcz_certificate" {
  domain_name       = local.user_uploads_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  // certificate MUST be located in us-east-1 in order to be used for global
  // services, like CloudFront
  provider = aws.global_home

  # subject_alternative_names = ["dracidoupe.cz"]
}

resource "aws_cloudfront_distribution" "s3_ddcz_uploads_dist" {
  origin {
    # domain_name = "${aws_s3_bucket.www.website_endpoint}"
    domain_name = aws_s3_bucket.ddcz_uploads_bucket.bucket_regional_domain_name
    origin_id   = "ddcz_uploads_origin"
  }
  enabled         = true
  is_ipv6_enabled = true
  default_root_object = "index.html"
  price_class = "PriceClass_100"
  # description = "HTTPS termination point for user-uploaded content on DDCZ"

  aliases = [local.user_uploads_domain]


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ddcz_uploads_origin"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 864000
  }

  ordered_cache_behavior {
    path_pattern     = "/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ddcz_uploads_origin"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.ddcz_certificate.arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    "product" = "ddcz"
  }


}
