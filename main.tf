#Network
resource "google_compute_network" "home-network" {
    name = var.network_name
    auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "home-subnet" {
    name            = var.subnet_name
    ip_cidr_range   = var.subnet_ip_range
    region          = var.region
    network         = google_compute_network.home-network.id
}

resource "google_compute_address" "static_ip" {
  count = var.instance_count
  name = "static-ip"
  address_type = "EXTERNAL"
  depends_on = [ google_compute_network.home-network ]
}

#Instance
resource "google_compute_instance" "home" {
    name = "home"
    machine_type = var.machine_type
    zone = var.zone

    boot_disk {
        initialize_params {
            image = var.image
        }
    }

    network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name
    access_config {
    nat_ip = google_compute_address.static_ip[0].address
    }
  }

  tags = ["allow-ssh-http-tcp-icmp"]

    metadata = {
    startup-script = "#Thanks to Remo\n#!/bin/bash\n# Update and install Apache2\napt update\napt install -y apache2\n\n# Start and enable Apache2\nsystemctl start apache2\nsystemctl enable apache2\n\n# GCP Metadata server base URL and header\nMETADATA_URL=\"http://metadata.google.internal/computeMetadata/v1\"\nMETADATA_FLAVOR_HEADER=\"Metadata-Flavor: Google\"\n\n# Use curl to fetch instance metadata\nlocal_ipv4=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/network-interfaces/0/ip\")\nzone=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/zone\")\nproject_id=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/project/project-id\")\nnetwork_tags=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/tags\")\n\n# Create a simple HTML page and include instance details\ncat <<EOF > /var/www/html/index.html\n<html lang=\"en\">\n<head>\n    <meta charset=\"UTF-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    <title>Kar Vastor Video</title>\n    <style>\n        body {\n            background-color: black;\n            color: white;\n            font-family: Arial, sans-serif;\n            display: flex;\n            justify-content: center;\n            align-items: center;\n            height: 100vh;\n            margin: 0;\n        }\n        header {\n            position: absolute;\n            top: 0;\n            width: 100%;\n            text-align: center;\n            font-size: 2em;\n            padding: 20px 0;\n        }\n        iframe {\n            border: none;\n        }\n    </style>\n</head>\n<body>\n    <header>Kar Vastor</header>\n    <iframe width=\"560\" height=\"315\" src=\"https://www.youtube.com/embed/cIQAWvkSj0g?si=q8mkabsoUt5ATKlS\" title=\"YouTube video player\" allow=\"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share\" allowfullscreen></iframe>\n</body>\n</html>\nEOF"
  }
}

resource "google_compute_global_address" "home-ip" {
  name = "home-ip"
}

resource "google_compute_instance_template" "home-be" {
    name = "home-be"
    machine_type = "e2-micro"
    disk {
        source_image = "debian-cloud/debian-11"
    }
    network_interface {
        network = google_compute_network.home-network.id
        subnetwork = google_compute_subnetwork.home-subnet.id
    }
    metadata_startup_script = "apt-get update && apt-get install -y apache2 && service apache2 start"
}

resource "google_compute_instance_group_manager" "home-be" {
    name = "home-be"
    base_instance_name = "home-be"
    zone = "us-central1-a"
    timeouts {
        create = "10m"
        update = "10m"
        delete = "10m"
    }
    target_size = 1
    named_port {
        name = "http"
        port = 80
    }
    version {
        instance_template = google_compute_instance_template.home-be.self_link
    }
}

resource "google_compute_backend_service" "home-be" {
    name = "home-be"
    protocol = "HTTP"
    timeout_sec = 10
    load_balancing_scheme = "EXTERNAL"
    backend {
        group = google_compute_instance_group_manager.home-be.instance_group
    }

    health_checks = [google_compute_health_check.home.self_link]
}

resource "google_compute_health_check" "home" {
    name = "home"
    check_interval_sec = 1
    timeout_sec = 1
    healthy_threshold = 2
    unhealthy_threshold = 2
    http_health_check {
        request_path = "/"
    }
}

resource "google_compute_http_health_check" "home" {
    name = "home"
    request_path = "/"
}

resource "google_compute_url_map" "home" {
    name = "home"
    default_service = google_compute_backend_service.home-be.self_link
    host_rule {
        hosts = ["*"]
        path_matcher = "allpaths"
    }

    path_matcher {
        name = "allpaths"
        default_service = google_compute_backend_service.home-be.self_link
        path_rule {
            paths = ["/*"]
            service = google_compute_backend_service.home-be.self_link
        }
    }
}

resource "google_compute_target_http_proxy" "home" {
    name = "home"
    url_map = google_compute_url_map.home.self_link
}

resource "google_compute_global_forwarding_rule" "home" {
    name = "home"
    target = google_compute_target_http_proxy.home.self_link
    ip_protocol = "TCP"
    port_range = "80"
    ip_address = google_compute_global_address.home-ip.address
}