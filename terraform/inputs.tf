variable automate_admin_username {
  default = "admin"
}

variable automate_admin_email {
  default = "admin@chef.io"
}

variable "automate_server_instance_type" {
  default = "m5.large"
}

variable "aws_profile" {
  default     = "default"
  description = "The AWS profile to use from your ~/.aws/credentials file."
}

variable "aws_region" {
  default     = "us-west-2"
  description = "The name of the selected AWS region / datacenter."
}

variable "aws_ssh_key_file" {
}

variable "aws_ssh_key_pair_name" {
}

variable "aws_ssh_user" {
  default = "centos"
}

variable "tag_contact" {
}

variable "tag_dept" {
}

variable "tag_name" {
  default = "migration"
}

variable "tag_project" {
}

variable "domain_name" {
}