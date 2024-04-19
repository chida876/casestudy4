provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-1b"
}

resource "aws_subnet" "subnet3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-1c"
}

resource "aws_s3_bucket" "shared_storage" {
  bucket = "shared-storage-bucket"
  acl    = "private"
}

resource "aws_instance" "ec2_instance" {
  count = 3

  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = "your-key-name"
  subnet_id     = count.index == 0 ? aws_subnet.subnet1.id : count.index == 1 ? aws_subnet.subnet2.id : aws_subnet.subnet3.id

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              echo "shared-storage-bucket:/ /mnt/shared_storage s3fs _netdev,iam_role,allow_other 0 0" >> /etc/fstab
              mkdir /mnt/shared_storage
              mount -a
              EOF

  tags = {
    Name = "EC2_Instance_${count.index}"
  }
}
