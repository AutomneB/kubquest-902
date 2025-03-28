variable "ssh_key_path" {
  description = "Path to the SSH key"
  type        = string
  default     = "../ssh-key"
}

variable "ansible_playbook_file" {
  description = "Path to the Ansible playbook file"
  type        = string
  default     = "../ansible/templates/playbook-kubernetes-basic.yml"
}

variable "ansible_port" {
  description = "Ansible SSH port"
  type        = string
  default     = "22"
}

variable "instance_username" {
  type        = string
  default     = "adminuser"
}