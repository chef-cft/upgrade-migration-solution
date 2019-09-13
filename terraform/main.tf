provider "aws" {
  region                  = var.aws_region
  profile                 = var.aws_profile
  shared_credentials_file = "~/.aws/credentials"
}

resource "random_id" "random" {
  byte_length = 4
}

data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "name"
    values = ["aws-native-chef-server-5*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["446539779517"]
}

data "aws_availability_zones" "available" {
}

resource "aws_vpc" "default" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name      = "${var.tag_name}_${random_id.random.hex}_vpc"
    X-Dept    = var.tag_dept
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }

  enable_classiclink_dns_support = true
  enable_dns_hostnames           = true
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_subnet" "default" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.default.id
  cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.tag_name}_${random_id.random.hex}_${data.aws_availability_zones.available.names[count.index]}"
    X-Dept    = var.tag_dept
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}

resource "random_shuffle" "rand_subnet" {
  input = aws_subnet.default.*.id
}

# TODO
# - self-repairing alarm
# - install Automate
data "template_file" "automate-config" {
  template = file("${path.module}/templates/automate-config.toml")

  vars = {
    automate_fqdn             = coalesce(var.automate_fqdn, aws_alb.automate_lb.dns_name)
    automate_admin_email      = var.automate_admin_email
    automate_admin_username   = var.automate_admin_username
    automate_admin_password   = var.automate_admin_password
    automate_dc_token         = var.automate_dc_token
  }
}

data "template_file" "automate-install" {
  template = file("${path.module}/templates/automate-install.sh")

  vars = {
    automate_admin_password = var.automate_admin_password
  }
}

resource "aws_instance" "chef_automate" {
  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = var.aws_ssh_user
    private_key = file(var.aws_ssh_key_file)
  }

  ami                         = data.aws_ami.centos.id
  instance_type               = var.automate_server_instance_type
  key_name                    = var.aws_ssh_key_pair_name
  subnet_id                   = element(aws_subnet.default.*.id, 0)
  vpc_security_group_ids      = [aws_security_group.base_linux.id, aws_security_group.chef_automate.id]
  associate_public_ip_address = true
  ebs_optimized               = true

  root_block_device {
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp2"
  }

  ebs_block_device {
    device_name           = "/dev/sdb"
    delete_on_termination = false
    volume_size           = 20
    volume_type           = "gp2"
  }

  tags = {
    Name      = "${var.tag_name}-${random_id.random.hex}-automate"
    X-Dept    = var.tag_dept
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }

  # mount the EBS volume
  provisioner "file" {
    source      = "${path.module}/mount_data_volume.sh"
    destination = "/tmp/mount_data_volume.sh"
  }

  provisioner "file" {
    content      = data.template_file.automate-config.rendered
    destination = "/tmp/automate-config.toml"
  }

  provisioner "file" {
    content      = data.template_file.automate-install.rendered
    destination = "/tmp/automate-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash -ex /tmp/mount_data_volume.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash -ex /tmp/automate-install.sh",
    ]
  }
}

