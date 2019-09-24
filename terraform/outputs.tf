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
output "windows_client_password" {
  value = "${rsadecrypt(aws_instance.windows_client.password_data,file(var.aws_ssh_key_file))}"
}

output "LINUX_curl-bash" {
  value = "curl https://raw.githubusercontent.com/stephenlauck/chef-repo/master/bootstrap.sh | sudo bash -s ${random_string.customer_id.result} ${data.local_file.chef-automate-token.content}"
}

output "WINDOWS_Invoke-Command" {
  value = "Invoke-Command -ScriptBlock ([scriptBlock]::Create((New-Object System.Net.WebClient).DownloadString(' https://raw.githubusercontent.com/stephenlauck/chef-repo/master/bootstrap.ps1'))) -ArgumentList '${random_string.customer_id.result}','${data.local_file.chef-automate-token.content}'"
}
