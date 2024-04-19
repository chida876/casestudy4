provider "aws" {
  region = "ap-south-1"
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create subnets in different availability zones
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
}

resource "aws_subnet" "subnet3" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-south-1b"
}

# Create an S3 bucket
resource "aws_s3_bucket" "my_shared_bucket" {
  bucket = "my-shared-bucket-876"
}

# EC2 instances
resource "aws_instance" "ec2_instance" {
  count = 3

  ami           = "ami-007020fd9c84e18c7" # Ubuntu 20.04 LTS
  instance_type = "t2.micro"
  key_name      = "keypair"
  iam_instance_profile = "s3_access_role" # Replace with your IAM role name
  
  subnet_id = count.index == 0 ? aws_subnet.subnet1.id : count.index == 1 ? aws_subnet.subnet2.id : aws_subnet.subnet3.id

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo apt-get install -y s3fs
              echo 'AKIA4MTWNVEBOUIVGVZY
:73IChEeRvoyeqxkN/3pYQe8kYicYjzavLghdQaBt' > /home/ubuntu/.passwd-s3fs
              chmod 600 /home/ubuntu/.passwd-s3fs
              sudo mkdir /mnt/my_shared_bucket
              sudo s3fs ${aws_s3_bucket.my_shared_bucket.bucket} /mnt/my_shared_bucket -o passwd_file=/home/ubuntu/.passwd-s3fs -o url=https://s3.amazonaws.com -o use_path_request_style
              EOF
}
