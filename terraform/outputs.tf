output "automate_fqdn" {
  value = "${var.tag_name}-${random_string.customer_id.result}.${var.domain_name}"
}

output "automate_admin_password" {
  value = random_string.automate_admin_password.result
}

output "automate_ssh" {
  value = formatlist(
    "ssh -i %s %s@%s",
    var.aws_ssh_key_file,
    var.aws_ssh_user,
    aws_instance.chef_automate.*.public_ip,
  )
}

output "validation_pem" {
  value = tls_private_key.chef-infra-validator.private_key_pem
}