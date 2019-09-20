output "automate_fqdn" {
  value = var.automate_fqdn != "" ? var.automate_fqdn : aws_alb.automate_lb.dns_name
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
