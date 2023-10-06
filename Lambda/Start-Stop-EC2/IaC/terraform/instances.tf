# Create EC2 instances
resource "aws_instance" "prod" {
  count         = 2
  ami           = "ami-067d1e60475437da2" //Amazon Linux 2023 AMI
  instance_type = "t2.micro"
  key_name      = "lambda"
  tags = {
    Name = "Prod Instance ${count.index + 1}"
    env  = "prod"
  }
  vpc_security_group_ids = [aws_security_group.instances.id]
}

resource "aws_instance" "test" {
  count         = 2 
  ami           = "ami-067d1e60475437da2" //Amazon Linux 2023 AMI
  instance_type = "t2.micro"
  key_name      = "lambda"
  tags = {
    Name = "Test Instance ${count.index + 1}"
    env  = "test" 
  }
  vpc_security_group_ids = [aws_security_group.instances.id]
}
