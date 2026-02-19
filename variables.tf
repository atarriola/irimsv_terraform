variable "hostinger_api_token" {
  description = "Hostinger API token (read from env via TF_VAR_hostinger_api_token)"
  type        = string
  sensitive   = true
}

variable "vps_plan" {
  description = "VPS plan code (see Hostinger provider docs/data sources)"
  type        = string
}

variable "data_center_id" {
  description = "Target data center ID"
  type        = number
}

variable "template_id" {
  description = "OS template ID (Ubuntu 22.04/24.04 or Debian 12/13 recommended)"
  type        = number
}

variable "hostname" {
  description = "Optional hostname/FQDN"
  type        = string
  default     = null
}

variable "ssh_key_name" {
  description = "Name for the SSH public key in Hostinger"
  type        = string
  default     = "irmvps-key"
}

variable "ssh_public_key" {
  description = "Your SSH public key string (ssh-ed25519 ... or ssh-rsa ...)"
  type        = string
}
