provider "aws" {
    version = "~> 2.0"
    region = "us-east-1"
}

locals {
  jenkins_default_name = "jenkins"
  jenkins_home = "/home/ubuntu/jenkins_home"
  jenkins_home_mount = "${local.jenkins_home}:/var/jenkins_home"
  docker_sock_mount = "/var/run/docker.sock:/var/run/docker.sock"
  java_opts = "JAVA_OPTS='-Djenkins.install.runSetupWizard=false'"
}



##################################################################
#  Jenkins agent
##################################################################
resource "aws_instance" "jenkins_agent" {
  ami = "ami-09d069a04349dc3cb"
  instance_type = "t2.micro"
  key_name = aws_key_pair.Project_key.key_name
  subnet_id = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.nat.id}"]

  tags = {
    Name = "Project Jenkins Agent"
  }
}


##################################################################
#  Jenkins master
##################################################################


resource "aws_instance" "jenkins_master" {
  ami = "ami-07d0cf3af28718ef8"
  instance_type = "t3.micro"
  key_name = aws_key_pair.Project_key.key_name
  subnet_id = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.nat.id}"]

  tags = {
    Name = "Project Jenkins Master"
  }

  connection {
    host = aws_instance.jenkins_master.public_ip
    user = "ubuntu"
    private_key = file("Project_key")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt install docker.io -y",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ubuntu",
      "mkdir -p ${local.jenkins_home}",
      "sudo chown -R 1000:1000 ${local.jenkins_home}"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo docker run -d -p 8080:8080 -p 5000:5000 -v ${local.jenkins_home_mount} -v ${local.docker_sock_mount} --env ${local.java_opts} jenkins/jenkins"
    ]
  }
}
resource "aws_eip" "web-1" {
    instance = "${aws_instance.jenkins_master.id}"
    vpc = true
}
resource "aws_eip" "web-2" {
    instance = "${aws_instance.jenkins_agent.id}"
    vpc = true
}
