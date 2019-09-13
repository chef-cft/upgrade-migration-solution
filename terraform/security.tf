resource "aws_security_group" "base_linux" {
  name        = "base_linux_${random_id.random.hex}"
  description = "base security rules for all linux nodes"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name      = "${var.tag_dept}-${var.tag_project}_${random_id.random.hex}_security_group"
    X-Dept    = var.tag_dept
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}

resource "aws_security_group" "chef_automate" {
  name        = "chef_automate_${random_id.random.hex}"
  description = "Chef Automate Server"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name      = "${var.tag_dept}-${var.tag_project}_${random_id.random.hex}_security_group"
    X-Dept    = var.tag_dept
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}

//////////////////////////
// Base Linux Rules
resource "aws_security_group_rule" "ingress_allow_22_tcp_all" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.base_linux.id
}

////////////////////////////////
// Chef Automate Rules
# HTTP (nginx)
resource "aws_security_group_rule" "ingress_chef_automate_allow_80_tcp" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.chef_automate.id
}

# HTTPS (nginx)
resource "aws_security_group_rule" "ingress_chef_automate_allow_443_tcp" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.chef_automate.id
}

# Egress: ALL
resource "aws_security_group_rule" "linux_egress_allow_0-65535_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.base_linux.id
}
