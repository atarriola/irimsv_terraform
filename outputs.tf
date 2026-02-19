output "ssh_command" {
  description = "SSH command once the VPS is up"
  value       = "ssh root@${hostinger_vps.this.76.13.23.174}"
}
