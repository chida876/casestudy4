provider "aws" {
  region = "ap-south-1"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# Create Subnets in three different availability zones
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
}

resource "aws_subnet" "subnet3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1c"
}

# Create S3 Bucket
resource "aws_s3_bucket" "shared_storage_871996" {
  bucket = "shared-storage-bucket-${timestamp()}"
}

resource "aws_s3_bucket_acl" "shared_storage_acl" {
  bucket = aws_s3_bucket.shared_storage.bucket
  acl    = "private"
}

# EC2 Instances
resource "aws_instance" "ec2_instance" {
  count = 3

  ami           = "ami-007020fd9c84e18c7"
  instance_type = "t2.micro"
  subnet_id     = element(aws_subnet.subnet1.*.id, count.index % 3)
  key_name      = "springboot-1"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              echo 'docker run -v /mnt/s3:/data -d -p 80:80 nginx' >> /etc/rc.local
              mkdir /mnt/s3
              mount -t fuse.s3fs ${aws_s3_bucket.shared_storage.bucket} /mnt/s3 -o passwd_file=/etc/passwd-s3fs -o url=https://s3.amazonaws.com -o allow_other
              EOF

  tags = {
    Name = "ec2-instance-${count.index}"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.shared_storage.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:*",
        Resource  = [aws_s3_bucket.shared_storage.arn, "${aws_s3_bucket.shared_storage.arn}/*"],
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = "*"
          }
        }
      }
    ]
  })
}
