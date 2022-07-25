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
  description = "renduterra"
}

variable "region" {
  description = "us-central1"
}

provider "google" { 
  project = var.project_id
  region  = var.region
}


provider "grafana" {
  alias         = "first"

    url = "https://nacerlf.grafana.net"
     auth = "eyJrIjoiUDV3U0w0OTFONHRvR3VkSHk0UGJPQzVlVzdPbTJsWDQiLCJuIjoicmVuZHVJbmZyYSIsImlkIjoxfQ==" 
    //cloud_api_key = "eyJrIjoiUDV3U0w0OTFONHRvR3VkSHk0UGJPQzVlVzdPbTJsWDQiLCJuIjoicmVuZHVJbmZyYSIsImlkIjoxfQ==" 

}

resource "grafana_dashboard" "metrics" {
    provider = grafana.first
  config_json = file("grafana-dashboard.json")
}

resource "grafana_folder" "my_folder" {
  provider = grafana.first

  title = "Test Folder"
}

#Ressource Grafana
/*
resource "grafana_cloud_stack" "rendu" {
  provider    = grafana.first

  name        = "rendu"
  slug        = "rednu"
  region_slug = "us" # Example “us”,”eu” etc
}

# Creating an API key in Grafana instance to be used for creating resources in Grafana instance
resource "grafana_api_key" "rendukey" {
  provider = grafana.first

  cloud_stack_slug = grafana_cloud_stack.rendu.slug
  name             = "rendukey"
  role             = "Admin" 
}

# Declaring the second provider to be used for creating resources in Grafana        
provider "grafana" {
  alias         = "second"

  url  = grafana_cloud_stack.rendu.url
  auth = grafana_api_key.rendukey
}

*/