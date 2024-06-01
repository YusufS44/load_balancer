variable project {
    default = "project-id"
}

variable region {
    default = "us-central1"
}

variable credentials {
    default = "your-key.json"
}

variable zone {
    default = "us-central1-a"
}

variable subnet_ip_range {
    default = "10.231.1.0/24"
}

variable network_name {
    default = "home-network"
}

variable subnet_name {
    default = "home-subnet"
}

variable instance_count {
    default = 1
  
}

variable machine_type {
   default = "e2-micro"
}

variable image {
    default = "debian-cloud/debian-11"
}