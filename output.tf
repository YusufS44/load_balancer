output "region" {
  value       = var.region
  description = "The region in which resources are created."
}

output "zone" {
  value       = var.zone
  description = "The zone in which resources are created."
}

output "subnet_cidr" {
  value       = var.subnet_ip_range
  description = "The CIDR block for the subnet."
}

output "machine_type" {
  value       = var.machine_type
  description = "The machine type for the instance."
}

output "image" {
  value       = var.image
  description = "The image from which the instance is created."
}

output "vpc_name" {
  value       = google_compute_network.home-network.name
  description = "The name of the VPC network."
}

output "subnet_name" {
  value       = google_compute_subnetwork.home-subnet.name
  description = "The name of the subnet."
}

output "static_ip_names" {
  value       = google_compute_address.static_ip[*].name
  description = "The names of the static IP addresses."
}

output "static_ip_addresses" {
  value       = [for i in google_compute_address.static_ip : i.address]
  description = "The static IP addresses."
}

output "instance_names" {
  value       = google_compute_instance.home[*].name
  description = "The names of the VM instances."
}

output "instance_external_ips" {
  value       = google_compute_instance.home[*].network_interface[0].access_config[0].nat_ip
  description = "The external IP addresses of the VM instances."
}