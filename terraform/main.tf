provider "aws" {
  region                  = var.aws_region
  profile                 = var.aws_profile
  shared_credentials_file = "~/.aws/credentials"
}

resource "random_string" "customer_id" {
  length = 4
  special = false
  upper = false
}

data "aws_ami" "automate" {
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
    Name      = "${var.tag_name}_${random_string.customer_id.result}_vpc"
    X-Dept    = var.tag_dept
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }

  enable_dns_hostnames = true
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
    Name      = "${var.tag_name}_${random_string.customer_id.result}_${data.aws_availability_zones.available.names[count.index]}"
    X-Dept    = var.tag_dept
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}

resource "random_shuffle" "rand_subnet" {
  input = aws_subnet.default.*.id
}

resource "random_string" "automate_admin_password" {
  length = 40
  special = true
}

data "template_file" "automate-config" {
  template = file("${path.module}/templates/automate-config.toml")

  vars = {
    automate_fqdn             = "${var.tag_name}-${random_string.customer_id.result}.${var.domain_name}"
    automate_admin_email      = var.automate_admin_email
    automate_admin_username   = var.automate_admin_username
    automate_admin_password   = random_string.automate_admin_password.result
  }
}

resource "aws_instance" "chef_automate" {
  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = var.aws_ssh_user
    private_key = file(var.aws_ssh_key_file)
  }

  ami                         = data.aws_ami.automate.id
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
    Name      = "${var.tag_name}-${random_string.customer_id.result}-automate"
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
    content = templatefile("${path.module}/templates/automate-config.toml",
    {
      automate_fqdn             = "${var.tag_name}-${random_string.customer_id.result}.${var.domain_name}"
      automate_admin_email      = var.automate_admin_email
      automate_admin_username   = var.automate_admin_username
      automate_admin_password   = random_string.automate_admin_password.result
    })
    destination = "/tmp/automate-config.toml"
  }

  provisioner "file" {
    content  = templatefile("${path.module}/templates/automate-install.sh",
    {
      automate_admin_password = random_string.automate_admin_password.result
    })
    destination = "/tmp/automate-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash -ex /tmp/mount_data_volume.sh",
      "sudo bash -ex /tmp/automate-install.sh",
      "sudo /bin/chef-server-ctl user-create chef_infra_admin migration admin nobody@chef.io $(/bin/openssl rand -base64 12) -f /etc/chef-automate/chef_infra_admin.pem",
      "sudo /bin/chef-server-ctl org-create migration migration -a chef_infra_admin -f /etc/chef-automate/migration-validator.pem",
      "sudo /bin/chef-automate iam token create datacollector | sudo tee /etc/chef-automate/dc.tok"
    ]
  }
}

resource "null_resource" "chef-automate-token" {
  provisioner "local-exec" {
    command = "scp -i ${var.aws_ssh_key_file} ${var.aws_ssh_user}@${aws_instance.chef_automate.public_ip}:/etc/chef-automate/dc.tok /tmp/chef-automate-dc.tok"
  }
  depends_on = [aws_instance.chef_automate]
}

data "local_file" "chef-automate-token" {
  filename = "/tmp/chef-automate-dc.tok"
  depends_on = [null_resource.chef-automate-token]
}

# windows ami: ami-053cea4575d27b5d6
# rhel 8: ami-0520e698dd500b1d1

resource "aws_instance" "windows_client" {
  ami                         = "ami-053cea4575d27b5d6"
  instance_type               = "t2.medium"
  key_name                    = var.aws_ssh_key_pair_name
  subnet_id                   = element(aws_subnet.default.*.id, 0)
  vpc_security_group_ids      = [aws_security_group.base_windows.id]
  associate_public_ip_address = true
  get_password_data           = true

  root_block_device {
    delete_on_termination = true
    volume_size           = 30
    volume_type           = "gp2"
  }

  tags = {
    Name      = "${var.tag_name}-${random_string.customer_id.result}-automate"
    X-Dept    = var.tag_dept
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}