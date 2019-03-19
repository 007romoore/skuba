variable "image_name" {
  default     = "openSUSE-Leap-15.0-OpenStack.x86_64"
  description = "Name of the image to use"
}

variable "internal_net" {
  default = ""
  description = "Name of the internal network to be created"
}

variable "external_net" {
  default = "floating"
  description = "Name of the external network to be used, the one used to allocate floating IPs"
}

variable "master_size" {
  default = "m1.medium"
  description = "Size of the master nodes"
}

variable "masters" {
  default = 1
  description = "Number of master nodes"
}

variable "worker_size" {
  default = "m1.medium"
  description = "Size of the worker nodes"
}

variable "workers" {
  default = 1
  description = "Number of worker nodes"
}

variable "workers_vol_enabled" {
  default = 0
  description = "Attach persistent volumes to workers"
}

variable "workers_vol_size" {
  default = 5
  description = "size of the volumes in GB"
}

variable "dnsdomain" {
  default = "testing.qa.caasp.suse.net"
  description = "TBD - leftover?"
}

variable "dnsentry" {
  default = 0
  description = "TBD - leftover?"
}

variable "stack_name" {
  default = ""
  description = "identifier to make all your resources unique and avoid clashes with other users of this terraform project"
}

variable "authorized_keys" {
  type = "list"
  default = []
  description = "ssh keys to inject into all the nodes"
}
