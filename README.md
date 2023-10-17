# README - Projet Terraform

Ce projet Terraform a pour objectif de créer une infrastructure dans Google Cloud Platform (GCP) pour déployer des services Kubernetes et des ressources Grafana. Voici un aperçu des principales composantes et fonctionnalités du projet :

## Configuration Terraform
Le fichier `main.tf` commence par spécifier la version minimale de Terraform (0.12.26) et les fournisseurs nécessaires, notamment Google Cloud, Kubernetes, Docker et Grafana.

## Ressources Grafana
Le projet crée une ressource Grafana avec une configuration spécifique dans le fichier `grafana.firstnewinfra`. Cela permet de gérer un tableau de bord Grafana et un dossier associé.

- `grafana_folder.my_folderinfra` crée un dossier Grafana nommé "TestNewversion".
- `grafana_dashboard.metricsinfra` associe un tableau de bord Grafana au dossier précédemment créé, en important la configuration depuis un fichier JSON.

## Réseau et Cluster GKE
Le projet crée un réseau VPC (Virtual Private Cloud) dans GCP avec une sous-réseau définie. Cela sert de base pour le cluster Kubernetes.

- `google_compute_network.vpc` définit un réseau nommé "mynetwork4".
- `google_compute_subnetwork.subnet` crée un sous-réseau utilisant le réseau précédemment créé.

Un cluster Google Kubernetes Engine (GKE) est configuré dans le projet. Il permet de déployer des applications Kubernetes.

- `google_container_cluster.primary` configure un cluster GKE avec un nœud de base, en désactivant le pool de nœuds par défaut.
- `google_container_node_pool.primary_nodes` crée un pool de nœuds géré séparément pour le cluster GKE.

## Services Kubernetes
Le projet déploie deux services Kubernetes :

1. Un service Nginx : Le fichier `kubernetes_service.nginx` expose un service Nginx dans un déploiement.
2. Un service Grafana : Le fichier `kubernetes_service.grafana_service` expose un service Grafana dans un déploiement.

Chaque service est configuré pour être exposé via un équilibrage de charge de type "LoadBalancer".

## Configuration Helm (commentée)
Le code pour déployer Prometheus et Grafana via Helm est actuellement commenté (non actif) dans le fichier. Vous pouvez le décommenter et personnaliser la configuration si nécessaire.

## Docker (commenté)
Le code pour gérer une image Docker et un conteneur Nginx est également commenté. Vous pouvez le décommenter et ajuster la configuration si vous avez besoin de gérer des conteneurs Docker.

Assurez-vous de personnaliser les variables telles que `var.project_id`, `var.region`, `var.gke_username`, `var.gke_password`, et `var.gke_num_nodes` selon vos besoins.

N'oubliez pas de définir les valeurs manquantes pour `grafana.firstnewinfra` et `kubernetes_service.nginx` en remplaçant les étiquettes "REPLACE" par les informations appropriées.

Pour déployer cette infrastructure, exécutez les commandes Terraform habituelles, telles que `terraform init`, `terraform plan`, et `terraform apply`.

Ce README fournit un aperçu général du projet Terraform. Assurez-vous de consulter la documentation Terraform pour une compréhension plus approfondie des ressources et des fonctionnalités spécifiques à GCP et Kubernetes.
