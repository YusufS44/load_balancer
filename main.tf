#Network
resource "google_compute_network" "home" {
    name = "home"
}


resource "google_compute_instance" "home" {
    name = "home"
    machine_type = "e2-micro"
    zone = "us-central1-a"

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
        }
    }

    network_interface {
        network = google_compute_network.home.id

        access_config {
            // Ephemeral IP
        }
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
        network = google_compute_network.home.id
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