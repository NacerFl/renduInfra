terraform {
  # This module is now only being tested with Terraform 1.0.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 1.0.x code.
  required_version = ">= 0.12.26"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.43.0"
    }

     kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.16"
    }

    grafana = {
      source  = "grafana/grafana"
      version = "1.24.0"
    }   

  }
}


# ---------------------------------------------------------------------------------------------------------------------
# PREPARE PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------


variable "project_id" {
  description = "testinfra-357317"//renduterra
}

variable "region" {
  description = "us-central1"
}

provider "google" { 
  project = var.project_id
  region  = var.region
}


#Ressource Grafana

provider "grafana" {
  alias         = "firstnewinfra"

    url = "REPLACE"
     auth = "REPLACE==" 

}



resource "grafana_folder" "my_folderinfra" {
  provider = grafana.firstnewinfra

  title = "TestNewversion"
}

resource "grafana_dashboard" "metricsinfra" {
    provider = grafana.firstnewinfra
    folder = grafana_folder.my_folderinfra.id
  config_json = file("grafana-dashboardinfra.json")
}



# ---------------------------------------------------------------------------------------------------------------------
# VPC
# ------------


# VPC
resource "google_compute_network" "vpc" {
  name                    = "mynetwork4"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A PRIVATE CLUSTER IN GOOGLE CLOUD PLATFORM
# ------------


    variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 1 #<= 3 Node
  description = "number of gke nodes"
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.region
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
}

 #Separately Managed Node Pool
 resource "google_container_node_pool" "primary_nodes" {
   name       = "${google_container_cluster.primary.name}-node-pool"
   location   = var.region
   cluster    = google_container_cluster.primary.name
   node_count = var.gke_num_nodes

   node_config {

     labels = {
       env = var.project_id
     }

     # preemptible  = true
     machine_type = "n1-standard-1"
     tags         = ["gke-node", "${var.project_id}-gke"]
     metadata = {
       disable-legacy-endpoints = "true"
    }
   }
 }


# --------------------------

data "google_client_config" "default" {
}


provider "kubernetes" {
   host                   = "https://${google_container_cluster.primary.endpoint}"
 // token                  = "${data.google_client_config.current.access_token}"
 token = data.google_client_config.default.access_token
 
  client_certificate     = "${base64decode(google_container_cluster.primary.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.primary.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
}

 resource "kubernetes_service" "nginx" {
   metadata {
     name = "scalable-nginx-example"
 }
   spec {
      selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
     port        = 80
      target_port = 80
       protocol    = "TCP"
     }
     type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "scalable-nginx-example"
    labels = {
      App = "ScalableNginxExample"
    }
  }

  spec {
    selector {
      match_labels = {
        App = "ScalableNginxExample"
      }
         
    }
    template {
      metadata {
        labels = {
          App = "ScalableNginxExample"
        }
      }
      spec {
        container {
          image = "mobius0/customnginx:latest"
          name  = "example"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "grafana_service" {
  metadata {
    name = "grafana"
  }
  spec {
    selector = {
      name = "grafana"
    }
    port {
      port = 3000
      protocol = "TCP"
      target_port = 3000
    }
    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "grafana" {
  metadata {
    name = "grafana"
    labels = {
      name = "grafana"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        name = "grafana"
      }
    }
    strategy {
      rolling_update {
        max_surge = 1
        max_unavailable = 1
      }
      type = "RollingUpdate"
    }
    template {
      metadata {
        labels = {
          name = "grafana"
        }
      }
      spec {
        container {
          image = "grafana/grafana:latest"
          image_pull_policy = "IfNotPresent"
          name = "grafana"

          port {
            container_port = 3000
            protocol = "TCP"
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "1024Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "100Mi"
            }
          }
          volume_mount {
            name = "data"
            mount_path = "/var/lib/grafana"
          }
        }
        security_context {}
        volume {
          name = "data"
          empty_dir {}
        }
      }
    }
  }
}

# resource "helm_release" "prometheus" {
#   name       = "prometheus"
#   namespace  = "test"
  

#   #repository = "https://charts.bitnami.com/bitnami"
#     chart = "./prometheus"
#   set {
#     name  = "service.type"
#     value = "NodePort"
#   }
# }

# resource "helm_release" "grafana" {
#   name       = "grafana"
#   namespace  = "test"
  

#   #repository = "https://charts.bitnami.com/bitnami"
#     chart = "./grafana"

#   set {
#     name  = "service.type"
#     value = "NodePort"
#   }
# }

# resource "docker_image" "nginx" {
#   name         = "nginx:latest"
#   keep_locally = false
# }

# resource "docker_container" "nginx" {
#   image = docker_image.nginx.latest
#   name  = "tutorial"
#   ports {
#     internal = 80
#     external = 8000
#   }
# }
